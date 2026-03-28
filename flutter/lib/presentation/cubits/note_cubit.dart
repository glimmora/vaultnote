import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/crypto/key_manager.dart';
import '../../core/storage/secure_prefs.dart';
import '../../core/storage/note_repository.dart';
import '../../core/storage/label_repository.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/label.dart';
import '../../domain/usecases/note_usecases.dart';

// Events
abstract class NoteEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadNotesEvent extends NoteEvent {}
class CreateNoteEvent extends NoteEvent {
  final Note note;
  CreateNoteEvent(this.note);
  @override
  List<Object?> get props => [note];
}
class UpdateNoteEvent extends NoteEvent {
  final Note note;
  UpdateNoteEvent(this.note);
  @override
  List<Object?> get props => [note];
}
class DeleteNoteEvent extends NoteEvent {
  final String noteId;
  DeleteNoteEvent(this.noteId);
  @override
  List<Object?> get props => [noteId];
}
class TogglePinNoteEvent extends NoteEvent {
  final String noteId;
  TogglePinNoteEvent(this.noteId);
  @override
  List<Object?> get props => [noteId];
}
class ArchiveNoteEvent extends NoteEvent {
  final String noteId;
  final bool archive;
  ArchiveNoteEvent(this.noteId, this.archive);
  @override
  List<Object?> get props => [noteId, archive];
}
class SearchNotesEvent extends NoteEvent {
  final String query;
  SearchNotesEvent(this.query);
  @override
  List<Object?> get props => [query];
}
class FilterByLabelEvent extends NoteEvent {
  final String? label;
  FilterByLabelEvent(this.label);
  @override
  List<Object?> get props => [label];
}
class ClearFilterEvent extends NoteEvent {}

// State
class NoteState extends Equatable {
  final List<Note> notes;
  final List<Note> filteredNotes;
  final String? filterLabel;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const NoteState({
    this.notes = const [],
    this.filteredNotes = const [],
    this.filterLabel,
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  NoteState copyWith({
    List<Note>? notes,
    List<Note>? filteredNotes,
    String? filterLabel,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return NoteState(
      notes: notes ?? this.notes,
      filteredNotes: filteredNotes ?? this.filteredNotes,
      filterLabel: filterLabel ?? this.filterLabel,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [notes, filteredNotes, filterLabel, searchQuery, isLoading, error];
}

// Cubit
class NoteCubit extends Cubit<NoteState> {
  final NoteRepository _noteRepository;
  final LabelRepository _labelRepository;
  final CreateNoteUseCase _createNote = CreateNoteUseCase();
  final UpdateNoteUseCase _updateNote = UpdateNoteUseCase();
  final ArchiveNoteUseCase _archiveNote = ArchiveNoteUseCase();
  final TogglePinUseCase _togglePin = TogglePinUseCase();

  NoteCubit(
    this._noteRepository,
    this._labelRepository,
  ) : super(const NoteState());

  Future<void> loadNotes() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final notes = await _noteRepository.getActiveNotes();
      emit(state.copyWith(
        notes: notes,
        filteredNotes: _applyFilters(notes),
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> createNote(Note note) async {
    try {
      await _noteRepository.createNote(note);
      await loadNotes();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      await _noteRepository.updateNote(note);
      await loadNotes();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await _noteRepository.deleteNote(noteId);
      await loadNotes();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> togglePin(String noteId) async {
    try {
      final note = state.notes.firstWhere((n) => n.id == noteId);
      final updated = _togglePin.execute(note);
      await _noteRepository.updateNote(updated);
      await loadNotes();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> archiveNote(String noteId, bool archive) async {
    try {
      final note = state.notes.firstWhere((n) => n.id == noteId);
      final updated = _archiveNote.execute(note, archive);
      await _noteRepository.updateNote(updated);
      await loadNotes();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> searchNotes(String query) async {
    emit(state.copyWith(searchQuery: query));
    if (query.isEmpty) {
      await loadNotes();
    } else {
      try {
        final results = await _noteRepository.searchNotes(query);
        emit(state.copyWith(
          filteredNotes: _applyLabelFilter(results),
          isLoading: false,
        ));
      } catch (e) {
        emit(state.copyWith(error: e.toString()));
      }
    }
  }

  Future<void> filterByLabel(String? label) async {
    emit(state.copyWith(filterLabel: label));
    emit(state.copyWith(filteredNotes: _applyLabelFilter(state.notes)));
  }

  List<Note> _applyFilters(List<Note> notes) {
    var result = notes;
    if (state.filterLabel != null) {
      result = _applyLabelFilter(result);
    }
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      result = result.where((n) =>
        n.title.toLowerCase().contains(query) ||
        n.body.toLowerCase().contains(query) ||
        n.labels.any((l) => l.toLowerCase().contains(query)),
      ).toList();
    }
    return result;
  }

  List<Note> _applyLabelFilter(List<Note> notes) {
    if (state.filterLabel == null) return notes;
    return notes.where((n) => n.labels.contains(state.filterLabel)).toList();
  }
}
