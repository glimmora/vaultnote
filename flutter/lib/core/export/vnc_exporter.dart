import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../crypto/key_manager.dart';
import 'vnc_format.dart';
import '../../domain/entities/note.dart';

/// Export notes to .vnc container files
class VNCExporter {
  final KeyManager _keyManager;

  VNCExporter(this._keyManager);

  /// Export single note to .vnc file
  Future<File> exportSingleNote(Note note, String outputDir) async {
    if (!_keyManager.isUnlocked) {
      throw StateError('KeyManager not unlocked');
    }

    final data = await VNCFormat.encryptNote(
      note,
      _keyManager.masterKey!,
      _keyManager.hmacKey!,
    );

    final dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File(path.join(outputDir, '${note.id}.vnc'));
    await file.writeAsBytes(data);
    return file;
  }

  /// Export multiple notes to a single container file
  Future<File> exportMultipleNotes(
    List<Note> notes,
    String outputPath,
  ) async {
    if (!_keyManager.isUnlocked) {
      throw StateError('KeyManager not unlocked');
    }

    // Create a tar-like container with all notes
    final container = <String, Uint8List>{};
    
    for (final note in notes) {
      final data = await VNCFormat.encryptNote(
        note,
        _keyManager.masterKey!,
        _keyManager.hmacKey!,
      );
      container['${note.id}.vnc'] = data;
    }

    // Compress into a single archive
    final archive = Archive();
    for (final entry in container.entries) {
      archive.addFile(ArchiveFile(
        entry.key,
        entry.value.length,
        entry.value,
      ));
    }

    final compressed = ZipEncoder().encode(archive);
    if (compressed == null) {
      throw Exception('Compression failed');
    }

    // Wrap in .vnc format
    final wrapperNote = Note(
      id: 'container_${DateTime.now().millisecondsSinceEpoch}',
      title: 'VaultNote Container',
      body: 'Contains ${notes.length} notes',
      created: DateTime.now(),
      modified: DateTime.now(),
    );

    final wrapperData = await VNCFormat.encryptNote(
      wrapperNote,
      _keyManager.masterKey!,
      _keyManager.hmacKey!,
    );

    // Combine wrapper + zip
    final finalData = Uint8List.fromList([
      ...wrapperData,
      ...compressed,
    ]);

    final file = File(outputPath);
    await file.writeAsBytes(finalData);
    return file;
  }

  /// Export all notes
  Future<File> exportAllNotes(String outputDir) async {
    final appDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = path.join(outputDir, 'vaultnote_backup_$timestamp.vnc');
    
    // Get all notes (need to inject repository - simplified here)
    // This would be called from a use case with repository access
    throw UnimplementedError('Use exportMultipleNotes with note list');
  }
}
