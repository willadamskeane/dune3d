import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/camera_model.dart';

/// Provider for the current camera state.
final cameraProvider = StateNotifierProvider<CameraNotifier, CameraModel>((ref) {
  return CameraNotifier();
});

/// Notifier for camera state management.
class CameraNotifier extends StateNotifier<CameraModel> {
  CameraNotifier() : super(CameraModel.defaultCamera());

  /// Orbit the camera by delta angles.
  void orbit(double deltaAzimuth, double deltaElevation) {
    state = state.orbit(deltaAzimuth, deltaElevation);
  }

  /// Zoom the camera by a factor.
  void zoom(double factor) {
    state = state.zoom(factor);
  }

  /// Pan the camera in view space.
  void pan(double deltaX, double deltaY) {
    state = state.pan(deltaX, deltaY);
  }

  /// Reset to default camera position.
  void reset() {
    state = CameraModel.defaultCamera();
  }

  /// Set camera to look at a specific target.
  void lookAt(double x, double y, double z) {
    state = state.copyWith(
      target: state.target..setValues(x, y, z),
    );
  }
}
