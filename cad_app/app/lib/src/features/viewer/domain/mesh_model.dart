/// Represents a triangulated mesh for rendering.
class Mesh {
  /// Vertex positions as x,y,z triplets.
  final List<double> positions;

  /// Vertex normals as x,y,z triplets.
  final List<double> normals;

  /// Triangle indices into the vertex arrays.
  final List<int> indices;

  /// Unique identifier mapping to kernel shape.
  final String id;

  const Mesh({
    required this.positions,
    required this.normals,
    required this.indices,
    required this.id,
  });

  /// Number of vertices in the mesh.
  int get vertexCount => positions.length ~/ 3;

  /// Number of triangles in the mesh.
  int get triangleCount => indices.length ~/ 3;

  /// Creates an empty mesh.
  factory Mesh.empty(String id) {
    return Mesh(
      positions: const [],
      normals: const [],
      indices: const [],
      id: id,
    );
  }

  /// Creates a simple cube mesh for testing.
  factory Mesh.cube(String id, {double size = 1.0}) {
    final half = size / 2;

    // 8 vertices of a cube
    final positions = <double>[
      -half, -half, -half, // 0
      half, -half, -half, // 1
      half, half, -half, // 2
      -half, half, -half, // 3
      -half, -half, half, // 4
      half, -half, half, // 5
      half, half, half, // 6
      -half, half, half, // 7
    ];

    // Simple normals (pointing outward from each face)
    final normals = List<double>.filled(24, 0.0);

    // 12 triangles (2 per face)
    final indices = <int>[
      // Front
      0, 1, 2, 0, 2, 3,
      // Back
      5, 4, 7, 5, 7, 6,
      // Top
      3, 2, 6, 3, 6, 7,
      // Bottom
      4, 5, 1, 4, 1, 0,
      // Right
      1, 5, 6, 1, 6, 2,
      // Left
      4, 0, 3, 4, 3, 7,
    ];

    return Mesh(
      positions: positions,
      normals: normals,
      indices: indices,
      id: id,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Mesh && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Mesh(id: $id, vertices: $vertexCount, triangles: $triangleCount)';
  }
}
