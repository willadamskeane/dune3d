import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:cad_app/src/features/sketch/state/sketch_providers.dart';
import 'package:cad_app/src/features/sketch/domain/sketch_constraints.dart';

void main() {
  group('SketchState', () {
    test('default state is empty', () {
      const state = SketchState();

      expect(state.points, isEmpty);
      expect(state.segments, isEmpty);
      expect(state.circles, isEmpty);
      expect(state.arcs, isEmpty);
      expect(state.constraints, isEmpty);
      expect(state.isEmpty, true);
    });

    test('isEmpty returns false when has points', () {
      final state = SketchState(
        points: [
          SketchPoint(id: 'p1', position: Vector2.zero()),
        ],
      );

      expect(state.isEmpty, false);
    });

    test('getPoint returns point by id', () {
      final point = SketchPoint(id: 'test-point', position: Vector2(10, 20));
      final state = SketchState(points: [point]);

      final found = state.getPoint('test-point');

      expect(found, isNotNull);
      expect(found!.id, 'test-point');
    });

    test('getPoint returns null for non-existent id', () {
      const state = SketchState();

      final found = state.getPoint('non-existent');

      expect(found, isNull);
    });
  });

  group('SketchStateNotifier', () {
    late ProviderContainer container;
    late SketchStateNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(sketchStateProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('addPoint creates point with correct position', () {
      final point = notifier.addPoint(100, 200);

      expect(point.position.x, 100);
      expect(point.position.y, 200);
      expect(point.id, isNotEmpty);
    });

    test('addPoint updates state', () {
      notifier.addPoint(10, 20);

      final state = container.read(sketchStateProvider);
      expect(state.points.length, 1);
    });

    test('addPoint with isFixed sets fixed flag', () {
      final point = notifier.addPoint(0, 0, isFixed: true);

      expect(point.isFixed, true);
    });

    test('addSegment creates segment between points', () {
      final p1 = notifier.addPoint(0, 0);
      final p2 = notifier.addPoint(100, 0);
      final segment = notifier.addSegment(p1.id, p2.id);

      expect(segment.startPointId, p1.id);
      expect(segment.endPointId, p2.id);
    });

    test('addSegment updates state', () {
      final p1 = notifier.addPoint(0, 0);
      final p2 = notifier.addPoint(100, 0);
      notifier.addSegment(p1.id, p2.id);

      final state = container.read(sketchStateProvider);
      expect(state.segments.length, 1);
    });

    test('addCircle creates circle with center and radius', () {
      final center = notifier.addPoint(50, 50);
      final radius = notifier.addPoint(100, 50);
      final circle = notifier.addCircle(center.id, radius.id);

      expect(circle.centerPointId, center.id);
      expect(circle.radiusPointId, radius.id);
    });

    test('addConstraint creates constraint', () {
      final p1 = notifier.addPoint(0, 0);
      final p2 = notifier.addPoint(100, 0);
      final constraint = notifier.addConstraint(
        SketchConstraintType.distance,
        [p1.id, p2.id],
        value: 100.0,
      );

      expect(constraint.type, SketchConstraintType.distance);
      expect(constraint.value, 100.0);
      expect(constraint.entityIds, contains(p1.id));
      expect(constraint.entityIds, contains(p2.id));
    });

    test('updatePointPosition modifies point position', () {
      final point = notifier.addPoint(0, 0);
      notifier.updatePointPosition(point.id, 50, 75);

      final state = container.read(sketchStateProvider);
      final updated = state.getPoint(point.id);

      expect(updated!.position.x, 50);
      expect(updated.position.y, 75);
    });

    test('deleteEntity removes point', () {
      final point = notifier.addPoint(0, 0);
      notifier.deleteEntity(point.id);

      final state = container.read(sketchStateProvider);
      expect(state.points, isEmpty);
    });

    test('deleteEntity removes related segments', () {
      final p1 = notifier.addPoint(0, 0);
      final p2 = notifier.addPoint(100, 0);
      notifier.addSegment(p1.id, p2.id);

      notifier.deleteEntity(p1.id);

      final state = container.read(sketchStateProvider);
      expect(state.segments, isEmpty);
    });

    test('deleteEntity removes related constraints', () {
      final p1 = notifier.addPoint(0, 0);
      notifier.addConstraint(
        SketchConstraintType.fixedPoint,
        [p1.id],
      );

      notifier.deleteEntity(p1.id);

      final state = container.read(sketchStateProvider);
      expect(state.constraints, isEmpty);
    });

    test('clear removes all entities', () {
      notifier.addPoint(0, 0);
      notifier.addPoint(100, 100);
      notifier.clear();

      final state = container.read(sketchStateProvider);
      expect(state.isEmpty, true);
    });

    test('setSolveResult updates state', () {
      notifier.setSolveResult(SolveResult.fullyConstrained);

      final state = container.read(sketchStateProvider);
      expect(state.lastSolveResult, SolveResult.fullyConstrained);
    });

    test('applySolvedPositions updates point positions', () {
      final p1 = notifier.addPoint(0, 0);
      final p2 = notifier.addPoint(10, 10);

      notifier.applySolvedPositions({
        p1.id: Vector2(5, 5),
        p2.id: Vector2(15, 15),
      });

      final state = container.read(sketchStateProvider);
      final updatedP1 = state.getPoint(p1.id);
      final updatedP2 = state.getPoint(p2.id);

      expect(updatedP1!.position.x, 5);
      expect(updatedP1.position.y, 5);
      expect(updatedP2!.position.x, 15);
      expect(updatedP2.position.y, 15);
    });
  });

  group('SketchToolMode', () {
    test('all tool modes are defined', () {
      expect(SketchToolMode.values, contains(SketchToolMode.select));
      expect(SketchToolMode.values, contains(SketchToolMode.line));
      expect(SketchToolMode.values, contains(SketchToolMode.rectangle));
      expect(SketchToolMode.values, contains(SketchToolMode.circle));
      expect(SketchToolMode.values, contains(SketchToolMode.arc));
      expect(SketchToolMode.values, contains(SketchToolMode.dimension));
      expect(SketchToolMode.values, contains(SketchToolMode.constraint));
    });
  });
}

// Helper class for testing
class SketchPoint {
  final String id;
  final Vector2 position;
  final bool isFixed;

  SketchPoint({
    required this.id,
    required this.position,
    this.isFixed = false,
  });
}
