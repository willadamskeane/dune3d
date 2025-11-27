import 'package:vector_math/vector_math_64.dart';

/// Represents the camera configuration for 3D viewing.
class CameraModel {
  final Vector3 position;
  final Vector3 target;
  final Vector3 up;
  final double fovY;
  final double near;
  final double far;

  const CameraModel({
    required this.position,
    required this.target,
    required this.up,
    required this.fovY,
    required this.near,
    required this.far,
  });

  /// Creates a default camera positioned to view the origin.
  factory CameraModel.defaultCamera() {
    return CameraModel(
      position: Vector3(0, 0, 10),
      target: Vector3.zero(),
      up: Vector3(0, 1, 0),
      fovY: 60.0,
      near: 0.1,
      far: 1000.0,
    );
  }

  CameraModel copyWith({
    Vector3? position,
    Vector3? target,
    Vector3? up,
    double? fovY,
    double? near,
    double? far,
  }) {
    return CameraModel(
      position: position ?? this.position.clone(),
      target: target ?? this.target.clone(),
      up: up ?? this.up.clone(),
      fovY: fovY ?? this.fovY,
      near: near ?? this.near,
      far: far ?? this.far,
    );
  }

  /// Computes the view matrix for this camera.
  Matrix4 get viewMatrix {
    return makeViewMatrix(position, target, up);
  }

  /// Computes the projection matrix for this camera.
  Matrix4 projectionMatrix(double aspectRatio) {
    return makePerspectiveMatrix(
      radians(fovY),
      aspectRatio,
      near,
      far,
    );
  }

  /// Orbit the camera around the target by delta angles (in radians).
  CameraModel orbit(double deltaAzimuth, double deltaElevation) {
    final direction = position - target;
    final distance = direction.length;

    // Convert to spherical coordinates
    final theta = deltaAzimuth;
    final phi = deltaElevation;

    // Rotate around vertical axis
    final rotY = Matrix4.rotationY(theta);
    // Rotate around horizontal axis
    final right = up.cross(direction)..normalize();
    final rotH = Matrix4.identity()..rotate(right, phi);

    final newDirection = rotH.transform3(rotY.transform3(direction));
    newDirection.normalize();
    newDirection.scale(distance);

    return copyWith(position: target + newDirection);
  }

  /// Zoom the camera by adjusting distance to target.
  CameraModel zoom(double factor) {
    final direction = position - target;
    final newDistance = direction.length * factor;
    direction.normalize();
    direction.scale(newDistance.clamp(near * 2, far / 2));
    return copyWith(position: target + direction);
  }

  /// Pan the camera in the view plane.
  CameraModel pan(double deltaX, double deltaY) {
    final forward = (target - position)..normalize();
    final right = forward.cross(up)..normalize();
    final actualUp = right.cross(forward)..normalize();

    final offset = right * deltaX + actualUp * deltaY;
    return copyWith(
      position: position + offset,
      target: target + offset,
    );
  }
}
