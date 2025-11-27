import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/scene_providers.dart';
import '../state/camera_providers.dart';

/// Widget displaying the 3D CAD viewport.
///
/// Currently renders a placeholder. Will be replaced with flutter_gpu
/// pipeline once integrated.
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return Listener(
          onPointerSignal: _handlePointerSignal,
          child: GestureDetector(
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            onScaleEnd: _handleScaleEnd,
            onTapUp: _handleTap,
            child: Container(
              color: Colors.black,
              child: CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _ViewportPainter(
                  meshCount: meshes.length,
                  cameraPosition: camera.position.toString(),
                  selectedId: selectedId,
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

  void _handleTap(TapUpDetails details) {
    // TODO: Implement ray casting for entity selection
    // For now, just demonstrate selection capability
  }
}

class _ViewportPainter extends CustomPainter {
  final int meshCount;
  final String cameraPosition;
  final String? selectedId;

  _ViewportPainter({
    required this.meshCount,
    required this.cameraPosition,
    this.selectedId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid placeholder
    _drawGrid(canvas, size);

    // Draw info overlay
    _drawInfoOverlay(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0;

    const gridSize = 50.0;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw vertical lines
    for (var x = centerX % gridSize; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (var y = centerY % gridSize; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw axis indicators
    final axisPaint = Paint()
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // X axis (red)
    axisPaint.color = Colors.red;
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(centerX + 60, centerY),
      axisPaint,
    );

    // Y axis (green)
    axisPaint.color = Colors.green;
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(centerX, centerY - 60),
      axisPaint,
    );

    // Z axis (blue) - simulated depth
    axisPaint.color = Colors.blue;
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(centerX - 40, centerY + 40),
      axisPaint,
    );
  }

  void _drawInfoOverlay(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: Colors.white.withOpacity(0.8),
      fontSize: 14,
      fontFamily: 'monospace',
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: '3D Viewport (flutter_gpu placeholder)\n'
            'Meshes: $meshCount\n'
            'Camera: $cameraPosition\n'
            'Selected: ${selectedId ?? 'none'}',
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 20);

    textPainter.paint(canvas, const Offset(10, 10));

    // Draw instructions at bottom
    final instructionPainter = TextPainter(
      text: TextSpan(
        text: 'Drag: Orbit | Two-finger: Pan/Zoom | Scroll: Zoom',
        style: textStyle.copyWith(fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    instructionPainter.paint(
      canvas,
      Offset(10, size.height - instructionPainter.height - 10),
    );
  }

  @override
  bool shouldRepaint(covariant _ViewportPainter oldDelegate) {
    return oldDelegate.meshCount != meshCount ||
        oldDelegate.cameraPosition != cameraPosition ||
        oldDelegate.selectedId != selectedId;
  }
}
