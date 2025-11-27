import 'package:flutter_test/flutter_test.dart';
import 'package:cad_app/src/features/sketch/domain/sketch_constraints.dart';

void main() {
  group('SketchConstraint', () {
    test('constructor sets all properties', () {
      final constraint = SketchConstraint(
        id: 'c1',
        type: SketchConstraintType.distance,
        entityIds: ['p1', 'p2'],
        value: 50.0,
        isReference: true,
      );

      expect(constraint.id, 'c1');
      expect(constraint.type, SketchConstraintType.distance);
      expect(constraint.entityIds, ['p1', 'p2']);
      expect(constraint.value, 50.0);
      expect(constraint.isReference, true);
    });

    test('default value is null', () {
      final constraint = SketchConstraint(
        id: 'c2',
        type: SketchConstraintType.horizontal,
        entityIds: ['s1'],
      );

      expect(constraint.value, isNull);
    });

    test('default isReference is false', () {
      final constraint = SketchConstraint(
        id: 'c3',
        type: SketchConstraintType.vertical,
        entityIds: ['s1'],
      );

      expect(constraint.isReference, false);
    });

    test('copyWith updates type', () {
      final original = SketchConstraint(
        id: 'c1',
        type: SketchConstraintType.horizontal,
        entityIds: ['s1'],
      );
      final updated = original.copyWith(type: SketchConstraintType.vertical);

      expect(updated.type, SketchConstraintType.vertical);
      expect(updated.id, 'c1');
    });

    test('copyWith updates value', () {
      final original = SketchConstraint(
        id: 'c1',
        type: SketchConstraintType.distance,
        entityIds: ['p1', 'p2'],
        value: 10.0,
      );
      final updated = original.copyWith(value: 25.0);

      expect(updated.value, 25.0);
    });

    test('copyWith updates entityIds', () {
      final original = SketchConstraint(
        id: 'c1',
        type: SketchConstraintType.coincident,
        entityIds: ['p1', 'p2'],
      );
      final updated = original.copyWith(entityIds: ['p3', 'p4']);

      expect(updated.entityIds, ['p3', 'p4']);
    });

    test('equality is based on id', () {
      final c1 = SketchConstraint(
        id: 'same',
        type: SketchConstraintType.horizontal,
        entityIds: ['a'],
      );
      final c2 = SketchConstraint(
        id: 'same',
        type: SketchConstraintType.vertical,
        entityIds: ['b'],
      );

      expect(c1, equals(c2));
    });

    test('hashCode is based on id', () {
      final c1 = SketchConstraint(
        id: 'hash-test',
        type: SketchConstraintType.horizontal,
        entityIds: [],
      );
      final c2 = SketchConstraint(
        id: 'hash-test',
        type: SketchConstraintType.vertical,
        entityIds: ['x'],
      );

      expect(c1.hashCode, equals(c2.hashCode));
    });
  });

  group('SketchConstraintType', () {
    test('all constraint types are defined', () {
      expect(SketchConstraintType.values, contains(SketchConstraintType.coincident));
      expect(SketchConstraintType.values, contains(SketchConstraintType.horizontal));
      expect(SketchConstraintType.values, contains(SketchConstraintType.vertical));
      expect(SketchConstraintType.values, contains(SketchConstraintType.perpendicular));
      expect(SketchConstraintType.values, contains(SketchConstraintType.parallel));
      expect(SketchConstraintType.values, contains(SketchConstraintType.equalLength));
      expect(SketchConstraintType.values, contains(SketchConstraintType.distance));
      expect(SketchConstraintType.values, contains(SketchConstraintType.radius));
      expect(SketchConstraintType.values, contains(SketchConstraintType.tangent));
      expect(SketchConstraintType.values, contains(SketchConstraintType.pointOnCurve));
      expect(SketchConstraintType.values, contains(SketchConstraintType.angle));
      expect(SketchConstraintType.values, contains(SketchConstraintType.midpoint));
      expect(SketchConstraintType.values, contains(SketchConstraintType.symmetric));
      expect(SketchConstraintType.values, contains(SketchConstraintType.fixedPoint));
    });
  });

  group('SolveResult', () {
    test('all solve results are defined', () {
      expect(SolveResult.values, contains(SolveResult.fullyConstrained));
      expect(SolveResult.values, contains(SolveResult.underConstrained));
      expect(SolveResult.values, contains(SolveResult.overConstrained));
      expect(SolveResult.values, contains(SolveResult.failed));
    });
  });
}
