import 'dart:math' as math;
import 'geometry.dart';
import 'entities.dart';

/// Type of constraint
enum ConstraintType {
  horizontal,
  vertical,
  parallel,
  perpendicular,
  coincident,
  equal,
  fixed,
  distance,
  angle,
  radius,
  tangent,
  midpoint,
  symmetric,
}

/// Unique identifier for constraints
typedef ConstraintId = String;

/// Base class for constraints
abstract class Constraint {
  final ConstraintId id;
  final ConstraintType type;
  final List<EntityId> entityIds;
  double? value;
  bool isSatisfied = false;

  Constraint({
    required this.id,
    required this.type,
    required this.entityIds,
    this.value,
  });

  /// Check if this constraint is satisfied
  bool check(Map<EntityId, SketchEntity> entities);

  /// Get the error/residual of this constraint
  double getError(Map<EntityId, SketchEntity> entities);

  /// Serialize to JSON
  Map<String, dynamic> toJson();

  /// Get a human-readable description
  String get description;
}

/// Horizontal constraint - makes a line horizontal
class HorizontalConstraint extends Constraint {
  HorizontalConstraint({required super.id, required EntityId lineId})
      : super(type: ConstraintType.horizontal, entityIds: [lineId]);

  @override
  bool check(Map<EntityId, SketchEntity> entities) {
    final entity = entities[entityIds[0]];
    if (entity is LineEntity) {
      return (entity.start.y - entity.end.y).abs() < 1e-6;
    }
    return false;
  }

  @override
  double getError(Map<EntityId, SketchEntity> entities) {
    final entity = entities[entityIds[0]];
    if (entity is LineEntity) {
      return (entity.start.y - entity.end.y).abs();
    }
    return double.infinity;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'horizontal',
        'id': id,
        'entityIds': entityIds,
      };

  @override
  String get description => 'Horizontal';
}

/// Vertical constraint - makes a line vertical
class VerticalConstraint extends Constraint {
  VerticalConstraint({required super.id, required EntityId lineId})
      : super(type: ConstraintType.vertical, entityIds: [lineId]);

  @override
  bool check(Map<EntityId, SketchEntity> entities) {
    final entity = entities[entityIds[0]];
    if (entity is LineEntity) {
      return (entity.start.x - entity.end.x).abs() < 1e-6;
    }
    return false;
  }

  @override
  double getError(Map<EntityId, SketchEntity> entities) {
    final entity = entities[entityIds[0]];
    if (entity is LineEntity) {
      return (entity.start.x - entity.end.x).abs();
    }
    return double.infinity;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'vertical',
        'id': id,
        'entityIds': entityIds,
      };

  @override
  String get description => 'Vertical';
}

/// Distance constraint - sets the distance between two points or length of a line
class DistanceConstraint extends Constraint {
  DistanceConstraint({
    required super.id,
    required List<EntityId> entityIds,
    required double distance,
  }) : super(
          type: ConstraintType.distance,
          entityIds: entityIds,
          value: distance,
        );

  @override
  bool check(Map<EntityId, SketchEntity> entities) {
    return getError(entities) < 1e-6;
  }

  @override
  double getError(Map<EntityId, SketchEntity> entities) {
    if (entityIds.length == 1) {
      // Line length
      final entity = entities[entityIds[0]];
      if (entity is LineEntity) {
        return (entity.length - value!).abs();
      }
    } else if (entityIds.length == 2) {
      // Distance between two entities
      final e1 = entities[entityIds[0]];
      final e2 = entities[entityIds[1]];

      Vec2? p1, p2;
      if (e1 is PointEntity) p1 = e1.position;
      if (e1 is LineEntity) p1 = e1.midpoint;
      if (e1 is CircleEntity) p1 = e1.center;

      if (e2 is PointEntity) p2 = e2.position;
      if (e2 is LineEntity) p2 = e2.midpoint;
      if (e2 is CircleEntity) p2 = e2.center;

      if (p1 != null && p2 != null) {
        return (p1.distanceTo(p2) - value!).abs();
      }
    }
    return double.infinity;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'distance',
        'id': id,
        'entityIds': entityIds,
        'value': value,
      };

  @override
  String get description => 'Distance: ${value?.toStringAsFixed(2)}';
}

/// Angle constraint - sets the angle of a line or between two lines
class AngleConstraint extends Constraint {
  AngleConstraint({
    required super.id,
    required List<EntityId> entityIds,
    required double angleDegrees,
  }) : super(
          type: ConstraintType.angle,
          entityIds: entityIds,
          value: angleDegrees,
        );

  double get angleRadians => value! * math.pi / 180;

  @override
  bool check(Map<EntityId, SketchEntity> entities) {
    return getError(entities) < 1e-6;
  }

  @override
  double getError(Map<EntityId, SketchEntity> entities) {
    if (entityIds.length == 1) {
      final entity = entities[entityIds[0]];
      if (entity is LineEntity) {
        final angle = math.atan2(
          entity.end.y - entity.start.y,
          entity.end.x - entity.start.x,
        );
        final diff = (angle - angleRadians) % (2 * math.pi);
        return math.min(diff, 2 * math.pi - diff);
      }
    } else if (entityIds.length == 2) {
      final e1 = entities[entityIds[0]];
      final e2 = entities[entityIds[1]];

      if (e1 is LineEntity && e2 is LineEntity) {
        final angle1 = math.atan2(
          e1.end.y - e1.start.y,
          e1.end.x - e1.start.x,
        );
        final angle2 = math.atan2(
          e2.end.y - e2.start.y,
          e2.end.x - e2.start.x,
        );
        final diff = ((angle2 - angle1) - angleRadians).abs() % (2 * math.pi);
        return math.min(diff, 2 * math.pi - diff);
      }
    }
    return double.infinity;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'angle',
        'id': id,
        'entityIds': entityIds,
        'value': value,
      };

  @override
  String get description => 'Angle: ${value?.toStringAsFixed(1)}';
}

/// Radius constraint - sets the radius of a circle or arc
class RadiusConstraint extends Constraint {
  RadiusConstraint({
    required super.id,
    required EntityId circleId,
    required double radius,
  }) : super(
          type: ConstraintType.radius,
          entityIds: [circleId],
          value: radius,
        );

  @override
  bool check(Map<EntityId, SketchEntity> entities) {
    return getError(entities) < 1e-6;
  }

  @override
  double getError(Map<EntityId, SketchEntity> entities) {
    final entity = entities[entityIds[0]];
    if (entity is CircleEntity) {
      return (entity.radius - value!).abs();
    }
    if (entity is ArcEntity) {
      return (entity.radius - value!).abs();
    }
    return double.infinity;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'radius',
        'id': id,
        'entityIds': entityIds,
        'value': value,
      };

  @override
  String get description => 'Radius: ${value?.toStringAsFixed(2)}';
}

/// Coincident constraint - makes two points coincide
class CoincidentConstraint extends Constraint {
  CoincidentConstraint({
    required super.id,
    required EntityId entity1Id,
    required EntityId entity2Id,
    this.point1Index = 0,
    this.point2Index = 0,
  }) : super(
          type: ConstraintType.coincident,
          entityIds: [entity1Id, entity2Id],
        );

  final int point1Index;
  final int point2Index;

  @override
  bool check(Map<EntityId, SketchEntity> entities) {
    return getError(entities) < 1e-6;
  }

  @override
  double getError(Map<EntityId, SketchEntity> entities) {
    final e1 = entities[entityIds[0]];
    final e2 = entities[entityIds[1]];

    if (e1 == null || e2 == null) return double.infinity;

    final points1 = e1.controlPoints;
    final points2 = e2.controlPoints;

    if (point1Index < points1.length && point2Index < points2.length) {
      return points1[point1Index].distanceTo(points2[point2Index]);
    }

    return double.infinity;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'coincident',
        'id': id,
        'entityIds': entityIds,
        'point1Index': point1Index,
        'point2Index': point2Index,
      };

  @override
  String get description => 'Coincident';
}

/// Parallel constraint - makes two lines parallel
class ParallelConstraint extends Constraint {
  ParallelConstraint({
    required super.id,
    required EntityId line1Id,
    required EntityId line2Id,
  }) : super(type: ConstraintType.parallel, entityIds: [line1Id, line2Id]);

  @override
  bool check(Map<EntityId, SketchEntity> entities) {
    return getError(entities) < 1e-6;
  }

  @override
  double getError(Map<EntityId, SketchEntity> entities) {
    final e1 = entities[entityIds[0]];
    final e2 = entities[entityIds[1]];

    if (e1 is LineEntity && e2 is LineEntity) {
      final d1 = e1.direction;
      final d2 = e2.direction;
      final cross = d1.cross(d2).abs();
      return cross;
    }

    return double.infinity;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'parallel',
        'id': id,
        'entityIds': entityIds,
      };

  @override
  String get description => 'Parallel';
}

/// Perpendicular constraint - makes two lines perpendicular
class PerpendicularConstraint extends Constraint {
  PerpendicularConstraint({
    required super.id,
    required EntityId line1Id,
    required EntityId line2Id,
  }) : super(type: ConstraintType.perpendicular, entityIds: [line1Id, line2Id]);

  @override
  bool check(Map<EntityId, SketchEntity> entities) {
    return getError(entities) < 1e-6;
  }

  @override
  double getError(Map<EntityId, SketchEntity> entities) {
    final e1 = entities[entityIds[0]];
    final e2 = entities[entityIds[1]];

    if (e1 is LineEntity && e2 is LineEntity) {
      final d1 = e1.direction;
      final d2 = e2.direction;
      final dot = d1.dot(d2).abs();
      return dot;
    }

    return double.infinity;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'perpendicular',
        'id': id,
        'entityIds': entityIds,
      };

  @override
  String get description => 'Perpendicular';
}

/// Equal constraint - makes two entities equal in size
class EqualConstraint extends Constraint {
  EqualConstraint({
    required super.id,
    required EntityId entity1Id,
    required EntityId entity2Id,
  }) : super(type: ConstraintType.equal, entityIds: [entity1Id, entity2Id]);

  @override
  bool check(Map<EntityId, SketchEntity> entities) {
    return getError(entities) < 1e-6;
  }

  @override
  double getError(Map<EntityId, SketchEntity> entities) {
    final e1 = entities[entityIds[0]];
    final e2 = entities[entityIds[1]];

    if (e1 is LineEntity && e2 is LineEntity) {
      return (e1.length - e2.length).abs();
    }

    if (e1 is CircleEntity && e2 is CircleEntity) {
      return (e1.radius - e2.radius).abs();
    }

    return double.infinity;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'equal',
        'id': id,
        'entityIds': entityIds,
      };

  @override
  String get description => 'Equal';
}

/// Factory for creating constraints from JSON
class ConstraintFactory {
  static Constraint fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final id = json['id'] as String;
    final entityIds = (json['entityIds'] as List).cast<String>();

    switch (type) {
      case 'horizontal':
        return HorizontalConstraint(id: id, lineId: entityIds[0]);
      case 'vertical':
        return VerticalConstraint(id: id, lineId: entityIds[0]);
      case 'distance':
        return DistanceConstraint(
          id: id,
          entityIds: entityIds,
          distance: json['value'] as double,
        );
      case 'angle':
        return AngleConstraint(
          id: id,
          entityIds: entityIds,
          angleDegrees: json['value'] as double,
        );
      case 'radius':
        return RadiusConstraint(
          id: id,
          circleId: entityIds[0],
          radius: json['value'] as double,
        );
      case 'coincident':
        return CoincidentConstraint(
          id: id,
          entity1Id: entityIds[0],
          entity2Id: entityIds[1],
          point1Index: json['point1Index'] as int? ?? 0,
          point2Index: json['point2Index'] as int? ?? 0,
        );
      case 'parallel':
        return ParallelConstraint(
          id: id,
          line1Id: entityIds[0],
          line2Id: entityIds[1],
        );
      case 'perpendicular':
        return PerpendicularConstraint(
          id: id,
          line1Id: entityIds[0],
          line2Id: entityIds[1],
        );
      case 'equal':
        return EqualConstraint(
          id: id,
          entity1Id: entityIds[0],
          entity2Id: entityIds[1],
        );
      default:
        throw ArgumentError('Unknown constraint type: $type');
    }
  }
}
