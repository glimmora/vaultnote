import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/storage/label_repository.dart';
import '../../core/storage/note_repository.dart';
import '../../domain/entities/label.dart';
import '../../domain/usecases/note_usecases.dart';

// Events
abstract class LabelEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadLabelsEvent extends LabelEvent {}
class CreateLabelEvent extends LabelEvent {
  final Label label;
  CreateLabelEvent(this.label);
  @override
  List<Object?> get props => [label];
}
class UpdateLabelEvent extends LabelEvent {
  final Label label;
  UpdateLabelEvent(this.label);
  @override
  List<Object?> get props => [label];
}
class DeleteLabelEvent extends LabelEvent {
  final String labelId;
  DeleteLabelEvent(this.labelId);
  @override
  List<Object?> get props => [labelId];
}

// State
class LabelState extends Equatable {
  final List<Label> labels;
  final bool isLoading;
  final String? error;

  const LabelState({
    this.labels = const [],
    this.isLoading = false,
    this.error,
  });

  LabelState copyWith({
    List<Label>? labels,
    bool? isLoading,
    String? error,
  }) {
    return LabelState(
      labels: labels ?? this.labels,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [labels, isLoading, error];
}

// Cubit
class LabelCubit extends Cubit<LabelState> {
  final LabelRepository _labelRepository;
  final NoteRepository _noteRepository;
  final CreateLabelUseCase _createLabel = CreateLabelUseCase();
  final UpdateLabelUseCase _updateLabel = UpdateLabelUseCase();

  LabelCubit(this._labelRepository, this._noteRepository) : super(const LabelState());

  Future<void> loadLabels() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final labels = await _labelRepository.loadLabels();
      emit(state.copyWith(labels: labels, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> createLabel(String name, String color) async {
    try {
      final label = _createLabel.execute(name: name, color: color);
      await _labelRepository.addLabel(label);
      await loadLabels();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> updateLabel(Label label) async {
    try {
      await _labelRepository.updateLabel(label);
      await loadLabels();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteLabel(String labelId) async {
    try {
      // Get the label name before deleting
      final labelToDelete = state.labels.firstWhere((l) => l.id == labelId);
      
      // Delete from labels list
      await _labelRepository.deleteLabel(labelId);
      
      // Remove label from all notes
      await _noteRepository.removeLabelFromNotes(labelToDelete.name);
      
      await loadLabels();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
