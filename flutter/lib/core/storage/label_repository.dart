import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../crypto/key_manager.dart';
import 'vnc_format.dart';
import '../../domain/entities/label.dart';

/// Repository for label operations
/// All labels stored in a single labels.vnc container
class LabelRepository {
  final KeyManager _keyManager;
  String? _labelsFilePath;

  LabelRepository(this._keyManager);

  /// Initialize repository
  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _labelsFilePath = path.join(appDir.path, 'labels.vnc');
  }

  /// Load all labels
  Future<List<Label>> loadLabels() async {
    if (!_keyManager.isUnlocked) {
      throw StateError('KeyManager not unlocked');
    }

    final file = File(_labelsFilePath!);
    if (!await file.exists()) {
      return [];
    }

    try {
      final data = await file.readAsBytes();
      final decrypted = await VNCFormat.decryptNote(
        data,
        _keyManager.masterKey!,
        _keyManager.hmacKey!,
      );
      
      // Parse labels from JSON body
      final labelsData = decrypted.body;
      // Simple parsing: each line is "id|name|color"
      final lines = labelsData.split('\n').where((l) => l.trim().isNotEmpty);
      return lines.map((line) {
        final parts = line.split('|');
        return Label(
          id: parts[0],
          name: parts[1],
          color: parts.length > 2 ? parts[2] : '#4285F4',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save all labels
  Future<void> saveLabels(List<Label> labels) async {
    if (!_keyManager.isUnlocked) {
      throw StateError('KeyManager not unlocked');
    }

    // Serialize labels to simple format
    final body = labels.map((l) => '${l.id}|${l.name}|${l.color}').join('\n');
    
    final note = Note(
      id: 'labels_container',
      title: 'Labels',
      body: body,
      created: DateTime.now(),
      modified: DateTime.now(),
    );

    final data = await VNCFormat.encryptNote(
      note,
      _keyManager.masterKey!,
      _keyManager.hmacKey!,
    );

    final file = File(_labelsFilePath!);
    await file.writeAsBytes(data);
  }

  /// Add a label
  Future<void> addLabel(Label label) async {
    final labels = await loadLabels();
    labels.add(label);
    await saveLabels(labels);
  }

  /// Update a label
  Future<void> updateLabel(Label label) async {
    final labels = await loadLabels();
    final index = labels.indexWhere((l) => l.id == label.id);
    if (index >= 0) {
      labels[index] = label;
      await saveLabels(labels);
    }
  }

  /// Delete a label
  Future<void> deleteLabel(String labelId) async {
    final labels = await loadLabels();
    labels.removeWhere((l) => l.id == labelId);
    await saveLabels(labels);
  }

  /// Remove label from all notes (called from NoteRepository)
  Future<void> removeLabelFromNotes(String labelName) async {
    // This would need a callback to NoteRepository
    // For simplicity, handled in use case
  }
}
