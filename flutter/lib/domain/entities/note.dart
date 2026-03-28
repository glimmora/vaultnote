import 'package:equatable/equatable.dart';

class Note extends Equatable {
  final String id;
  final String title;
  final String body;
  final List<String> labels;
  final String color;
  final DateTime created;
  final DateTime modified;
  final bool pinned;
  final bool archived;

  const Note({
    required this.id,
    required this.title,
    required this.body,
    this.labels = const [],
    this.color = '#FFFFFF',
    required this.created,
    required this.modified,
    this.pinned = false,
    this.archived = false,
  });

  Note copyWith({
    String? id,
    String? title,
    String? body,
    List<String>? labels,
    String? color,
    DateTime? created,
    DateTime? modified,
    bool? pinned,
    bool? archived,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      labels: labels ?? this.labels,
      color: color ?? this.color,
      created: created ?? this.created,
      modified: modified ?? this.modified,
      pinned: pinned ?? this.pinned,
      archived: archived ?? this.archived,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'labels': labels,
      'color': color,
      'created': created.toIso8601String(),
      'modified': modified.toIso8601String(),
      'pinned': pinned,
      'archived': archived,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      labels: (json['labels'] as List<dynamic>?)?.cast<String>() ?? [],
      color: json['color'] as String? ?? '#FFFFFF',
      created: DateTime.parse(json['created'] as String),
      modified: DateTime.parse(json['modified'] as String),
      pinned: json['pinned'] as bool? ?? false,
      archived: json['archived'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        labels,
        color,
        created,
        modified,
        pinned,
        archived,
      ];
}
