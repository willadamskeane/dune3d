import '../domain/project_entity.dart';

/// Abstract repository for project persistence operations.
abstract class ProjectRepository {
  Future<List<ProjectEntity>> listProjects();
  Future<ProjectEntity> createProject(String name);
  Future<void> deleteProject(String id);
  Future<ProjectEntity?> loadProject(String id);
  Future<void> saveProject(ProjectEntity project);
}

/// In-memory implementation of [ProjectRepository] for development/testing.
/// Will be replaced with persistent storage (SQLite/file-based) later.
class InMemoryProjectRepository implements ProjectRepository {
  final Map<String, ProjectEntity> _projects = {};

  @override
  Future<ProjectEntity> createProject(String name) async {
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final project = ProjectEntity(
      id: id,
      name: name,
      createdAt: now,
      updatedAt: now,
    );
    _projects[id] = project;
    return project;
  }

  @override
  Future<void> deleteProject(String id) async {
    _projects.remove(id);
  }

  @override
  Future<List<ProjectEntity>> listProjects() async {
    return _projects.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<ProjectEntity?> loadProject(String id) async => _projects[id];

  @override
  Future<void> saveProject(ProjectEntity project) async {
    _projects[project.id] = project.copyWith(updatedAt: DateTime.now());
  }
}
