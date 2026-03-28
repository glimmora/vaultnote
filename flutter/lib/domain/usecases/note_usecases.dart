import 'package:uuid/uuid.dart';
import '../entities/note.dart';
import '../entities/label.dart';

/// Create a new note
class CreateNoteUseCase {
  final Uuid _uuid = const Uuid();

  Note execute({
    required String title,
    required String body,
    List<String>? labels,
    String? color,
    bool? pinned,
  }) {
    final now = DateTime.now();
    return Note(
      id: _uuid.v4(),
      title: title,
      body: body,
      labels: labels ?? [],
      color: color ?? '#FFFFFF',
      created: now,
      modified: now,
      pinned: pinned ?? false,
      archived: false,
    );
  }
}

/// Update an existing note
class UpdateNoteUseCase {
  Note execute(Note existing, {
    String? title,
    String? body,
    List<String>? labels,
    String? color,
    bool? pinned,
    bool? archived,
  }) {
    return existing.copyWith(
      title: title ?? existing.title,
      body: body ?? existing.body,
      labels: labels ?? existing.labels,
      color: color ?? existing.color,
      pinned: pinned ?? existing.pinned,
      archived: archived ?? existing.archived,
      modified: DateTime.now(),
    );
  }
}

/// Delete a note
class DeleteNoteUseCase {
  void execute(Note note) {
    // Just a marker - actual deletion happens in repository
  }
}

/// Archive a note
class ArchiveNoteUseCase {
  Note execute(Note note, bool archive) {
    return note.copyWith(
      archived: archive,
      modified: DateTime.now(),
    );
  }
}

/// Toggle pin status
class TogglePinUseCase {
  Note execute(Note note) {
    return note.copyWith(
      pinned: !note.pinned,
      modified: DateTime.now(),
    );
  }
}

/// Create a label
class CreateLabelUseCase {
  final Uuid _uuid = const Uuid();

  Label execute({
    required String name,
    String? color,
  }) {
    return Label(
      id: _uuid.v4(),
      name: name,
      color: color ?? '#4285F4',
    );
  }
}

/// Update a label
class UpdateLabelUseCase {
  Label execute(Label existing, {
    String? name,
    String? color,
  }) {
    return existing.copyWith(
      name: name ?? existing.name,
      color: color ?? existing.color,
    );
  }
}

/// Delete a label
class DeleteLabelUseCase {
  void execute(Label label) {
    // Just a marker - actual deletion happens in repository
  }
}
