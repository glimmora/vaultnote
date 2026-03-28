import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../crypto/key_manager.dart';
import 'vnc_format.dart';
import '../../domain/entities/note.dart';

/// Import notes from .vnc container files
class VNCImporter {
  final KeyManager _keyManager;

  VNCImporter(this._keyManager);

  /// Import a single .vnc file
  Future<Note> importSingleFile(Uint8List data) async {
    if (!_keyManager.isUnlocked) {
      throw StateError('KeyManager not unlocked');
    }

    return await VNCFormat.decryptNote(
      data,
      _keyManager.masterKey!,
      _keyManager.hmacKey!,
    );
  }

  /// Import from container file (multiple notes)
  Future<List<Note>> importContainer(Uint8List data) async {
    if (!_keyManager.isUnlocked) {
      throw StateError('KeyManager not unlocked');
    }

    // First, try to decrypt the wrapper
    // Container format: [wrapper .vnc][zip data]
    
    // Find where the zip starts by looking for PK signature
    int zipStart = -1;
    for (int i = 0; i < data.length - 4; i++) {
      if (data[i] == 0x50 && data[i + 1] == 0x4B &&
          data[i + 2] == 0x03 && data[i + 3] == 0x04) {
        zipStart = i;
        break;
      }
    }

    if (zipStart == -1) {
      // Not a container, treat as single note
      final note = await VNCFormat.decryptNote(
        data,
        _keyManager.masterKey!,
        _keyManager.hmacKey!,
      );
      return [note];
    }

    // Extract zip data
    final zipData = data.sublist(zipStart);
    
    // Decompress zip
    final archive = ZipDecoder().decodeBytes(zipData);
    
    final notes = <Note>[];
    for (final file in archive.files) {
      if (file.name.endsWith('.vnc') && file.content is Uint8List) {
        try {
          final note = await VNCFormat.decryptNote(
            file.content as Uint8List,
            _keyManager.masterKey!,
            _keyManager.hmacKey!,
          );
          notes.add(note);
        } catch (e) {
          // Skip corrupted notes
          print('Failed to import ${file.name}: $e');
        }
      }
    }

    return notes;
  }
}
