import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:cad_app/src/features/sketch/domain/sketch_entities.dart';

void main() {
  group('SketchPoint', () {
    test('constructor sets all properties', () {
      final point = SketchPoint(
        id: 'p1',
        position: Vector2(10, 20),
        isFixed: true,
      );

      expect(point.id, 'p1');
      expect(point.position.x, 10);
      expect(point.position.y, 20);
      expect(point.isFixed, true);
    });

    test('default isFixed is false', () {
      final point = SketchPoint(
        id: 'p2',
        position: Vector2.zero(),
      );

      expect(point.isFixed, false);
    });

    test('copyWith updates position', () {
      final point = SketchPoint(
        id: 'p1',
        position: Vector2(0, 0),
      );
      final moved = point.copyWith(position: Vector2(50, 100));

      expect(moved.position.x, 50);
      expect(moved.position.y, 100);
      expect(moved.id, 'p1'); // unchanged
    });

    test('copyWith updates isFixed', () {
      final point = SketchPoint(
        id: 'p1',
        position: Vector2(0, 0),
        isFixed: false,
      );
      final fixed = point.copyWith(isFixed: true);

      expect(fixed.isFixed, true);
      expect(fixed.position, equals(point.position));
    });

    test('equality is based on id', () {
      final p1 = SketchPoint(id: 'same', position: Vector2(1, 2));
      final p2 = SketchPoint(id: 'same', position: Vector2(3, 4));

      expect(p1, equals(p2));
    });

    test('hashCode is based on id', () {
      final p1 = SketchPoint(id: 'hash-test', position: Vector2(0, 0));
      final p2 = SketchPoint(id: 'hash-test', position: Vector2(100, 100));

      expect(p1.hashCode, equals(p2.hashCode));
    });
  });

  group('SketchSegment', () {
    test('constructor sets all properties', () {
      final segment = SketchSegment(
        id: 's1',
        startPointId: 'p1',
        endPointId: 'p2',
      );

      expect(segment.id, 's1');
      expect(segment.startPointId, 'p1');
      expect(segment.endPointId, 'p2');
    });

    test('equality is based on id', () {
      final s1 = SketchSegment(id: 'same', startPointId: 'a', endPointId: 'b');
      final s2 = SketchSegment(id: 'same', startPointId: 'c', endPointId: 'd');

      expect(s1, equals(s2));
    });
  });

  group('SketchCircle', () {
    test('constructor sets all properties', () {
      final circle = SketchCircle(
        id: 'c1',
        centerPointId: 'center',
        radiusPointId: 'radius',
      );

      expect(circle.id, 'c1');
      expect(circle.centerPointId, 'center');
      expect(circle.radiusPointId, 'radius');
    });

    test('equality is based on id', () {
      final c1 = SketchCircle(id: 'same', centerPointId: 'a', radiusPointId: 'b');
      final c2 = SketchCircle(id: 'same', centerPointId: 'c', radiusPointId: 'd');

      expect(c1, equals(c2));
    });
  });

  group('SketchArc', () {
    test('constructor sets all properties', () {
      final arc = SketchArc(
        id: 'a1',
        centerPointId: 'center',
        startPointId: 'start',
        endPointId: 'end',
        clockwise: true,
      );

      expect(arc.id, 'a1');
      expect(arc.centerPointId, 'center');
      expect(arc.startPointId, 'start');
      expect(arc.endPointId, 'end');
      expect(arc.clockwise, true);
    });

    test('default clockwise is false', () {
      final arc = SketchArc(
        id: 'a2',
        centerPointId: 'c',
        startPointId: 's',
        endPointId: 'e',
      );

      expect(arc.clockwise, false);
    });
  });
}
