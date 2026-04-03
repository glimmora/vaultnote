import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/note_cubit.dart';
import '../cubits/label_cubit.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/label.dart';
import '../../domain/usecases/note_usecases.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _createLabelController = TextEditingController();
  
  String _selectedColor = '#FFFFFF';
  List<String> _selectedLabels = [];
  bool _isPinned = false;
  bool _hasChanges = false;

  final List<String> _availableColors = [
    '#FFFFFF', // White
    '#F28B82', // Red
    '#FDD663', // Yellow
    '#81C995', // Green
    '#78D9EC', // Cyan
    '#7BAAF7', // Blue
    '#8793F9', // Purple
    '#FF8BCC', // Pink
    '#E8EAED', // Gray
  ];

  final CreateNoteUseCase _createNote = CreateNoteUseCase();
  final UpdateNoteUseCase _updateNote = UpdateNoteUseCase();

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _bodyController.text = widget.note!.body;
      _selectedColor = widget.note!.color;
      _selectedLabels = List.from(widget.note!.labels);
      _isPinned = widget.note!.pinned;
    }
    
    _titleController.addListener(_onTextChanged);
    _bodyController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _createLabelController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _saveNote();
        if (mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Note' : 'New Note'),
          actions: [
            IconButton(
              icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              onPressed: () {
                setState(() {
                  _isPinned = !_isPinned;
                  _hasChanges = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.palette),
              onPressed: _showColorPicker,
            ),
            IconButton(
              icon: const Icon(Icons.label),
              onPressed: _showLabelPicker,
            ),
          ],
        ),
        body: Column(
          children: [
            // Color indicator
            Container(
              height: 4,
              width: double.infinity,
              color: _hexToColor(_selectedColor),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: null,
                    ),
                    const SizedBox(height: 8),
                    // Labels chips
                    if (_selectedLabels.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedLabels.map((label) {
                          return Chip(
                            label: Text(label),
                            backgroundColor: _getLabelColor(label),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                _selectedLabels.remove(label);
                                _hasChanges = true;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: _bodyController,
                      decoration: const InputDecoration(
                        hintText: 'Note',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                      maxLines: null,
                      minLines: 10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await _saveNote();
            if (mounted) Navigator.pop(context);
          },
          child: const Icon(Icons.check),
        ),
      ),
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Color',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableColors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                      _hasChanges = true;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _hexToColor(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.black)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showLabelPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => BlocBuilder<LabelCubit, LabelState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Labels',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...state.labels.map((label) {
                      final isSelected = _selectedLabels.contains(label.name);
                      return FilterChip(
                        label: Text(label.name),
                        selected: isSelected,
                        selectedColor: _hexToColor(label.color).withOpacity(0.3),
                        checkmarkColor: _hexToColor(label.color),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedLabels.add(label.name);
                            } else {
                              _selectedLabels.remove(label.name);
                            }
                            _hasChanges = true;
                          });
                        },
                      );
                    }),
                    // Add new label button
                    OutlinedButton.icon(
                      onPressed: () => _showCreateLabelDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('New Label'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCreateLabelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Label'),
        content: TextField(
          controller: _createLabelController,
          decoration: const InputDecoration(
            hintText: 'Label name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_createLabelController.text.isNotEmpty) {
                context.read<LabelCubit>().createLabel(
                      _createLabelController.text,
                      '#4285F4',
                    );
                _createLabelController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      if (hex.isEmpty || !hex.startsWith('#') || hex.length != 7) {
        return const Color(0xFFFFFFFF);
      }
      return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return const Color(0xFFFFFFFF);
    }
  }

  Color _getLabelColor(String labelName) {
    try {
      final labelCubit = context.read<LabelCubit>();
      final label = labelCubit.state.labels.firstWhere(
            (l) => l.name == labelName,
            orElse: () => const Label(id: '', name: '', color: '#4285F4'),
          );
      return _hexToColor(label.color).withOpacity(0.3);
    } catch (e) {
      return const Color(0xFF4285F4).withOpacity(0.3);
    }
  }

  Future<void> _saveNote() async {
    if (!_hasChanges) return;

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty && body.isEmpty) return;

    final noteCubit = context.read<NoteCubit>();

    if (widget.note != null) {
      // Update existing note
      final updated = _updateNote.execute(
        widget.note!,
        title: title,
        body: body,
        labels: _selectedLabels,
        color: _selectedColor,
        pinned: _isPinned,
      );
      await noteCubit.updateNote(updated);
    } else {
      // Create new note
      final note = _createNote.execute(
        title: title.isEmpty ? 'Untitled' : title,
        body: body,
        labels: _selectedLabels,
        color: _selectedColor,
        pinned: _isPinned,
      );
      await noteCubit.createNote(note);
    }

    setState(() {
      _hasChanges = false;
    });
  }
}
