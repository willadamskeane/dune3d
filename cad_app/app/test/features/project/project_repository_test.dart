import 'package:flutter_test/flutter_test.dart';
import 'package:cad_app/src/features/project/data/project_repository.dart';

void main() {
  group('InMemoryProjectRepository', () {
    late InMemoryProjectRepository repository;

    setUp(() {
      repository = InMemoryProjectRepository();
    });

    test('createProject creates project with correct name', () async {
      final project = await repository.createProject('My Project');

      expect(project.name, 'My Project');
      expect(project.id, isNotEmpty);
    });

    test('createProject sets timestamps', () async {
      final before = DateTime.now();
      final project = await repository.createProject('My Project');
      final after = DateTime.now();

      expect(project.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(project.createdAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      expect(project.updatedAt, equals(project.createdAt));
    });

    test('listProjects returns empty list initially', () async {
      final projects = await repository.listProjects();

      expect(projects, isEmpty);
    });

    test('listProjects returns created projects', () async {
      await repository.createProject('Project 1');
      await repository.createProject('Project 2');

      final projects = await repository.listProjects();

      expect(projects.length, 2);
    });

    test('listProjects returns projects sorted by updatedAt descending', () async {
      await repository.createProject('Project 1');
      await Future.delayed(const Duration(milliseconds: 10));
      await repository.createProject('Project 2');

      final projects = await repository.listProjects();

      expect(projects.first.name, 'Project 2');
      expect(projects.last.name, 'Project 1');
    });

    test('loadProject returns created project', () async {
      final created = await repository.createProject('My Project');

      final loaded = await repository.loadProject(created.id);

      expect(loaded, isNotNull);
      expect(loaded!.id, created.id);
      expect(loaded.name, created.name);
    });

    test('loadProject returns null for non-existent id', () async {
      final project = await repository.loadProject('non-existent');

      expect(project, isNull);
    });

    test('deleteProject removes project', () async {
      final project = await repository.createProject('My Project');

      await repository.deleteProject(project.id);

      final loaded = await repository.loadProject(project.id);
      expect(loaded, isNull);
    });

    test('deleteProject with non-existent id does not throw', () async {
      await expectLater(
        repository.deleteProject('non-existent'),
        completes,
      );
    });

    test('saveProject updates project timestamp', () async {
      final project = await repository.createProject('My Project');
      final originalUpdatedAt = project.updatedAt;

      await Future.delayed(const Duration(milliseconds: 10));
      await repository.saveProject(project);

      final loaded = await repository.loadProject(project.id);
      expect(loaded!.updatedAt.isAfter(originalUpdatedAt), isTrue);
    });
  });
}
