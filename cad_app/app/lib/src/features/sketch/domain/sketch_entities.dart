import 'package:vector_math/vector_math_64.dart';

/// A point in 2D sketch space.
class SketchPoint {
  final String id;
  final Vector2 position;
  final bool isFixed;

  const SketchPoint({
    required this.id,
    required this.position,
    this.isFixed = false,
  });

  SketchPoint copyWith({
    Vector2? position,
    bool? isFixed,
  }) {
    return SketchPoint(
      id: id,
      position: position ?? this.position.clone(),
      isFixed: isFixed ?? this.isFixed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SketchPoint && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SketchPoint(id: $id, pos: $position, fixed: $isFixed)';
}

/// A line segment between two points.
class SketchSegment {
  final String id;
  final String startPointId;
  final String endPointId;

  const SketchSegment({
    required this.id,
    required this.startPointId,
    required this.endPointId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SketchSegment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SketchSegment(id: $id, start: $startPointId, end: $endPointId)';
}

/// A circle defined by center and radius point.
class SketchCircle {
  final String id;
  final String centerPointId;
  final String radiusPointId;

  const SketchCircle({
    required this.id,
    required this.centerPointId,
    required this.radiusPointId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SketchCircle && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SketchCircle(id: $id, center: $centerPointId, radius: $radiusPointId)';
}

/// An arc defined by center, start, and end points.
class SketchArc {
  final String id;
  final String centerPointId;
  final String startPointId;
  final String endPointId;
  final bool clockwise;

  const SketchArc({
    required this.id,
    required this.centerPointId,
    required this.startPointId,
    required this.endPointId,
    this.clockwise = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SketchArc && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SketchArc(id: $id, center: $centerPointId, start: $startPointId, end: $endPointId)';
}

/// Types of sketch entities for selection/filtering.
enum SketchEntityType {
  point,
  segment,
  circle,
  arc,
}
