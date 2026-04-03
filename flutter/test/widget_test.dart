// This is a basic Flutter widget test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaultnote/domain/entities/note.dart';
import 'package:vaultnote/presentation/widgets/note_card.dart';
import 'package:vaultnote/presentation/widgets/label_chip.dart';

void main() {
  testWidgets('NoteCard should render correctly', (WidgetTester tester) async {
    final note = Note(
      id: 'test-id',
      title: 'Test Note',
      body: 'This is a test note body content',
      labels: ['work', 'important'],
      color: '#FFFFFF',
      created: DateTime.now(),
      modified: DateTime.now(),
      pinned: true,
      archived: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteCard(
            note: note,
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      ),
    );

    // Verify note card renders with title
    expect(find.text('Test Note'), findsOneWidget);
    expect(find.byType(NoteCard), findsOneWidget);
  });

  testWidgets('LabelChip should render correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabelChip(
            label: 'work',
            onTap: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    // Verify label chip renders
    expect(find.text('work'), findsOneWidget);
    expect(find.byType(LabelChip), findsOneWidget);
  });

  testWidgets('Note entity should serialize and deserialize correctly', (WidgetTester tester) async {
    final note = Note(
      id: 'test-id-123',
      title: 'Serialization Test',
      body: 'Testing JSON serialization',
      labels: ['test', 'serialization'],
      color: '#FF5722',
      created: DateTime(2024, 1, 15, 10, 30),
      modified: DateTime(2024, 1, 16, 14, 45),
      pinned: true,
      archived: false,
    );

    final json = note.toJson();
    final restored = Note.fromJson(json);

    expect(restored.id, equals(note.id));
    expect(restored.title, equals(note.title));
    expect(restored.body, equals(note.body));
    expect(restored.labels, equals(note.labels));
    expect(restored.color, equals(note.color));
    expect(restored.pinned, equals(note.pinned));
    expect(restored.archived, equals(note.archived));
  });
}
