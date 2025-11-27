import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:cad_app/src/features/viewer/domain/camera_model.dart';

void main() {
  group('CameraModel', () {
    late CameraModel camera;

    setUp(() {
      camera = CameraModel.defaultCamera();
    });

    test('defaultCamera creates valid camera', () {
      expect(camera.position.z, 10.0);
      expect(camera.target, equals(Vector3.zero()));
      expect(camera.up.y, 1.0);
      expect(camera.fovY, 60.0);
      expect(camera.near, 0.1);
      expect(camera.far, 1000.0);
    });

    test('copyWith creates new instance with updated position', () {
      final newPos = Vector3(5, 5, 5);
      final updated = camera.copyWith(position: newPos);

      expect(updated.position.x, 5.0);
      expect(updated.position.y, 5.0);
      expect(updated.position.z, 5.0);
      expect(updated.target, equals(camera.target));
    });

    test('copyWith without arguments preserves values', () {
      final copy = camera.copyWith();

      expect(copy.fovY, camera.fovY);
      expect(copy.near, camera.near);
      expect(copy.far, camera.far);
    });

    test('viewMatrix returns valid matrix', () {
      final viewMatrix = camera.viewMatrix;

      expect(viewMatrix, isA<Matrix4>());
      // View matrix should be invertible
      expect(viewMatrix.determinant(), isNot(0.0));
    });

    test('projectionMatrix returns valid matrix for reasonable aspect', () {
      final projMatrix = camera.projectionMatrix(16 / 9);

      expect(projMatrix, isA<Matrix4>());
    });

    test('zoom increases distance when factor > 1', () {
      final initialDistance = (camera.position - camera.target).length;
      final zoomed = camera.zoom(1.5);
      final newDistance = (zoomed.position - zoomed.target).length;

      expect(newDistance, greaterThan(initialDistance));
    });

    test('zoom decreases distance when factor < 1', () {
      final initialDistance = (camera.position - camera.target).length;
      final zoomed = camera.zoom(0.5);
      final newDistance = (zoomed.position - zoomed.target).length;

      expect(newDistance, lessThan(initialDistance));
    });

    test('pan moves both position and target', () {
      final panned = camera.pan(5.0, 0.0);

      // Target should have moved
      expect(panned.target, isNot(equals(camera.target)));
      // Position should have moved by same amount
      final positionDelta = panned.position - camera.position;
      final targetDelta = panned.target - camera.target;
      expect(positionDelta.x, closeTo(targetDelta.x, 0.001));
      expect(positionDelta.y, closeTo(targetDelta.y, 0.001));
      expect(positionDelta.z, closeTo(targetDelta.z, 0.001));
    });

    test('orbit changes position but keeps target', () {
      final orbited = camera.orbit(0.5, 0.0);

      expect(orbited.target, equals(camera.target));
      expect(orbited.position, isNot(equals(camera.position)));
    });

    test('orbit preserves distance to target', () {
      final initialDistance = (camera.position - camera.target).length;
      final orbited = camera.orbit(0.3, 0.2);
      final newDistance = (orbited.position - orbited.target).length;

      expect(newDistance, closeTo(initialDistance, 0.001));
    });
  });
}
