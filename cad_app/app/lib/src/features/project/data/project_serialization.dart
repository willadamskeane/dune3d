import 'dart:convert';

import 'package:vector_math/vector_math_64.dart';

import '../domain/project_entity.dart';
import '../../sketch/domain/sketch_entities.dart';
import '../../sketch/domain/sketch_constraints.dart';
import '../../viewer/domain/mesh_model.dart';

/// Serialization utilities for project data.
class ProjectSerializer {
  ProjectSerializer._();

  /// Serialize a project entity to JSON.
  static Map<String, dynamic> projectToJson(ProjectEntity project) {
    return {
      'id': project.id,
      'name': project.name,
      'createdAt': project.createdAt.toIso8601String(),
      'updatedAt': project.updatedAt.toIso8601String(),
    };
  }

  /// Deserialize a project entity from JSON.
  static ProjectEntity projectFromJson(Map<String, dynamic> json) {
    return ProjectEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Serialize a sketch point to JSON.
  static Map<String, dynamic> pointToJson(SketchPoint point) {
    return {
      'id': point.id,
      'x': point.position.x,
      'y': point.position.y,
      'isFixed': point.isFixed,
    };
  }

  /// Deserialize a sketch point from JSON.
  static SketchPoint pointFromJson(Map<String, dynamic> json) {
    return SketchPoint(
      id: json['id'] as String,
      position: Vector2(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      isFixed: json['isFixed'] as bool? ?? false,
    );
  }

  /// Serialize a sketch segment to JSON.
  static Map<String, dynamic> segmentToJson(SketchSegment segment) {
    return {
      'id': segment.id,
      'startPointId': segment.startPointId,
      'endPointId': segment.endPointId,
    };
  }

  /// Deserialize a sketch segment from JSON.
  static SketchSegment segmentFromJson(Map<String, dynamic> json) {
    return SketchSegment(
      id: json['id'] as String,
      startPointId: json['startPointId'] as String,
      endPointId: json['endPointId'] as String,
    );
  }

  /// Serialize a sketch circle to JSON.
  static Map<String, dynamic> circleToJson(SketchCircle circle) {
    return {
      'id': circle.id,
      'centerPointId': circle.centerPointId,
      'radiusPointId': circle.radiusPointId,
    };
  }

  /// Deserialize a sketch circle from JSON.
  static SketchCircle circleFromJson(Map<String, dynamic> json) {
    return SketchCircle(
      id: json['id'] as String,
      centerPointId: json['centerPointId'] as String,
      radiusPointId: json['radiusPointId'] as String,
    );
  }

  /// Serialize a sketch arc to JSON.
  static Map<String, dynamic> arcToJson(SketchArc arc) {
    return {
      'id': arc.id,
      'centerPointId': arc.centerPointId,
      'startPointId': arc.startPointId,
      'endPointId': arc.endPointId,
      'clockwise': arc.clockwise,
    };
  }

  /// Deserialize a sketch arc from JSON.
  static SketchArc arcFromJson(Map<String, dynamic> json) {
    return SketchArc(
      id: json['id'] as String,
      centerPointId: json['centerPointId'] as String,
      startPointId: json['startPointId'] as String,
      endPointId: json['endPointId'] as String,
      clockwise: json['clockwise'] as bool? ?? false,
    );
  }

  /// Serialize a constraint to JSON.
  static Map<String, dynamic> constraintToJson(SketchConstraint constraint) {
    return {
      'id': constraint.id,
      'type': constraint.type.name,
      'entityIds': constraint.entityIds,
      'value': constraint.value,
      'isReference': constraint.isReference,
    };
  }

  /// Deserialize a constraint from JSON.
  static SketchConstraint constraintFromJson(Map<String, dynamic> json) {
    return SketchConstraint(
      id: json['id'] as String,
      type: SketchConstraintType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => SketchConstraintType.distance,
      ),
      entityIds: (json['entityIds'] as List).cast<String>(),
      value: (json['value'] as num?)?.toDouble(),
      isReference: json['isReference'] as bool? ?? false,
    );
  }

  /// Serialize a mesh to JSON.
  static Map<String, dynamic> meshToJson(Mesh mesh) {
    return {
      'id': mesh.id,
      'positions': mesh.positions,
      'normals': mesh.normals,
      'indices': mesh.indices,
    };
  }

  /// Deserialize a mesh from JSON.
  static Mesh meshFromJson(Map<String, dynamic> json) {
    return Mesh(
      id: json['id'] as String,
      positions: (json['positions'] as List).cast<double>(),
      normals: (json['normals'] as List).cast<double>(),
      indices: (json['indices'] as List).cast<int>(),
    );
  }
}

/// Complete project data for serialization.
class ProjectData {
  final ProjectEntity metadata;
  final List<SketchPoint> sketchPoints;
  final List<SketchSegment> sketchSegments;
  final List<SketchCircle> sketchCircles;
  final List<SketchArc> sketchArcs;
  final List<SketchConstraint> sketchConstraints;
  final List<Mesh> meshes;

  const ProjectData({
    required this.metadata,
    this.sketchPoints = const [],
    this.sketchSegments = const [],
    this.sketchCircles = const [],
    this.sketchArcs = const [],
    this.sketchConstraints = const [],
    this.meshes = const [],
  });

  /// Serialize to JSON string.
  String toJsonString() {
    final json = {
      'version': 1,
      'metadata': ProjectSerializer.projectToJson(metadata),
      'sketch': {
        'points': sketchPoints.map(ProjectSerializer.pointToJson).toList(),
        'segments': sketchSegments.map(ProjectSerializer.segmentToJson).toList(),
        'circles': sketchCircles.map(ProjectSerializer.circleToJson).toList(),
        'arcs': sketchArcs.map(ProjectSerializer.arcToJson).toList(),
        'constraints':
            sketchConstraints.map(ProjectSerializer.constraintToJson).toList(),
      },
      'meshes': meshes.map(ProjectSerializer.meshToJson).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  /// Deserialize from JSON string.
  static ProjectData fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    final metadata = ProjectSerializer.projectFromJson(
      json['metadata'] as Map<String, dynamic>,
    );

    final sketch = json['sketch'] as Map<String, dynamic>? ?? {};

    final points = (sketch['points'] as List?)
            ?.map((e) =>
                ProjectSerializer.pointFromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final segments = (sketch['segments'] as List?)
            ?.map((e) =>
                ProjectSerializer.segmentFromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final circles = (sketch['circles'] as List?)
            ?.map((e) =>
                ProjectSerializer.circleFromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final arcs = (sketch['arcs'] as List?)
            ?.map(
                (e) => ProjectSerializer.arcFromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final constraints = (sketch['constraints'] as List?)
            ?.map((e) =>
                ProjectSerializer.constraintFromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final meshes = (json['meshes'] as List?)
            ?.map(
                (e) => ProjectSerializer.meshFromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ProjectData(
      metadata: metadata,
      sketchPoints: points,
      sketchSegments: segments,
      sketchCircles: circles,
      sketchArcs: arcs,
      sketchConstraints: constraints,
      meshes: meshes,
    );
  }
}
