import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

/// Types of snap targets.
enum SnapType {
  /// Snap to grid intersection.
  grid,

  /// Snap to point entity.
  point,

  /// Snap to midpoint of a segment.
  midpoint,

  /// Snap to endpoint of a segment.
  endpoint,

  /// Snap to center of circle/arc.
  center,

  /// Snap to intersection of two entities.
  intersection,

  /// Snap to nearest point on entity.
  nearest,

  /// Snap to tangent point.
  tangent,

  /// Snap to perpendicular point.
  perpendicular,

  /// Constrain to horizontal movement.
  horizontal,

  /// Constrain to vertical movement.
  vertical,

  /// Constrain to 45-degree angles.
  angle45,
}

/// Represents a snap target location.
class SnapTarget {
  final Offset position;
  final SnapType type;
  final String? entityId;
  final double priority;

  const SnapTarget({
    required this.position,
    required this.type,
    this.entityId,
    this.priority = 1.0,
  });
}

/// Configuration for the snap system.
class SnapConfig {
  /// Enable grid snapping.
  final bool gridEnabled;

  /// Grid size in units.
  final double gridSize;

  /// Enable entity snapping.
  final bool entitySnapEnabled;

  /// Snap radius in screen pixels.
  final double snapRadius;

  /// Enable constraint snapping (H/V/45).
  final bool constraintEnabled;

  /// Angle snap increment in degrees (0 to disable).
  final double angleSnapDegrees;

  /// Priority order for snap types.
  final List<SnapType> snapPriority;

  const SnapConfig({
    this.gridEnabled = true,
    this.gridSize = 10.0,
    this.entitySnapEnabled = true,
    this.snapRadius = 15.0,
    this.constraintEnabled = true,
    this.angleSnapDegrees = 15.0,
    this.snapPriority = const [
      SnapType.endpoint,
      SnapType.midpoint,
      SnapType.center,
      SnapType.intersection,
      SnapType.perpendicular,
      SnapType.tangent,
      SnapType.nearest,
      SnapType.grid,
    ],
  });
}

/// Service for handling snap-to-grid and snap-to-entity.
class SnapSystem {
  final SnapConfig config;
  final List<SnapTarget> _potentialTargets = [];
  Offset? _referencePoint;

  SnapSystem({this.config = const SnapConfig()});

  /// Set a reference point for constraint calculations.
  void setReferencePoint(Offset? point) {
    _referencePoint = point;
  }

  /// Clear all registered snap targets.
  void clearTargets() {
    _potentialTargets.clear();
  }

  /// Register a snap target.
  void addTarget(SnapTarget target) {
    _potentialTargets.add(target);
  }

  /// Register multiple snap targets.
  void addTargets(Iterable<SnapTarget> targets) {
    _potentialTargets.addAll(targets);
  }

  /// Find the best snap position for the given input position.
  SnapResult snap(Offset position, {bool constrainToAxis = false}) {
    SnapTarget? bestTarget;
    double bestDistance = double.infinity;
    Offset snappedPosition = position;

    // Apply axis constraint first if enabled
    if (constrainToAxis && _referencePoint != null) {
      snappedPosition = _applyAxisConstraint(position, _referencePoint!);
    }

    // Check entity snap targets
    if (config.entitySnapEnabled) {
      for (final target in _potentialTargets) {
        final distance = (target.position - snappedPosition).distance;
        if (distance < config.snapRadius && distance < bestDistance) {
          bestDistance = distance;
          bestTarget = target;
        }
      }
    }

    // Apply snap target if found
    if (bestTarget != null) {
      return SnapResult(
        position: bestTarget.position,
        snapped: true,
        snapType: bestTarget.type,
        entityId: bestTarget.entityId,
      );
    }

    // Apply grid snap
    if (config.gridEnabled) {
      snappedPosition = _snapToGrid(snappedPosition);
      return SnapResult(
        position: snappedPosition,
        snapped: true,
        snapType: SnapType.grid,
      );
    }

    return SnapResult(
      position: snappedPosition,
      snapped: false,
    );
  }

  /// Snap position to grid.
  Offset _snapToGrid(Offset position) {
    final x = (position.dx / config.gridSize).round() * config.gridSize;
    final y = (position.dy / config.gridSize).round() * config.gridSize;
    return Offset(x, y);
  }

  /// Apply horizontal/vertical constraint.
  Offset _applyAxisConstraint(Offset position, Offset reference) {
    final delta = position - reference;

    // Check which axis is dominant
    if (delta.dx.abs() > delta.dy.abs()) {
      // Constrain to horizontal
      return Offset(position.dx, reference.dy);
    } else {
      // Constrain to vertical
      return Offset(reference.dx, position.dy);
    }
  }

  /// Apply angle constraint (snap to nearest angle increment).
  Offset applyAngleConstraint(Offset position, Offset reference) {
    if (config.angleSnapDegrees <= 0) return position;

    final delta = position - reference;
    final distance = delta.distance;
    if (distance < 1) return position;

    final angle = math.atan2(delta.dy, delta.dx);
    final degrees = angle * 180 / math.pi;
    final snappedDegrees =
        (degrees / config.angleSnapDegrees).round() * config.angleSnapDegrees;
    final snappedAngle = snappedDegrees * math.pi / 180;

    return reference +
        Offset(
          distance * math.cos(snappedAngle),
          distance * math.sin(snappedAngle),
        );
  }

  /// Calculate snap targets for a line segment.
  static List<SnapTarget> targetsForSegment({
    required Offset start,
    required Offset end,
    String? segmentId,
  }) {
    return [
      SnapTarget(
        position: start,
        type: SnapType.endpoint,
        entityId: segmentId,
        priority: 1.0,
      ),
      SnapTarget(
        position: end,
        type: SnapType.endpoint,
        entityId: segmentId,
        priority: 1.0,
      ),
      SnapTarget(
        position: Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2),
        type: SnapType.midpoint,
        entityId: segmentId,
        priority: 0.9,
      ),
    ];
  }

  /// Calculate snap targets for a circle.
  static List<SnapTarget> targetsForCircle({
    required Offset center,
    required double radius,
    String? circleId,
  }) {
    return [
      SnapTarget(
        position: center,
        type: SnapType.center,
        entityId: circleId,
        priority: 1.0,
      ),
      // Quadrant points
      SnapTarget(
        position: center + Offset(radius, 0),
        type: SnapType.point,
        entityId: circleId,
        priority: 0.8,
      ),
      SnapTarget(
        position: center + Offset(-radius, 0),
        type: SnapType.point,
        entityId: circleId,
        priority: 0.8,
      ),
      SnapTarget(
        position: center + Offset(0, radius),
        type: SnapType.point,
        entityId: circleId,
        priority: 0.8,
      ),
      SnapTarget(
        position: center + Offset(0, -radius),
        type: SnapType.point,
        entityId: circleId,
        priority: 0.8,
      ),
    ];
  }

  /// Find intersection point of two line segments.
  static Offset? segmentIntersection(
    Offset p1,
    Offset p2,
    Offset p3,
    Offset p4,
  ) {
    final d = (p1.dx - p2.dx) * (p3.dy - p4.dy) -
        (p1.dy - p2.dy) * (p3.dx - p4.dx);
    if (d.abs() < 1e-10) return null;

    final t = ((p1.dx - p3.dx) * (p3.dy - p4.dy) -
            (p1.dy - p3.dy) * (p3.dx - p4.dx)) /
        d;
    final u = -((p1.dx - p2.dx) * (p1.dy - p3.dy) -
            (p1.dy - p2.dy) * (p1.dx - p3.dx)) /
        d;

    if (t >= 0 && t <= 1 && u >= 0 && u <= 1) {
      return Offset(
        p1.dx + t * (p2.dx - p1.dx),
        p1.dy + t * (p2.dy - p1.dy),
      );
    }

    return null;
  }

  /// Find nearest point on a line segment to a given point.
  static Offset nearestPointOnSegment(Offset point, Offset start, Offset end) {
    final l2 = (end - start).distanceSquared;
    if (l2 == 0) return start;

    var t = ((point - start).dx * (end - start).dx +
            (point - start).dy * (end - start).dy) /
        l2;
    t = t.clamp(0.0, 1.0);

    return start + (end - start) * t;
  }
}

/// Result of a snap operation.
class SnapResult {
  final Offset position;
  final bool snapped;
  final SnapType? snapType;
  final String? entityId;

  const SnapResult({
    required this.position,
    required this.snapped,
    this.snapType,
    this.entityId,
  });
}

/// Widget for visualizing snap indicators.
class SnapIndicator extends StatelessWidget {
  final SnapResult? snapResult;
  final double size;

  const SnapIndicator({
    super.key,
    this.snapResult,
    this.size = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    if (snapResult == null || !snapResult!.snapped) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: _SnapIndicatorPainter(
        position: snapResult!.position,
        type: snapResult!.snapType,
        size: size,
      ),
    );
  }
}

class _SnapIndicatorPainter extends CustomPainter {
  final Offset position;
  final SnapType? type;
  final double size;

  _SnapIndicatorPainter({
    required this.position,
    this.type,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    switch (type) {
      case SnapType.endpoint:
        // Square indicator
        canvas.drawRect(
          Rect.fromCenter(center: position, width: size, height: size),
          paint,
        );
        break;

      case SnapType.midpoint:
        // Triangle indicator
        final path = Path()
          ..moveTo(position.dx, position.dy - size / 2)
          ..lineTo(position.dx + size / 2, position.dy + size / 2)
          ..lineTo(position.dx - size / 2, position.dy + size / 2)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case SnapType.center:
        // Circle with cross indicator
        canvas.drawCircle(position, size / 2, paint);
        canvas.drawLine(
          position + Offset(-size / 2, 0),
          position + Offset(size / 2, 0),
          paint,
        );
        canvas.drawLine(
          position + Offset(0, -size / 2),
          position + Offset(0, size / 2),
          paint,
        );
        break;

      case SnapType.intersection:
        // X indicator
        canvas.drawLine(
          position + Offset(-size / 2, -size / 2),
          position + Offset(size / 2, size / 2),
          paint,
        );
        canvas.drawLine(
          position + Offset(size / 2, -size / 2),
          position + Offset(-size / 2, size / 2),
          paint,
        );
        break;

      case SnapType.grid:
        // Small cross indicator
        paint.strokeWidth = 1.0;
        canvas.drawLine(
          position + Offset(-size / 3, 0),
          position + Offset(size / 3, 0),
          paint,
        );
        canvas.drawLine(
          position + Offset(0, -size / 3),
          position + Offset(0, size / 3),
          paint,
        );
        break;

      default:
        // Default circle indicator
        canvas.drawCircle(position, size / 3, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _SnapIndicatorPainter oldDelegate) {
    return oldDelegate.position != position || oldDelegate.type != type;
  }
}
