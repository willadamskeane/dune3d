import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/scene_providers.dart';
import '../state/camera_providers.dart';
import '../domain/camera_model.dart';
import '../domain/mesh_model.dart';
import 'viewport_renderer.dart';

/// Provider for the current render mode.
final renderModeProvider = StateProvider<RenderMode>((ref) {
  return RenderMode.solidWithEdges;
});

/// Provider for the hovered entity ID.
final hoveredEntityIdProvider = StateProvider<String?>((ref) => null);

/// Widget displaying the 3D CAD viewport.
class CadViewportWidget extends ConsumerStatefulWidget {
  const CadViewportWidget({super.key});

  @override
  ConsumerState<CadViewportWidget> createState() => _CadViewportWidgetState();
}

class _CadViewportWidgetState extends ConsumerState<CadViewportWidget> {
  Offset? _lastPanPosition;
  static const double _orbitSensitivity = 0.01;
  static const double _panSensitivity = 0.02;
  static const double _zoomSensitivity = 0.001;

  @override
  Widget build(BuildContext context) {
    final meshes = ref.watch(meshListProvider);
    final camera = ref.watch(cameraProvider);
    final selectedId = ref.watch(selectedEntityIdProvider);
    final hoveredId = ref.watch(hoveredEntityIdProvider);
    final renderMode = ref.watch(renderModeProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Listener(
          onPointerSignal: _handlePointerSignal,
          onPointerHover: (event) => _handleHover(event, meshes, camera, constraints),
          child: GestureDetector(
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            onScaleEnd: _handleScaleEnd,
            onTapUp: (details) => _handleTap(details, meshes, camera, constraints),
            child: Container(
              color: const Color(0xFF1A1A2E),
              child: CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _ViewportPainter(
                  meshes: meshes,
                  camera: camera,
                  selectedId: selectedId,
                  hoveredId: hoveredId,
                  renderMode: renderMode,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final zoomFactor = 1.0 + event.scrollDelta.dy * _zoomSensitivity;
      ref.read(cameraProvider.notifier).zoom(zoomFactor);
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _lastPanPosition = details.focalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_lastPanPosition == null) return;

    final delta = details.focalPoint - _lastPanPosition!;
    _lastPanPosition = details.focalPoint;

    if (details.pointerCount == 1) {
      // Single finger: orbit
      ref.read(cameraProvider.notifier).orbit(
            delta.dx * _orbitSensitivity,
            -delta.dy * _orbitSensitivity,
          );
    } else if (details.pointerCount == 2) {
      // Two fingers: pan + zoom
      ref.read(cameraProvider.notifier).pan(
            -delta.dx * _panSensitivity,
            delta.dy * _panSensitivity,
          );

      if (details.scale != 1.0) {
        ref.read(cameraProvider.notifier).zoom(1.0 / details.scale);
      }
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _lastPanPosition = null;
  }

  void _handleHover(
    PointerHoverEvent event,
    List<Mesh> meshes,
    CameraModel camera,
    BoxConstraints constraints,
  ) {
    // Simple hover detection using ray casting (placeholder)
    // In a real implementation, this would cast a ray and find intersections
    ref.read(hoveredEntityIdProvider.notifier).state = null;
  }

  void _handleTap(
    TapUpDetails details,
    List<Mesh> meshes,
    CameraModel camera,
    BoxConstraints constraints,
  ) {
    // Simple selection using ray casting (placeholder)
    // In a real implementation, this would cast a ray and find the nearest intersection
    final size = Size(constraints.maxWidth, constraints.maxHeight);
    final tapPos = details.localPosition;

    // For now, cycle through meshes for demo purposes
    final currentSelected = ref.read(selectedEntityIdProvider);
    if (meshes.isEmpty) {
      ref.read(selectedEntityIdProvider.notifier).state = null;
      return;
    }

    final currentIndex = meshes.indexWhere((m) => m.id == currentSelected);
    final nextIndex = (currentIndex + 1) % meshes.length;
    ref.read(selectedEntityIdProvider.notifier).state = meshes[nextIndex].id;
  }
}

class _ViewportPainter extends CustomPainter {
  final List<Mesh> meshes;
  final CameraModel camera;
  final String? selectedId;
  final String? hoveredId;
  final RenderMode renderMode;

  _ViewportPainter({
    required this.meshes,
    required this.camera,
    this.selectedId,
    this.hoveredId,
    required this.renderMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background gradient
    _drawBackground(canvas, size);

    // Draw ground grid
    final aspect = size.width / size.height;
    final vpMatrix = camera.projectionMatrix(aspect) * camera.viewMatrix;
    ViewportRenderer.drawGroundGrid(canvas, size, vpMatrix);

    // Render all meshes
    ViewportRenderer.render(
      canvas: canvas,
      size: size,
      meshes: meshes,
      camera: camera,
      mode: renderMode,
      selectedId: selectedId,
      hoveredId: hoveredId,
    );

    // Draw info overlay
    _drawInfoOverlay(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF2D2D44),
        const Color(0xFF1A1A2E),
      ],
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _drawInfoOverlay(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: Colors.white.withOpacity(0.8),
      fontSize: 12,
      fontFamily: 'monospace',
    );

    // Camera info
    final cameraInfo = TextPainter(
      text: TextSpan(
        text: 'Meshes: ${meshes.length}\n'
            'Selected: ${selectedId ?? 'none'}\n'
            'Mode: ${renderMode.name}',
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 20);

    cameraInfo.paint(canvas, const Offset(10, 10));

    // Instructions at bottom
    final instructions = TextPainter(
      text: TextSpan(
        text: 'Drag: Orbit | Two-finger: Pan/Zoom | Scroll: Zoom | Tap: Select',
        style: textStyle.copyWith(fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    instructions.paint(
      canvas,
      Offset(10, size.height - instructions.height - 10),
    );
  }

  @override
  bool shouldRepaint(covariant _ViewportPainter oldDelegate) {
    return oldDelegate.meshes != meshes ||
        oldDelegate.camera != camera ||
        oldDelegate.selectedId != selectedId ||
        oldDelegate.hoveredId != hoveredId ||
        oldDelegate.renderMode != renderMode;
  }
}
