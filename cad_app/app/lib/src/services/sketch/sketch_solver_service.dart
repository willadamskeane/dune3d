import 'package:cad_kernel_plugin/cad_kernel_plugin.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../features/sketch/domain/sketch_entities.dart';
import '../../features/sketch/domain/sketch_constraints.dart';

/// Service for solving geometric constraints in sketches using ShapeOp.
class SketchSolverService {
  final ShapeOpBindings shapeOp;

  SketchSolverService({required this.shapeOp});

  /// Solve constraints and return updated point positions.
  ///
  /// Returns a map of point IDs to their solved positions.
  SolveOutput solve({
    required List<SketchPoint> points,
    required List<SketchSegment> segments,
    required List<SketchCircle> circles,
    required List<SketchConstraint> constraints,
    int iterations = 30,
  }) {
    if (points.isEmpty) {
      return SolveOutput(
        positions: {},
        result: SolveResult.fullyConstrained,
      );
    }

    final solverHandle = shapeOp.createSolver();

    try {
      final pointIndexById = <String, int>{};

      // Add all points to the solver
      for (final p in points) {
        final idx = shapeOp.addPoint(
          solverHandle,
          p.position.x,
          p.position.y,
          isFixed: p.isFixed,
        );
        pointIndexById[p.id] = idx;
      }

      // Track constraint count for determining solve result
      var constraintCount = 0;
      final degreesOfFreedom = points.where((p) => !p.isFixed).length * 2;

      // Map constraints to ShapeOp
      for (final c in constraints) {
        switch (c.type) {
          case SketchConstraintType.coincident:
            if (c.entityIds.length >= 2) {
              final p1 = pointIndexById[c.entityIds[0]];
              final p2 = pointIndexById[c.entityIds[1]];
              if (p1 != null && p2 != null) {
                shapeOp.addCoincidentConstraint(solverHandle, p1, p2);
                constraintCount += 2;
              }
            }
            break;

          case SketchConstraintType.distance:
            if (c.entityIds.length >= 2 && c.value != null) {
              final p1 = pointIndexById[c.entityIds[0]];
              final p2 = pointIndexById[c.entityIds[1]];
              if (p1 != null && p2 != null) {
                shapeOp.addDistanceConstraint(
                  solverHandle,
                  p1,
                  p2,
                  c.value!,
                );
                constraintCount += 1;
              }
            }
            break;

          case SketchConstraintType.horizontal:
            // Find segment and get its points
            final segment = segments
                .where((s) => s.id == c.entityIds.first)
                .firstOrNull;
            if (segment != null) {
              final p1 = pointIndexById[segment.startPointId];
              final p2 = pointIndexById[segment.endPointId];
              if (p1 != null && p2 != null) {
                shapeOp.addHorizontalConstraint(solverHandle, p1, p2);
                constraintCount += 1;
              }
            }
            break;

          case SketchConstraintType.vertical:
            final segment = segments
                .where((s) => s.id == c.entityIds.first)
                .firstOrNull;
            if (segment != null) {
              final p1 = pointIndexById[segment.startPointId];
              final p2 = pointIndexById[segment.endPointId];
              if (p1 != null && p2 != null) {
                shapeOp.addVerticalConstraint(solverHandle, p1, p2);
                constraintCount += 1;
              }
            }
            break;

          case SketchConstraintType.equalLength:
            // Requires two segments
            if (c.entityIds.length >= 2) {
              final seg1 = segments
                  .where((s) => s.id == c.entityIds[0])
                  .firstOrNull;
              final seg2 = segments
                  .where((s) => s.id == c.entityIds[1])
                  .firstOrNull;
              if (seg1 != null && seg2 != null) {
                final s1p1 = pointIndexById[seg1.startPointId];
                final s1p2 = pointIndexById[seg1.endPointId];
                final s2p1 = pointIndexById[seg2.startPointId];
                final s2p2 = pointIndexById[seg2.endPointId];
                if (s1p1 != null && s1p2 != null && s2p1 != null && s2p2 != null) {
                  shapeOp.addEqualLengthConstraint(
                    solverHandle,
                    s1p1,
                    s1p2,
                    s2p1,
                    s2p2,
                  );
                  constraintCount += 1;
                }
              }
            }
            break;

          case SketchConstraintType.fixedPoint:
            final pIdx = pointIndexById[c.entityIds.first];
            if (pIdx != null) {
              shapeOp.setPointFixed(solverHandle, pIdx, true);
              constraintCount += 2;
            }
            break;

          case SketchConstraintType.radius:
            // For circles
            final circle = circles
                .where((circ) => circ.id == c.entityIds.first)
                .firstOrNull;
            if (circle != null && c.value != null) {
              final center = pointIndexById[circle.centerPointId];
              final radiusPoint = pointIndexById[circle.radiusPointId];
              if (center != null && radiusPoint != null) {
                shapeOp.addDistanceConstraint(
                  solverHandle,
                  center,
                  radiusPoint,
                  c.value!,
                );
                constraintCount += 1;
              }
            }
            break;

          default:
            // TODO: Implement remaining constraint types
            break;
        }
      }

      // Solve and fetch positions
      final positions = shapeOp.solveAndFetchPositions(
        solverHandle,
        pointCount: points.length,
        iterations: iterations,
      );

      // Map back to point IDs
      final resultPositions = <String, Vector2>{};
      for (final entry in pointIndexById.entries) {
        final indexStr = entry.value.toString();
        final pos = positions[indexStr];
        if (pos != null) {
          resultPositions[entry.key] = pos;
        }
      }

      // Determine solve result
      SolveResult result;
      if (constraintCount >= degreesOfFreedom) {
        result = SolveResult.fullyConstrained;
      } else if (constraintCount > 0) {
        result = SolveResult.underConstrained;
      } else {
        result = SolveResult.underConstrained;
      }

      return SolveOutput(
        positions: resultPositions,
        result: result,
      );
    } catch (e) {
      return SolveOutput(
        positions: {},
        result: SolveResult.failed,
      );
    } finally {
      shapeOp.destroySolver(solverHandle);
    }
  }
}

/// Output from constraint solving.
class SolveOutput {
  final Map<String, Vector2> positions;
  final SolveResult result;

  const SolveOutput({
    required this.positions,
    required this.result,
  });
}
