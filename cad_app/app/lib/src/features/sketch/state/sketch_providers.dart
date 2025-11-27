import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';

import '../domain/sketch_entities.dart';
import '../domain/sketch_constraints.dart';

/// Current state of the sketch being edited.
class SketchState {
  final List<SketchPoint> points;
  final List<SketchSegment> segments;
  final List<SketchCircle> circles;
  final List<SketchArc> arcs;
  final List<SketchConstraint> constraints;
  final SolveResult? lastSolveResult;

  const SketchState({
    this.points = const [],
    this.segments = const [],
    this.circles = const [],
    this.arcs = const [],
    this.constraints = const [],
    this.lastSolveResult,
  });

  SketchState copyWith({
    List<SketchPoint>? points,
    List<SketchSegment>? segments,
    List<SketchCircle>? circles,
    List<SketchArc>? arcs,
    List<SketchConstraint>? constraints,
    SolveResult? lastSolveResult,
  }) {
    return SketchState(
      points: points ?? this.points,
      segments: segments ?? this.segments,
      circles: circles ?? this.circles,
      arcs: arcs ?? this.arcs,
      constraints: constraints ?? this.constraints,
      lastSolveResult: lastSolveResult ?? this.lastSolveResult,
    );
  }

  /// Get point by ID.
  SketchPoint? getPoint(String id) {
    try {
      return points.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Check if sketch is empty.
  bool get isEmpty =>
      points.isEmpty && segments.isEmpty && circles.isEmpty && arcs.isEmpty;
}

/// Provider for the current sketch state.
final sketchStateProvider =
    StateNotifierProvider<SketchStateNotifier, SketchState>((ref) {
  return SketchStateNotifier();
});

/// Notifier for sketch state management.
class SketchStateNotifier extends StateNotifier<SketchState> {
  SketchStateNotifier() : super(const SketchState());

  int _idCounter = 0;

  String _generateId(String prefix) => '${prefix}_${_idCounter++}';

  /// Add a point to the sketch.
  SketchPoint addPoint(double x, double y, {bool isFixed = false}) {
    final point = SketchPoint(
      id: _generateId('point'),
      position: Vector2(x, y),
      isFixed: isFixed,
    );
    state = state.copyWith(points: [...state.points, point]);
    return point;
  }

  /// Add a segment between two points.
  SketchSegment addSegment(String startId, String endId) {
    final segment = SketchSegment(
      id: _generateId('segment'),
      startPointId: startId,
      endPointId: endId,
    );
    state = state.copyWith(segments: [...state.segments, segment]);
    return segment;
  }

  /// Add a circle defined by center and radius point.
  SketchCircle addCircle(String centerId, String radiusId) {
    final circle = SketchCircle(
      id: _generateId('circle'),
      centerPointId: centerId,
      radiusPointId: radiusId,
    );
    state = state.copyWith(circles: [...state.circles, circle]);
    return circle;
  }

  /// Add an arc.
  SketchArc addArc(
    String centerId,
    String startId,
    String endId, {
    bool clockwise = false,
  }) {
    final arc = SketchArc(
      id: _generateId('arc'),
      centerPointId: centerId,
      startPointId: startId,
      endPointId: endId,
      clockwise: clockwise,
    );
    state = state.copyWith(arcs: [...state.arcs, arc]);
    return arc;
  }

  /// Add a constraint.
  SketchConstraint addConstraint(
    SketchConstraintType type,
    List<String> entityIds, {
    double? value,
    bool isReference = false,
  }) {
    final constraint = SketchConstraint(
      id: _generateId('constraint'),
      type: type,
      entityIds: entityIds,
      value: value,
      isReference: isReference,
    );
    state = state.copyWith(constraints: [...state.constraints, constraint]);
    return constraint;
  }

  /// Update a point's position.
  void updatePointPosition(String id, double x, double y) {
    state = state.copyWith(
      points: state.points.map((p) {
        if (p.id == id) {
          return p.copyWith(position: Vector2(x, y));
        }
        return p;
      }).toList(),
    );
  }

  /// Delete an entity and its related constraints.
  void deleteEntity(String id) {
    state = state.copyWith(
      points: state.points.where((p) => p.id != id).toList(),
      segments: state.segments
          .where(
              (s) => s.id != id && s.startPointId != id && s.endPointId != id)
          .toList(),
      circles: state.circles
          .where(
              (c) => c.id != id && c.centerPointId != id && c.radiusPointId != id)
          .toList(),
      arcs: state.arcs
          .where((a) =>
              a.id != id &&
              a.centerPointId != id &&
              a.startPointId != id &&
              a.endPointId != id)
          .toList(),
      constraints: state.constraints
          .where((c) => c.id != id && !c.entityIds.contains(id))
          .toList(),
    );
  }

  /// Clear the entire sketch.
  void clear() {
    _idCounter = 0;
    state = const SketchState();
  }

  /// Update solve result after constraint solving.
  void setSolveResult(SolveResult result) {
    state = state.copyWith(lastSolveResult: result);
  }

  /// Apply solved positions to points.
  void applySolvedPositions(Map<String, Vector2> positions) {
    state = state.copyWith(
      points: state.points.map((p) {
        final newPos = positions[p.id];
        if (newPos != null) {
          return p.copyWith(position: newPos);
        }
        return p;
      }).toList(),
    );
  }
}

/// Currently selected entity ID in sketch mode.
final sketchSelectedEntityProvider = StateProvider<String?>((ref) => null);

/// Current sketch tool mode.
enum SketchToolMode {
  select,
  line,
  rectangle,
  circle,
  arc,
  dimension,
  constraint,
}

/// Provider for current sketch tool.
final sketchToolProvider = StateProvider<SketchToolMode>((ref) {
  return SketchToolMode.select;
});
