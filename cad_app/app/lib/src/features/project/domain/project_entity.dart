/// Represents a CAD project with metadata.
class ProjectEntity {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  ProjectEntity copyWith({
    String? name,
    DateTime? updatedAt,
  }) {
    return ProjectEntity(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectEntity &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, createdAt, updatedAt);
  }

  @override
  String toString() {
    return 'ProjectEntity(id: $id, name: $name, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
