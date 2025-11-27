import 'package:flutter_test/flutter_test.dart';
import 'package:cad_app/src/features/viewer/domain/mesh_model.dart';

void main() {
  group('Mesh', () {
    test('constructor sets all properties', () {
      final mesh = Mesh(
        positions: [0, 0, 0, 1, 0, 0, 0, 1, 0],
        normals: [0, 0, 1, 0, 0, 1, 0, 0, 1],
        indices: [0, 1, 2],
        id: 'test-mesh',
      );

      expect(mesh.positions.length, 9);
      expect(mesh.normals.length, 9);
      expect(mesh.indices.length, 3);
      expect(mesh.id, 'test-mesh');
    });

    test('vertexCount returns correct count', () {
      final mesh = Mesh(
        positions: [0, 0, 0, 1, 0, 0, 0, 1, 0],
        normals: [0, 0, 1, 0, 0, 1, 0, 0, 1],
        indices: [0, 1, 2],
        id: 'test',
      );

      expect(mesh.vertexCount, 3);
    });

    test('triangleCount returns correct count', () {
      final mesh = Mesh(
        positions: List.filled(12 * 3, 0), // 12 vertices
        normals: List.filled(12 * 3, 0),
        indices: List.generate(18, (i) => i % 12), // 6 triangles
        id: 'test',
      );

      expect(mesh.triangleCount, 6);
    });

    test('empty factory creates mesh with no data', () {
      final mesh = Mesh.empty('empty-mesh');

      expect(mesh.positions, isEmpty);
      expect(mesh.normals, isEmpty);
      expect(mesh.indices, isEmpty);
      expect(mesh.id, 'empty-mesh');
      expect(mesh.vertexCount, 0);
      expect(mesh.triangleCount, 0);
    });

    test('cube factory creates valid cube mesh', () {
      final cube = Mesh.cube('cube-1');

      expect(cube.vertexCount, 8);
      expect(cube.triangleCount, 12);
      expect(cube.id, 'cube-1');
    });

    test('cube factory respects size parameter', () {
      final cube = Mesh.cube('cube-2', size: 4.0);

      // Check that positions span from -2 to 2
      final minX = cube.positions
          .asMap()
          .entries
          .where((e) => e.key % 3 == 0)
          .map((e) => e.value)
          .reduce((a, b) => a < b ? a : b);
      final maxX = cube.positions
          .asMap()
          .entries
          .where((e) => e.key % 3 == 0)
          .map((e) => e.value)
          .reduce((a, b) => a > b ? a : b);

      expect(minX, -2.0);
      expect(maxX, 2.0);
    });

    test('equality is based on id', () {
      final mesh1 = Mesh(
        positions: [0, 0, 0],
        normals: [0, 0, 1],
        indices: [0],
        id: 'same-id',
      );
      final mesh2 = Mesh(
        positions: [1, 1, 1],
        normals: [1, 0, 0],
        indices: [0],
        id: 'same-id',
      );

      expect(mesh1, equals(mesh2));
    });

    test('inequality for different ids', () {
      final mesh1 = Mesh.cube('id-1');
      final mesh2 = Mesh.cube('id-2');

      expect(mesh1, isNot(equals(mesh2)));
    });

    test('hashCode is based on id', () {
      final mesh1 = Mesh.cube('same-hash');
      final mesh2 = Mesh.empty('same-hash');

      expect(mesh1.hashCode, equals(mesh2.hashCode));
    });

    test('toString returns meaningful representation', () {
      final mesh = Mesh.cube('debug-cube');
      final str = mesh.toString();

      expect(str, contains('Mesh'));
      expect(str, contains('debug-cube'));
      expect(str, contains('8')); // vertices
      expect(str, contains('12')); // triangles
    });
  });
}
