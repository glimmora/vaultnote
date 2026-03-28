import 'package:equatable/equatable.dart';

class Label extends Equatable {
  final String id;
  final String name;
  final String color;

  const Label({
    required this.id,
    required this.name,
    this.color = '#4285F4',
  });

  Label copyWith({
    String? id,
    String? name,
    String? color,
  }) {
    return Label(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }

  factory Label.fromJson(Map<String, dynamic> json) {
    return Label(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#4285F4',
    );
  }

  @override
  List<Object?> get props => [id, name, color];
}
