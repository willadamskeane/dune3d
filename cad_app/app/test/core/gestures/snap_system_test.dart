import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cad_app/src/core/gestures/snap_system.dart';

void main() {
  group('SnapSystem', () {
    late SnapSystem snapSystem;

    setUp(() {
      snapSystem = SnapSystem(
        config: const SnapConfig(
          gridEnabled: true,
          gridSize: 10.0,
          entitySnapEnabled: true,
          snapRadius: 15.0,
        ),
      );
    });

    test('snaps to grid when no entity targets', () {
      final result = snapSystem.snap(const Offset(13, 17));

      expect(result.snapped, isTrue);
      expect(result.snapType, equals(SnapType.grid));
      expect(result.position, equals(const Offset(10, 20)));
    });

    test('snaps to entity when within radius', () {
      snapSystem.addTarget(const SnapTarget(
        position: Offset(50, 50),
        type: SnapType.endpoint,
        entityId: 'test_entity',
      ));

      final result = snapSystem.snap(const Offset(55, 48));

      expect(result.snapped, isTrue);
      expect(result.snapType, equals(SnapType.endpoint));
      expect(result.entityId, equals('test_entity'));
      expect(result.position, equals(const Offset(50, 50)));
    });

    test('does not snap to entity when outside radius', () {
      snapSystem.addTarget(const SnapTarget(
        position: Offset(50, 50),
        type: SnapType.endpoint,
        entityId: 'test_entity',
      ));

      final result = snapSystem.snap(const Offset(100, 100));

      // Should snap to grid instead
      expect(result.snapped, isTrue);
      expect(result.snapType, equals(SnapType.grid));
      expect(result.position, equals(const Offset(100, 100)));
    });

    test('clears targets correctly', () {
      snapSystem.addTarget(const SnapTarget(
        position: Offset(50, 50),
        type: SnapType.endpoint,
      ));

      snapSystem.clearTargets();

      final result = snapSystem.snap(const Offset(52, 48));
      expect(result.snapType, equals(SnapType.grid));
    });

    test('applies angle constraint', () {
      final result = snapSystem.applyAngleConstraint(
        const Offset(100, 10),
        Offset.zero,
      );

      // With 15-degree increments, (100, 10) is close to 0 degrees
      // so it should snap to horizontal
      expect(result.dy.abs(), lessThan(1));
    });
  });

  group('SnapSystem static methods', () {
    test('targetsForSegment creates correct targets', () {
      final targets = SnapSystem.targetsForSegment(
        start: const Offset(0, 0),
        end: const Offset(100, 0),
        segmentId: 'seg1',
      );

      expect(targets.length, equals(3));

      // Check endpoints
      expect(targets[0].type, equals(SnapType.endpoint));
      expect(targets[0].position, equals(const Offset(0, 0)));
      expect(targets[1].type, equals(SnapType.endpoint));
      expect(targets[1].position, equals(const Offset(100, 0)));

      // Check midpoint
      expect(targets[2].type, equals(SnapType.midpoint));
      expect(targets[2].position, equals(const Offset(50, 0)));
    });

    test('targetsForCircle creates correct targets', () {
      final targets = SnapSystem.targetsForCircle(
        center: const Offset(50, 50),
        radius: 25,
        circleId: 'circle1',
      );

      expect(targets.length, equals(5));

      // Check center
      expect(targets[0].type, equals(SnapType.center));
      expect(targets[0].position, equals(const Offset(50, 50)));

      // Check quadrant points
      expect(targets[1].position, equals(const Offset(75, 50))); // Right
      expect(targets[2].position, equals(const Offset(25, 50))); // Left
      expect(targets[3].position, equals(const Offset(50, 75))); // Bottom
      expect(targets[4].position, equals(const Offset(50, 25))); // Top
    });

    test('segmentIntersection finds correct intersection', () {
      final intersection = SnapSystem.segmentIntersection(
        const Offset(0, 0),
        const Offset(100, 100),
        const Offset(0, 100),
        const Offset(100, 0),
      );

      expect(intersection, isNotNull);
      expect(intersection!.dx, closeTo(50, 0.01));
      expect(intersection.dy, closeTo(50, 0.01));
    });

    test('segmentIntersection returns null for parallel lines', () {
      final intersection = SnapSystem.segmentIntersection(
        const Offset(0, 0),
        const Offset(100, 0),
        const Offset(0, 10),
        const Offset(100, 10),
      );

      expect(intersection, isNull);
    });

    test('segmentIntersection returns null for non-intersecting segments', () {
      final intersection = SnapSystem.segmentIntersection(
        const Offset(0, 0),
        const Offset(10, 10),
        const Offset(50, 0),
        const Offset(60, 10),
      );

      expect(intersection, isNull);
    });

    test('nearestPointOnSegment finds correct point', () {
      final nearest = SnapSystem.nearestPointOnSegment(
        const Offset(50, 50),
        const Offset(0, 0),
        const Offset(100, 0),
      );

      expect(nearest.dx, closeTo(50, 0.01));
      expect(nearest.dy, closeTo(0, 0.01));
    });

    test('nearestPointOnSegment clamps to endpoints', () {
      // Point beyond end
      final nearest1 = SnapSystem.nearestPointOnSegment(
        const Offset(150, 0),
        const Offset(0, 0),
        const Offset(100, 0),
      );
      expect(nearest1, equals(const Offset(100, 0)));

      // Point before start
      final nearest2 = SnapSystem.nearestPointOnSegment(
        const Offset(-50, 0),
        const Offset(0, 0),
        const Offset(100, 0),
      );
      expect(nearest2, equals(const Offset(0, 0)));
    });
  });

  group('SnapConfig', () {
    test('default config has expected values', () {
      const config = SnapConfig();

      expect(config.gridEnabled, isTrue);
      expect(config.gridSize, equals(10.0));
      expect(config.entitySnapEnabled, isTrue);
      expect(config.snapRadius, equals(15.0));
      expect(config.constraintEnabled, isTrue);
      expect(config.angleSnapDegrees, equals(15.0));
    });
  });
}
