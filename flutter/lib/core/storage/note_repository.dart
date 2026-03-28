import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../crypto/key_manager.dart';
import 'vnc_format.dart';
import '../../domain/entities/note.dart';

/// Repository for note CRUD operations
/// Notes are stored as individual .vnc files in app's private storage
class NoteRepository {
  final KeyManager _keyManager;
  Directory? _notesDir;

  NoteRepository(this._keyManager);

  /// Initialize repository - get app directory
  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _notesDir = Directory(path.join(appDir.path, 'notes'));
    if (!await _notesDir!.exists()) {
      await _notesDir!.create(recursive: true);
    }
  }

  /// Get file path for a note
  String _getNotePath(String noteId) {
    return path.join(_notesDir!.path, '$noteId.vnc');
  }

  /// Create a new note
  Future<void> createNote(Note note) async {
    if (!_keyManager.isUnlocked) {
      throw StateError('KeyManager not unlocked');
    }

    final data = await VNCFormat.encryptNote(
      note,
      _keyManager.masterKey!,
      _keyManager.hmacKey!,
    );

    final file = File(_getNotePath(note.id));
    await file.writeAsBytes(data);
  }

  /// Update an existing note
  Future<void> updateNote(Note note) async {
    await createNote(note); // Same as create (upsert)
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    final file = File(_getNotePath(noteId));
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Get a single note by ID
  Future<Note?> getNote(String noteId) async {
    if (!_keyManager.isUnlocked) {
      throw StateError('KeyManager not unlocked');
    }

    final file = File(_getNotePath(noteId));
    if (!await file.exists()) {
      return null;
    }

    final data = await file.readAsBytes();
    return await VNCFormat.decryptNote(
      data,
      _keyManager.masterKey!,
      _keyManager.hmacKey!,
    );
  }

  /// Get all notes (including archived)
  Future<List<Note>> getAllNotes() async {
    if (!_keyManager.isUnlocked) {
      throw StateError('KeyManager not unlocked');
    }

    final notes = <Note>[];
    
    if (!await _notesDir!.exists()) {
      return notes;
    }

    final files = _notesDir!.listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.vnc'));

    for (final file in files) {
      try {
        final data = await file.readAsBytes();
        final note = await VNCFormat.decryptNote(
          data,
          _keyManager.masterKey!,
          _keyManager.hmacKey!,
        );
        notes.add(note);
      } catch (e) {
        // Skip corrupted files
        print('Error reading note ${file.path}: $e');
      }
    }

    // Sort: pinned first, then by modified date descending
    notes.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      return b.modified.compareTo(a.modified);
    });

    return notes;
  }

  /// Get non-archived notes
  Future<List<Note>> getActiveNotes() async {
    final all = await getAllNotes();
    return all.where((n) => !n.archived).toList();
  }

  /// Get archived notes
  Future<List<Note>> getArchivedNotes() async {
    final all = await getAllNotes();
    return all.where((n) => n.archived).toList();
  }

  /// Search notes by text (decrypt and search in-memory)
  Future<List<Note>> searchNotes(String query) async {
    final all = await getActiveNotes();
    final lowerQuery = query.toLowerCase();
    
    return all.where((note) {
      return note.title.toLowerCase().contains(lowerQuery) ||
          note.body.toLowerCase().contains(lowerQuery) ||
          note.labels.any((l) => l.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Get notes by label
  Future<List<Note>> getNotesByLabel(String label) async {
    final all = await getActiveNotes();
    return all.where((n) => n.labels.contains(label)).toList();
  }

  /// Export a note as .vnc bytes (for sharing)
  Future<Uint8List> exportNote(String noteId) async {
    final note = await getNote(noteId);
    if (note == null) {
      throw Exception('Note not found');
    }

    return await VNCFormat.encryptNote(
      note,
      _keyManager.masterKey!,
      _keyManager.hmacKey!,
    );
  }

  /// Import a note from .vnc bytes
  Future<Note> importNote(Uint8List data) async {
    final note = await VNCFormat.decryptNote(
      data,
      _keyManager.masterKey!,
      _keyManager.hmacKey!,
    );
    
    // Save the imported note
    await createNote(note);
    return note;
  }
}
