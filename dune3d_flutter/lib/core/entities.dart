import 'package:flutter/material.dart';
import 'geometry.dart';

/// Unique identifier for entities
typedef EntityId = String;

/// Type of sketch entity
enum EntityType {
  point,
  line,
  circle,
  arc,
  rectangle,
}

/// Base class for all sketch entities
abstract class SketchEntity {
  final EntityId id;
  final EntityType type;
  bool isSelected = false;
  bool isConstruction = false;

  SketchEntity({required this.id, required this.type});

  /// Get the bounding box of this entity
  BoundingBox get boundingBox;

  /// Distance from a point to this entity (for hit testing)
  double distanceToPoint(Vec2 point);

  /// Get all control points for this entity
  List<Vec2> get controlPoints;

  /// Move this entity by a delta
  void translate(Vec2 delta);

  /// Create a copy of this entity with a new ID
  SketchEntity copyWith({EntityId? newId});

  /// Serialize to JSON
  Map<String, dynamic> toJson();

  /// Render this entity on a canvas
  void render(Canvas canvas, Paint paint, {double scale = 1.0});
}

/// A point entity
class PointEntity extends SketchEntity {
  Vec2 position;

  PointEntity({required super.id, required this.position})
      : super(type: EntityType.point);

  @override
  BoundingBox get boundingBox => BoundingBox(position, position);

  @override
  double distanceToPoint(Vec2 point) => position.distanceTo(point);

  @override
  List<Vec2> get controlPoints => [position];

  @override
  void translate(Vec2 delta) {
    position = position + delta;
  }

  @override
  SketchEntity copyWith({EntityId? newId}) =>
      PointEntity(id: newId ?? id, position: position)
        ..isSelected = isSelected
        ..isConstruction = isConstruction;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'point',
        'id': id,
        'position': position.toJson(),
        'isConstruction': isConstruction,
      };

  factory PointEntity.fromJson(Map<String, dynamic> json) => PointEntity(
        id: json['id'] as String,
        position: Vec2.fromJson(json['position'] as Map<String, dynamic>),
      )..isConstruction = json['isConstruction'] as bool? ?? false;

  @override
  void render(Canvas canvas, Paint paint, {double scale = 1.0}) {
    final pointSize = 6.0 / scale;
    canvas.drawCircle(
      Offset(position.x, position.y),
      pointSize,
      paint,
    );
  }
}

/// A line entity (segment between two points)
class LineEntity extends SketchEntity {
  Vec2 start;
  Vec2 end;

  LineEntity({required super.id, required this.start, required this.end})
      : super(type: EntityType.line);

  Vec2 get direction => (end - start).normalized;
  double get length => start.distanceTo(end);
  Vec2 get midpoint => start.lerp(end, 0.5);

  @override
  BoundingBox get boundingBox => BoundingBox.fromPoints([start, end]);

  @override
  double distanceToPoint(Vec2 point) =>
      GeometryUtils.pointToSegmentDistance(point, start, end);

  @override
  List<Vec2> get controlPoints => [start, end];

  @override
  void translate(Vec2 delta) {
    start = start + delta;
    end = end + delta;
  }

  @override
  SketchEntity copyWith({EntityId? newId}) =>
      LineEntity(id: newId ?? id, start: start, end: end)
        ..isSelected = isSelected
        ..isConstruction = isConstruction;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'line',
        'id': id,
        'start': start.toJson(),
        'end': end.toJson(),
        'isConstruction': isConstruction,
      };

  factory LineEntity.fromJson(Map<String, dynamic> json) => LineEntity(
        id: json['id'] as String,
        start: Vec2.fromJson(json['start'] as Map<String, dynamic>),
        end: Vec2.fromJson(json['end'] as Map<String, dynamic>),
      )..isConstruction = json['isConstruction'] as bool? ?? false;

  @override
  void render(Canvas canvas, Paint paint, {double scale = 1.0}) {
    canvas.drawLine(
      Offset(start.x, start.y),
      Offset(end.x, end.y),
      paint,
    );
  }
}

/// A circle entity
class CircleEntity extends SketchEntity {
  Vec2 center;
  double radius;

  CircleEntity({required super.id, required this.center, required this.radius})
      : super(type: EntityType.circle);

  double get circumference => 2 * 3.14159265359 * radius;
  double get area => 3.14159265359 * radius * radius;

  @override
  BoundingBox get boundingBox => BoundingBox(
        center - Vec2(radius, radius),
        center + Vec2(radius, radius),
      );

  @override
  double distanceToPoint(Vec2 point) =>
      GeometryUtils.pointToCircleDistance(point, center, radius);

  @override
  List<Vec2> get controlPoints => [
        center,
        center + Vec2(radius, 0),
      ];

  @override
  void translate(Vec2 delta) {
    center = center + delta;
  }

  @override
  SketchEntity copyWith({EntityId? newId}) =>
      CircleEntity(id: newId ?? id, center: center, radius: radius)
        ..isSelected = isSelected
        ..isConstruction = isConstruction;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'circle',
        'id': id,
        'center': center.toJson(),
        'radius': radius,
        'isConstruction': isConstruction,
      };

  factory CircleEntity.fromJson(Map<String, dynamic> json) => CircleEntity(
        id: json['id'] as String,
        center: Vec2.fromJson(json['center'] as Map<String, dynamic>),
        radius: json['radius'] as double,
      )..isConstruction = json['isConstruction'] as bool? ?? false;

  @override
  void render(Canvas canvas, Paint paint, {double scale = 1.0}) {
    canvas.drawCircle(
      Offset(center.x, center.y),
      radius,
      paint..style = PaintingStyle.stroke,
    );
  }
}

/// An arc entity
class ArcEntity extends SketchEntity {
  Vec2 center;
  double radius;
  double startAngle; // in radians
  double sweepAngle; // in radians

  ArcEntity({
    required super.id,
    required this.center,
    required this.radius,
    required this.startAngle,
    required this.sweepAngle,
  }) : super(type: EntityType.arc);

  Vec2 get startPoint =>
      center + Vec2.zero().rotate(startAngle) * radius + Vec2(radius, 0);
  Vec2 get endPoint => center +
      Vec2.zero().rotate(startAngle + sweepAngle) * radius +
      Vec2(radius, 0);

  @override
  BoundingBox get boundingBox {
    final points = <Vec2>[
      center + Vec2(radius, 0).rotate(startAngle),
      center + Vec2(radius, 0).rotate(startAngle + sweepAngle),
    ];

    // Check cardinal directions
    for (int i = 0; i < 4; i++) {
      final angle = i * 3.14159265359 / 2;
      if (_angleInArc(angle)) {
        points.add(center + Vec2(radius, 0).rotate(angle));
      }
    }

    return BoundingBox.fromPoints(points);
  }

  bool _angleInArc(double angle) {
    final normalized = _normalizeAngle(angle - startAngle);
    return normalized <= sweepAngle.abs();
  }

  double _normalizeAngle(double angle) {
    while (angle < 0) {
      angle += 2 * 3.14159265359;
    }
    while (angle > 2 * 3.14159265359) {
      angle -= 2 * 3.14159265359;
    }
    return angle;
  }

  @override
  double distanceToPoint(Vec2 point) {
    final toPoint = point - center;
    final angle = toPoint.x == 0 && toPoint.y == 0
        ? 0.0
        : _normalizeAngle((Vec2(1, 0).angleTo(toPoint)));

    if (_angleInArc(angle)) {
      return (toPoint.length - radius).abs();
    }

    final startPt = center + Vec2(radius, 0).rotate(startAngle);
    final endPt = center + Vec2(radius, 0).rotate(startAngle + sweepAngle);

    return [point.distanceTo(startPt), point.distanceTo(endPt)]
        .reduce((a, b) => a < b ? a : b);
  }

  @override
  List<Vec2> get controlPoints => [
        center,
        center + Vec2(radius, 0).rotate(startAngle),
        center + Vec2(radius, 0).rotate(startAngle + sweepAngle),
      ];

  @override
  void translate(Vec2 delta) {
    center = center + delta;
  }

  @override
  SketchEntity copyWith({EntityId? newId}) => ArcEntity(
        id: newId ?? id,
        center: center,
        radius: radius,
        startAngle: startAngle,
        sweepAngle: sweepAngle,
      )
        ..isSelected = isSelected
        ..isConstruction = isConstruction;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'arc',
        'id': id,
        'center': center.toJson(),
        'radius': radius,
        'startAngle': startAngle,
        'sweepAngle': sweepAngle,
        'isConstruction': isConstruction,
      };

  factory ArcEntity.fromJson(Map<String, dynamic> json) => ArcEntity(
        id: json['id'] as String,
        center: Vec2.fromJson(json['center'] as Map<String, dynamic>),
        radius: json['radius'] as double,
        startAngle: json['startAngle'] as double,
        sweepAngle: json['sweepAngle'] as double,
      )..isConstruction = json['isConstruction'] as bool? ?? false;

  @override
  void render(Canvas canvas, Paint paint, {double scale = 1.0}) {
    final rect = Rect.fromCircle(
      center: Offset(center.x, center.y),
      radius: radius,
    );
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      paint..style = PaintingStyle.stroke,
    );
  }
}

/// A rectangle entity (4 lines forming a rectangle)
class RectangleEntity extends SketchEntity {
  Vec2 corner1;
  Vec2 corner2;

  RectangleEntity({required super.id, required this.corner1, required this.corner2})
      : super(type: EntityType.rectangle);

  Vec2 get topLeft => Vec2(
        corner1.x < corner2.x ? corner1.x : corner2.x,
        corner1.y < corner2.y ? corner1.y : corner2.y,
      );

  Vec2 get bottomRight => Vec2(
        corner1.x > corner2.x ? corner1.x : corner2.x,
        corner1.y > corner2.y ? corner1.y : corner2.y,
      );

  Vec2 get topRight => Vec2(bottomRight.x, topLeft.y);
  Vec2 get bottomLeft => Vec2(topLeft.x, bottomRight.y);
  Vec2 get center => topLeft.lerp(bottomRight, 0.5);

  double get width => (corner2.x - corner1.x).abs();
  double get height => (corner2.y - corner1.y).abs();

  List<Vec2> get corners => [topLeft, topRight, bottomRight, bottomLeft];

  @override
  BoundingBox get boundingBox => BoundingBox(topLeft, bottomRight);

  @override
  double distanceToPoint(Vec2 point) {
    final corners = this.corners;
    double minDist = double.infinity;

    for (int i = 0; i < 4; i++) {
      final dist = GeometryUtils.pointToSegmentDistance(
        point,
        corners[i],
        corners[(i + 1) % 4],
      );
      if (dist < minDist) minDist = dist;
    }

    return minDist;
  }

  @override
  List<Vec2> get controlPoints => [corner1, corner2, topRight, bottomLeft];

  @override
  void translate(Vec2 delta) {
    corner1 = corner1 + delta;
    corner2 = corner2 + delta;
  }

  @override
  SketchEntity copyWith({EntityId? newId}) =>
      RectangleEntity(id: newId ?? id, corner1: corner1, corner2: corner2)
        ..isSelected = isSelected
        ..isConstruction = isConstruction;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'rectangle',
        'id': id,
        'corner1': corner1.toJson(),
        'corner2': corner2.toJson(),
        'isConstruction': isConstruction,
      };

  factory RectangleEntity.fromJson(Map<String, dynamic> json) =>
      RectangleEntity(
        id: json['id'] as String,
        corner1: Vec2.fromJson(json['corner1'] as Map<String, dynamic>),
        corner2: Vec2.fromJson(json['corner2'] as Map<String, dynamic>),
      )..isConstruction = json['isConstruction'] as bool? ?? false;

  @override
  void render(Canvas canvas, Paint paint, {double scale = 1.0}) {
    final rect = Rect.fromPoints(
      Offset(topLeft.x, topLeft.y),
      Offset(bottomRight.x, bottomRight.y),
    );
    canvas.drawRect(rect, paint..style = PaintingStyle.stroke);
  }
}

/// Factory for creating entities from JSON
class EntityFactory {
  static SketchEntity fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'point':
        return PointEntity.fromJson(json);
      case 'line':
        return LineEntity.fromJson(json);
      case 'circle':
        return CircleEntity.fromJson(json);
      case 'arc':
        return ArcEntity.fromJson(json);
      case 'rectangle':
        return RectangleEntity.fromJson(json);
      default:
        throw ArgumentError('Unknown entity type: $type');
    }
  }
}
