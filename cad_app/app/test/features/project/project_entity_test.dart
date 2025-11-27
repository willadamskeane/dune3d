import 'package:flutter_test/flutter_test.dart';
import 'package:cad_app/src/features/project/domain/project_entity.dart';

void main() {
  group('ProjectEntity', () {
    late ProjectEntity project;
    late DateTime createdAt;
    late DateTime updatedAt;

    setUp(() {
      createdAt = DateTime(2024, 1, 1);
      updatedAt = DateTime(2024, 1, 2);
      project = ProjectEntity(
        id: '123',
        name: 'Test Project',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    });

    test('constructor sets all properties correctly', () {
      expect(project.id, '123');
      expect(project.name, 'Test Project');
      expect(project.createdAt, createdAt);
      expect(project.updatedAt, updatedAt);
    });

    test('copyWith creates new instance with updated name', () {
      final updated = project.copyWith(name: 'Updated Name');

      expect(updated.id, project.id);
      expect(updated.name, 'Updated Name');
      expect(updated.createdAt, project.createdAt);
    });

    test('copyWith creates new instance with updated timestamp', () {
      final newTime = DateTime(2024, 2, 1);
      final updated = project.copyWith(updatedAt: newTime);

      expect(updated.updatedAt, newTime);
      expect(updated.name, project.name);
    });

    test('copyWith without arguments returns equivalent entity', () {
      final copy = project.copyWith();

      expect(copy.id, project.id);
      expect(copy.name, project.name);
      expect(copy.createdAt, project.createdAt);
      expect(copy.updatedAt, project.updatedAt);
    });

    test('equality works correctly', () {
      final same = ProjectEntity(
        id: '123',
        name: 'Test Project',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(project, equals(same));
    });

    test('inequality for different id', () {
      final different = ProjectEntity(
        id: '456',
        name: 'Test Project',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(project, isNot(equals(different)));
    });

    test('hashCode is consistent', () {
      final same = ProjectEntity(
        id: '123',
        name: 'Test Project',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(project.hashCode, equals(same.hashCode));
    });

    test('toString returns meaningful representation', () {
      final str = project.toString();

      expect(str, contains('ProjectEntity'));
      expect(str, contains('123'));
      expect(str, contains('Test Project'));
    });
  });
}
