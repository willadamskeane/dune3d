import 'dart:math' as math;
import 'geometry.dart';
import 'entities.dart';

/// 3D Vector
class Vec3 {
  final double x, y, z;

  const Vec3(this.x, this.y, this.z);
  static const Vec3 zero = Vec3(0, 0, 0);
  static const Vec3 unitX = Vec3(1, 0, 0);
  static const Vec3 unitY = Vec3(0, 1, 0);
  static const Vec3 unitZ = Vec3(0, 0, 1);

  Vec3 operator +(Vec3 other) => Vec3(x + other.x, y + other.y, z + other.z);
  Vec3 operator -(Vec3 other) => Vec3(x - other.x, y - other.y, z - other.z);
  Vec3 operator *(double scalar) => Vec3(x * scalar, y * scalar, z * scalar);
  Vec3 operator /(double scalar) => Vec3(x / scalar, y / scalar, z / scalar);
  Vec3 operator -() => Vec3(-x, -y, -z);

  double get length => math.sqrt(x * x + y * y + z * z);
  Vec3 get normalized => length > 0 ? this / length : Vec3.zero;

  double dot(Vec3 other) => x * other.x + y * other.y + z * other.z;

  Vec3 cross(Vec3 other) => Vec3(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );

  Vec3 rotateX(double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Vec3(x, y * cos - z * sin, y * sin + z * cos);
  }

  Vec3 rotateY(double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Vec3(x * cos + z * sin, y, -x * sin + z * cos);
  }

  Vec3 rotateZ(double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Vec3(x * cos - y * sin, x * sin + y * cos, z);
  }

  Vec2 toVec2() => Vec2(x, y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'z': z};

  factory Vec3.fromJson(Map<String, dynamic> json) =>
      Vec3(json['x'] as double, json['y'] as double, json['z'] as double);

  @override
  String toString() => 'Vec3($x, $y, $z)';
}

/// 3D Face (triangle or quad)
class Face3D {
  final List<int> vertexIndices;
  final Vec3? normal;

  Face3D(this.vertexIndices, {this.normal});

  bool get isTriangle => vertexIndices.length == 3;
  bool get isQuad => vertexIndices.length == 4;
}

/// 3D Edge
class Edge3D {
  final int startIndex;
  final int endIndex;
  final bool isHard; // Hard edge (visible) vs smooth edge

  Edge3D(this.startIndex, this.endIndex, {this.isHard = true});
}

/// 3D Mesh representing geometry
class Mesh3D {
  final List<Vec3> vertices;
  final List<Face3D> faces;
  final List<Edge3D> edges;
  String name;

  Mesh3D({
    required this.vertices,
    required this.faces,
    required this.edges,
    this.name = 'Mesh',
  });

  /// Create empty mesh
  factory Mesh3D.empty() => Mesh3D(vertices: [], faces: [], edges: []);

  /// Calculate bounding box
  (Vec3 min, Vec3 max) get bounds {
    if (vertices.isEmpty) {
      return (Vec3.zero, Vec3.zero);
    }

    double minX = vertices[0].x, minY = vertices[0].y, minZ = vertices[0].z;
    double maxX = vertices[0].x, maxY = vertices[0].y, maxZ = vertices[0].z;

    for (final v in vertices) {
      if (v.x < minX) minX = v.x;
      if (v.y < minY) minY = v.y;
      if (v.z < minZ) minZ = v.z;
      if (v.x > maxX) maxX = v.x;
      if (v.y > maxY) maxY = v.y;
      if (v.z > maxZ) maxZ = v.z;
    }

    return (Vec3(minX, minY, minZ), Vec3(maxX, maxY, maxZ));
  }

  /// Calculate center point
  Vec3 get center {
    final (min, max) = bounds;
    return Vec3(
      (min.x + max.x) / 2,
      (min.y + max.y) / 2,
      (min.z + max.z) / 2,
    );
  }
}

/// Type of 3D operation
enum Operation3DType {
  extrude,
  revolve,
  loft,
  sweep,
  fillet,
  chamfer,
  boolean,
}

/// Extrusion mode
enum ExtrudeMode {
  single,           // Extrude in one direction
  symmetric,        // Extrude equally in both directions
  twoSided,         // Extrude with different values each direction
}

/// Boolean operation type
enum BooleanType {
  union,
  difference,
  intersection,
}

/// Base class for 3D operations
abstract class Operation3D {
  final String id;
  final Operation3DType type;
  final String name;
  bool isVisible = true;

  Operation3D({
    required this.id,
    required this.type,
    required this.name,
  });

  /// Generate mesh from this operation
  Mesh3D generateMesh(List<SketchEntity> sketchEntities);

  Map<String, dynamic> toJson();
}

/// Extrude operation - creates 3D geometry from 2D profile
class ExtrudeOperation extends Operation3D {
  double distance;
  ExtrudeMode mode;
  double? secondDistance; // For two-sided mode
  bool addDraft;
  double draftAngle;
  List<String> profileEntityIds; // IDs of sketch entities to extrude

  ExtrudeOperation({
    required super.id,
    required this.distance,
    this.mode = ExtrudeMode.single,
    this.secondDistance,
    this.addDraft = false,
    this.draftAngle = 0,
    required this.profileEntityIds,
  }) : super(type: Operation3DType.extrude, name: 'Extrude');

  @override
  Mesh3D generateMesh(List<SketchEntity> sketchEntities) {
    final List<Vec3> vertices = [];
    final List<Face3D> faces = [];
    final List<Edge3D> edges = [];

    // Get profile entities
    final profileEntities = sketchEntities
        .where((e) => profileEntityIds.contains(e.id))
        .toList();

    if (profileEntities.isEmpty) {
      return Mesh3D.empty();
    }

    // For now, handle simple shapes (rectangle, circle)
    for (final entity in profileEntities) {
      if (entity is RectangleEntity) {
        _extrudeRectangle(entity, vertices, faces, edges);
      } else if (entity is CircleEntity) {
        _extrudeCircle(entity, vertices, faces, edges);
      } else if (entity is LineEntity) {
        // Lines can be extruded to create surfaces
        _extrudeLine(entity, vertices, faces, edges);
      }
    }

    return Mesh3D(
      vertices: vertices,
      faces: faces,
      edges: edges,
      name: 'Extrusion',
    );
  }

  void _extrudeRectangle(
    RectangleEntity rect,
    List<Vec3> vertices,
    List<Face3D> faces,
    List<Edge3D> edges,
  ) {
    final baseIndex = vertices.length;
    final corners = rect.corners;

    // Calculate extrusion heights based on mode
    double startZ = 0, endZ = distance;
    if (mode == ExtrudeMode.symmetric) {
      startZ = -distance / 2;
      endZ = distance / 2;
    } else if (mode == ExtrudeMode.twoSided && secondDistance != null) {
      startZ = -secondDistance!;
      endZ = distance;
    }

    // Bottom face vertices
    for (final corner in corners) {
      vertices.add(Vec3(corner.x, corner.y, startZ));
    }

    // Top face vertices
    for (final corner in corners) {
      vertices.add(Vec3(corner.x, corner.y, endZ));
    }

    // Bottom face
    faces.add(Face3D([baseIndex, baseIndex + 1, baseIndex + 2, baseIndex + 3]));

    // Top face
    faces.add(Face3D([baseIndex + 4, baseIndex + 7, baseIndex + 6, baseIndex + 5]));

    // Side faces
    for (int i = 0; i < 4; i++) {
      final next = (i + 1) % 4;
      faces.add(Face3D([
        baseIndex + i,
        baseIndex + next,
        baseIndex + next + 4,
        baseIndex + i + 4,
      ]));
    }

    // Edges - bottom
    for (int i = 0; i < 4; i++) {
      edges.add(Edge3D(baseIndex + i, baseIndex + (i + 1) % 4));
    }

    // Edges - top
    for (int i = 0; i < 4; i++) {
      edges.add(Edge3D(baseIndex + 4 + i, baseIndex + 4 + (i + 1) % 4));
    }

    // Edges - vertical
    for (int i = 0; i < 4; i++) {
      edges.add(Edge3D(baseIndex + i, baseIndex + 4 + i));
    }
  }

  void _extrudeCircle(
    CircleEntity circle,
    List<Vec3> vertices,
    List<Face3D> faces,
    List<Edge3D> edges,
  ) {
    final baseIndex = vertices.length;
    const segments = 32;

    double startZ = 0, endZ = distance;
    if (mode == ExtrudeMode.symmetric) {
      startZ = -distance / 2;
      endZ = distance / 2;
    }

    // Generate circle vertices
    for (int i = 0; i < segments; i++) {
      final angle = (2 * math.pi * i) / segments;
      final x = circle.center.x + circle.radius * math.cos(angle);
      final y = circle.center.y + circle.radius * math.sin(angle);
      vertices.add(Vec3(x, y, startZ));
    }

    // Center point for bottom cap
    final bottomCenterIndex = vertices.length;
    vertices.add(Vec3(circle.center.x, circle.center.y, startZ));

    // Top circle vertices
    for (int i = 0; i < segments; i++) {
      final angle = (2 * math.pi * i) / segments;
      final x = circle.center.x + circle.radius * math.cos(angle);
      final y = circle.center.y + circle.radius * math.sin(angle);
      vertices.add(Vec3(x, y, endZ));
    }

    // Center point for top cap
    final topCenterIndex = vertices.length;
    vertices.add(Vec3(circle.center.x, circle.center.y, endZ));

    // Bottom cap faces (triangles)
    for (int i = 0; i < segments; i++) {
      final next = (i + 1) % segments;
      faces.add(Face3D([bottomCenterIndex, baseIndex + i, baseIndex + next]));
    }

    // Top cap faces
    for (int i = 0; i < segments; i++) {
      final next = (i + 1) % segments;
      faces.add(Face3D([
        topCenterIndex,
        baseIndex + segments + 1 + next,
        baseIndex + segments + 1 + i,
      ]));
    }

    // Side faces
    for (int i = 0; i < segments; i++) {
      final next = (i + 1) % segments;
      faces.add(Face3D([
        baseIndex + i,
        baseIndex + segments + 1 + i,
        baseIndex + segments + 1 + next,
        baseIndex + next,
      ]));
    }

    // Edges - bottom circle
    for (int i = 0; i < segments; i++) {
      edges.add(Edge3D(baseIndex + i, baseIndex + (i + 1) % segments));
    }

    // Edges - top circle
    for (int i = 0; i < segments; i++) {
      edges.add(Edge3D(
        baseIndex + segments + 1 + i,
        baseIndex + segments + 1 + (i + 1) % segments,
      ));
    }
  }

  void _extrudeLine(
    LineEntity line,
    List<Vec3> vertices,
    List<Face3D> faces,
    List<Edge3D> edges,
  ) {
    final baseIndex = vertices.length;

    double startZ = 0, endZ = distance;
    if (mode == ExtrudeMode.symmetric) {
      startZ = -distance / 2;
      endZ = distance / 2;
    }

    // Create a surface from the line
    vertices.add(Vec3(line.start.x, line.start.y, startZ));
    vertices.add(Vec3(line.end.x, line.end.y, startZ));
    vertices.add(Vec3(line.end.x, line.end.y, endZ));
    vertices.add(Vec3(line.start.x, line.start.y, endZ));

    faces.add(Face3D([baseIndex, baseIndex + 1, baseIndex + 2, baseIndex + 3]));

    edges.add(Edge3D(baseIndex, baseIndex + 1));
    edges.add(Edge3D(baseIndex + 1, baseIndex + 2));
    edges.add(Edge3D(baseIndex + 2, baseIndex + 3));
    edges.add(Edge3D(baseIndex + 3, baseIndex));
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'extrude',
    'distance': distance,
    'mode': mode.name,
    'secondDistance': secondDistance,
    'addDraft': addDraft,
    'draftAngle': draftAngle,
    'profileEntityIds': profileEntityIds,
  };

  factory ExtrudeOperation.fromJson(Map<String, dynamic> json) {
    return ExtrudeOperation(
      id: json['id'] as String,
      distance: json['distance'] as double,
      mode: ExtrudeMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => ExtrudeMode.single,
      ),
      secondDistance: json['secondDistance'] as double?,
      addDraft: json['addDraft'] as bool? ?? false,
      draftAngle: json['draftAngle'] as double? ?? 0,
      profileEntityIds: (json['profileEntityIds'] as List).cast<String>(),
    );
  }
}

/// Revolve operation - creates 3D geometry by rotating 2D profile around an axis
class RevolveOperation extends Operation3D {
  double angle; // Angle in radians (full rotation = 2*pi)
  Vec2 axisStart;
  Vec2 axisEnd;
  List<String> profileEntityIds;

  RevolveOperation({
    required super.id,
    required this.angle,
    required this.axisStart,
    required this.axisEnd,
    required this.profileEntityIds,
  }) : super(type: Operation3DType.revolve, name: 'Revolve');

  @override
  Mesh3D generateMesh(List<SketchEntity> sketchEntities) {
    // Simplified revolve - full implementation would need profile tessellation
    final List<Vec3> vertices = [];
    final List<Face3D> faces = [];
    final List<Edge3D> edges = [];

    const segments = 32;

    for (final entity in sketchEntities) {
      if (!profileEntityIds.contains(entity.id)) continue;

      if (entity is LineEntity) {
        _revolveLine(entity, vertices, faces, edges, segments);
      }
    }

    return Mesh3D(
      vertices: vertices,
      faces: faces,
      edges: edges,
      name: 'Revolution',
    );
  }

  void _revolveLine(
    LineEntity line,
    List<Vec3> vertices,
    List<Face3D> faces,
    List<Edge3D> edges,
    int segments,
  ) {
    final baseIndex = vertices.length;

    // Simple revolve around Y axis
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final angleStep = angle * t;

      final cosA = math.cos(angleStep);
      final sinA = math.sin(angleStep);

      // Rotate start point
      vertices.add(Vec3(
        line.start.x * cosA,
        line.start.y,
        line.start.x * sinA,
      ));

      // Rotate end point
      vertices.add(Vec3(
        line.end.x * cosA,
        line.end.y,
        line.end.x * sinA,
      ));
    }

    // Create faces
    for (int i = 0; i < segments; i++) {
      final i0 = baseIndex + i * 2;
      final i1 = baseIndex + i * 2 + 1;
      final i2 = baseIndex + (i + 1) * 2 + 1;
      final i3 = baseIndex + (i + 1) * 2;

      faces.add(Face3D([i0, i3, i2, i1]));
    }

    // Add edges
    for (int i = 0; i <= segments; i++) {
      edges.add(Edge3D(baseIndex + i * 2, baseIndex + i * 2 + 1));
    }
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'revolve',
    'angle': angle,
    'axisStart': axisStart.toJson(),
    'axisEnd': axisEnd.toJson(),
    'profileEntityIds': profileEntityIds,
  };
}

/// Fillet operation - rounds edges
class FilletOperation extends Operation3D {
  double radius;
  List<int> edgeIndices; // Indices of edges to fillet

  FilletOperation({
    required super.id,
    required this.radius,
    required this.edgeIndices,
  }) : super(type: Operation3DType.fillet, name: 'Fillet');

  @override
  Mesh3D generateMesh(List<SketchEntity> sketchEntities) {
    // Fillet is applied to existing mesh edges
    // This is a placeholder - full implementation would modify mesh geometry
    return Mesh3D.empty();
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'fillet',
    'radius': radius,
    'edgeIndices': edgeIndices,
  };
}

/// Chamfer operation - bevels edges
class ChamferOperation extends Operation3D {
  double distance;
  double? secondDistance; // For asymmetric chamfers
  List<int> edgeIndices;

  ChamferOperation({
    required super.id,
    required this.distance,
    this.secondDistance,
    required this.edgeIndices,
  }) : super(type: Operation3DType.chamfer, name: 'Chamfer');

  @override
  Mesh3D generateMesh(List<SketchEntity> sketchEntities) {
    return Mesh3D.empty();
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'chamfer',
    'distance': distance,
    'secondDistance': secondDistance,
    'edgeIndices': edgeIndices,
  };
}

/// Camera for 3D view
class Camera3D {
  Vec3 position;
  Vec3 target;
  Vec3 up;
  double fov; // Field of view in radians
  bool isOrthographic;
  double orthoScale;

  Camera3D({
    this.position = const Vec3(100, 100, 100),
    this.target = const Vec3(0, 0, 0),
    this.up = const Vec3(0, 0, 1),
    this.fov = 0.785, // 45 degrees
    this.isOrthographic = false,
    this.orthoScale = 1.0,
  });

  /// Rotate camera around target
  void orbit(double deltaX, double deltaY) {
    final offset = position - target;
    final distance = offset.length;

    // Calculate spherical coordinates
    var theta = math.atan2(offset.x, offset.y);
    var phi = math.acos((offset.z / distance).clamp(-1.0, 1.0));

    // Apply rotation
    theta += deltaX * 0.01;
    phi = (phi + deltaY * 0.01).clamp(0.1, math.pi - 0.1);

    // Convert back to Cartesian
    position = Vec3(
      distance * math.sin(phi) * math.sin(theta) + target.x,
      distance * math.sin(phi) * math.cos(theta) + target.y,
      distance * math.cos(phi) + target.z,
    );
  }

  /// Pan camera
  void pan(double deltaX, double deltaY) {
    final forward = (target - position).normalized;
    final right = forward.cross(up).normalized;
    final actualUp = right.cross(forward).normalized;

    final panX = right * (-deltaX * 0.5);
    final panY = actualUp * (deltaY * 0.5);

    position = position + panX + panY;
    target = target + panX + panY;
  }

  /// Zoom camera
  void zoom(double factor) {
    if (isOrthographic) {
      orthoScale = (orthoScale / factor).clamp(0.1, 100.0);
    } else {
      final offset = position - target;
      final newDistance = (offset.length / factor).clamp(10.0, 10000.0);
      position = target + offset.normalized * newDistance;
    }
  }

  /// Reset to default view
  void reset() {
    position = const Vec3(100, 100, 100);
    target = const Vec3(0, 0, 0);
    up = const Vec3(0, 0, 1);
    orthoScale = 1.0;
  }

  /// Frame to fit bounds
  void frameToFit(Vec3 min, Vec3 max) {
    final center = Vec3(
      (min.x + max.x) / 2,
      (min.y + max.y) / 2,
      (min.z + max.z) / 2,
    );

    final size = Vec3(
      (max.x - min.x).abs(),
      (max.y - min.y).abs(),
      (max.z - min.z).abs(),
    );

    final maxDim = [size.x, size.y, size.z].reduce(math.max);
    final distance = maxDim * 2;

    target = center;
    position = center + Vec3(distance, distance, distance * 0.7);
  }

  /// Project 3D point to 2D screen coordinates
  Vec2 project(Vec3 point, double screenWidth, double screenHeight) {
    final forward = (target - position).normalized;
    final right = forward.cross(up).normalized;
    final actualUp = right.cross(forward).normalized;

    final toPoint = point - position;
    final distance = toPoint.dot(forward);

    if (distance <= 0) {
      return Vec2(-1000, -1000); // Behind camera
    }

    if (isOrthographic) {
      final x = toPoint.dot(right) / orthoScale;
      final y = toPoint.dot(actualUp) / orthoScale;
      return Vec2(
        screenWidth / 2 + x,
        screenHeight / 2 - y,
      );
    } else {
      final scale = (screenWidth / 2) / (distance * math.tan(fov / 2));
      final x = toPoint.dot(right) * scale;
      final y = toPoint.dot(actualUp) * scale;
      return Vec2(
        screenWidth / 2 + x,
        screenHeight / 2 - y,
      );
    }
  }
}
