/// Types of geometric constraints for sketch solving.
enum SketchConstraintType {
  /// Two points are at the same location.
  coincident,

  /// A segment is horizontal.
  horizontal,

  /// A segment is vertical.
  vertical,

  /// Two segments are perpendicular.
  perpendicular,

  /// Two segments are parallel.
  parallel,

  /// Two segments have equal length.
  equalLength,

  /// Two points are at a fixed distance.
  distance,

  /// A circle has a fixed radius.
  radius,

  /// Two segments meet at a tangent.
  tangent,

  /// A point is on a line/curve.
  pointOnCurve,

  /// An angle between segments.
  angle,

  /// A segment is midpoint of another.
  midpoint,

  /// Symmetric about a line.
  symmetric,

  /// Point is at origin.
  fixedPoint,
}

/// A geometric constraint in the sketch.
class SketchConstraint {
  final String id;
  final SketchConstraintType type;

  /// IDs of entities involved (points, segments, circles).
  final List<String> entityIds;

  /// Optional value for dimensional constraints (distance, radius, angle).
  final double? value;

  /// Whether this constraint is a reference (display only, not enforced).
  final bool isReference;

  const SketchConstraint({
    required this.id,
    required this.type,
    required this.entityIds,
    this.value,
    this.isReference = false,
  });

  SketchConstraint copyWith({
    SketchConstraintType? type,
    List<String>? entityIds,
    double? value,
    bool? isReference,
  }) {
    return SketchConstraint(
      id: id,
      type: type ?? this.type,
      entityIds: entityIds ?? List.from(this.entityIds),
      value: value ?? this.value,
      isReference: isReference ?? this.isReference,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SketchConstraint && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SketchConstraint(id: $id, type: $type, entities: $entityIds, value: $value)';
}

/// Result from constraint solving.
enum SolveResult {
  /// All constraints satisfied.
  fullyConstrained,

  /// Some degrees of freedom remain.
  underConstrained,

  /// Constraints conflict.
  overConstrained,

  /// Solver failed to converge.
  failed,
}
