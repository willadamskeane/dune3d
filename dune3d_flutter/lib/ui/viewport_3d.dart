import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;
import 'theme.dart';
import '../core/model_3d.dart';
import '../core/geometry.dart';

/// 3D Viewport for viewing and interacting with 3D models
class Viewport3D extends StatefulWidget {
  final List<Mesh3D> meshes;
  final List<Operation3D> operations;
  final Function(int)? onOperationSelected;
  final int? selectedOperationIndex;
  final VoidCallback? onRequestExtrude;

  const Viewport3D({
    super.key,
    required this.meshes,
    required this.operations,
    this.onOperationSelected,
    this.selectedOperationIndex,
    this.onRequestExtrude,
  });

  @override
  State<Viewport3D> createState() => _Viewport3DState();
}

class _Viewport3DState extends State<Viewport3D> with SingleTickerProviderStateMixin {
  late Camera3D _camera;
  Offset? _lastPanPosition;
  double _lastScale = 1.0;
  bool _isPanning = false;
  bool _isOrbiting = false;

  // View cube state
  int? _hoveredCubeFace;

  // Animation for smooth camera transitions
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _camera = Camera3D();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Frame to fit content if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _frameToFitContent();
    });
  }

  @override
  void didUpdateWidget(Viewport3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.meshes.length != oldWidget.meshes.length) {
      _frameToFitContent();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _frameToFitContent() {
    if (widget.meshes.isEmpty) {
      _camera.reset();
      return;
    }

    Vec3 minBounds = const Vec3(double.infinity, double.infinity, double.infinity);
    Vec3 maxBounds = const Vec3(double.negativeInfinity, double.negativeInfinity, double.negativeInfinity);

    for (final mesh in widget.meshes) {
      final (min, max) = mesh.bounds;
      minBounds = Vec3(
        math.min(minBounds.x, min.x),
        math.min(minBounds.y, min.y),
        math.min(minBounds.z, min.z),
      );
      maxBounds = Vec3(
        math.max(maxBounds.x, max.x),
        math.max(maxBounds.y, max.y),
        math.max(maxBounds.z, max.z),
      );
    }

    _camera.frameToFit(minBounds, maxBounds);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Dune3DTheme.background,
      child: Stack(
        children: [
          // Main 3D view
          Positioned.fill(
            child: Listener(
              onPointerSignal: _handlePointerSignal,
              child: GestureDetector(
                onScaleStart: _handleScaleStart,
                onScaleUpdate: _handleScaleUpdate,
                onScaleEnd: _handleScaleEnd,
                onDoubleTap: _frameToFitContent,
                child: CustomPaint(
                  painter: _Viewport3DPainter(
                    camera: _camera,
                    meshes: widget.meshes,
                  ),
                  child: Container(),
                ),
              ),
            ),
          ),

          // View cube (top right)
          Positioned(
            top: Dune3DTheme.spacingL,
            right: Dune3DTheme.spacingL,
            child: _buildViewCube(),
          ),

          // Empty state
          if (widget.meshes.isEmpty) _buildEmptyState(),

          // View controls (bottom right)
          Positioned(
            bottom: Dune3DTheme.spacingL,
            right: Dune3DTheme.spacingL,
            child: _buildViewControls(),
          ),

          // Coordinate system indicator (bottom left)
          Positioned(
            bottom: Dune3DTheme.spacingL,
            left: Dune3DTheme.spacingL,
            child: _buildAxisIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewCube() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Dune3DTheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(Dune3DTheme.radiusMedium),
        border: Border.all(color: Dune3DTheme.border),
        boxShadow: Dune3DTheme.elevation1,
      ),
      child: GestureDetector(
        onTapDown: (details) {
          // Determine which face was tapped and orient view
          final localPos = details.localPosition;
          _handleViewCubeTap(localPos);
        },
        child: CustomPaint(
          painter: _ViewCubePainter(
            camera: _camera,
            hoveredFace: _hoveredCubeFace,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(Dune3DTheme.spacingXL),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: Dune3DDecorations.floatingPanel(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Dune3DTheme.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.view_in_ar,
                size: 40,
                color: Dune3DTheme.accent,
              ),
            ),
            const SizedBox(height: Dune3DTheme.spacingL),
            Text(
              '3D Modeling',
              style: Dune3DTheme.heading2,
            ),
            const SizedBox(height: Dune3DTheme.spacingS),
            Text(
              'Create a sketch and use Extrude to generate 3D geometry. '
              'Draw closed shapes like rectangles or circles, then tap Extrude.',
              style: Dune3DTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dune3DTheme.spacingL),
            if (widget.onRequestExtrude != null)
              ElevatedButton.icon(
                onPressed: widget.onRequestExtrude,
                icon: const Icon(Icons.open_in_full, size: 18),
                label: const Text('Extrude Sketch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Dune3DTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dune3DTheme.spacingL,
                    vertical: Dune3DTheme.spacingM,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewControls() {
    return Container(
      decoration: Dune3DDecorations.floatingPanel(),
      padding: const EdgeInsets.all(Dune3DTheme.spacingS),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewControlButton(
            icon: Icons.zoom_in,
            onTap: () {
              _camera.zoom(1.2);
              setState(() {});
            },
          ),
          const SizedBox(height: Dune3DTheme.spacingXS),
          _ViewControlButton(
            icon: Icons.zoom_out,
            onTap: () {
              _camera.zoom(0.8);
              setState(() {});
            },
          ),
          const SizedBox(height: Dune3DTheme.spacingS),
          Container(height: 1, width: 28, color: Dune3DTheme.border),
          const SizedBox(height: Dune3DTheme.spacingS),
          _ViewControlButton(
            icon: Icons.fit_screen,
            tooltip: 'Fit to view',
            onTap: _frameToFitContent,
          ),
          const SizedBox(height: Dune3DTheme.spacingXS),
          _ViewControlButton(
            icon: _camera.isOrthographic ? Icons.grid_on : Icons.grid_off,
            tooltip: _camera.isOrthographic ? 'Perspective' : 'Orthographic',
            onTap: () {
              setState(() {
                _camera.isOrthographic = !_camera.isOrthographic;
              });
            },
          ),
          const SizedBox(height: Dune3DTheme.spacingXS),
          _ViewControlButton(
            icon: Icons.home,
            tooltip: 'Reset view',
            onTap: () {
              _camera.reset();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAxisIndicator() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Dune3DTheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(Dune3DTheme.radiusMedium),
        border: Border.all(color: Dune3DTheme.border),
      ),
      child: CustomPaint(
        painter: _AxisIndicatorPainter(camera: _camera),
      ),
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final zoomFactor = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
      _camera.zoom(zoomFactor);
      setState(() {});
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _lastPanPosition = details.localFocalPoint;
    _lastScale = 1.0;

    // Determine if orbiting or panning based on pointer count
    _isOrbiting = details.pointerCount == 1;
    _isPanning = details.pointerCount == 2;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final delta = details.localFocalPoint - (_lastPanPosition ?? details.localFocalPoint);

    if (details.pointerCount >= 2) {
      // Pinch zoom
      if (details.scale != 1.0) {
        final scaleChange = details.scale / _lastScale;
        _camera.zoom(scaleChange);
        _lastScale = details.scale;
      }

      // Two-finger pan
      _camera.pan(delta.dx, delta.dy);
    } else {
      // Single finger orbit
      _camera.orbit(delta.dx, delta.dy);
    }

    _lastPanPosition = details.localFocalPoint;
    setState(() {});
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _lastPanPosition = null;
    _isOrbiting = false;
    _isPanning = false;
  }

  void _handleViewCubeTap(Offset position) {
    // Simple view cube navigation
    final center = const Offset(40, 40);
    final diff = position - center;

    if (diff.distance < 15) {
      // Center - top view
      _setViewDirection(const Vec3(0, 0, 1));
    } else if (diff.dx.abs() > diff.dy.abs()) {
      if (diff.dx > 0) {
        _setViewDirection(const Vec3(1, 0, 0)); // Right
      } else {
        _setViewDirection(const Vec3(-1, 0, 0)); // Left
      }
    } else {
      if (diff.dy > 0) {
        _setViewDirection(const Vec3(0, 1, 0)); // Front
      } else {
        _setViewDirection(const Vec3(0, -1, 0)); // Back
      }
    }
  }

  void _setViewDirection(Vec3 direction) {
    final distance = (_camera.position - _camera.target).length;
    _camera.position = _camera.target + direction * distance;
    setState(() {});
  }
}

class _ViewControlButton extends StatefulWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onTap;

  const _ViewControlButton({
    required this.icon,
    this.tooltip,
    required this.onTap,
  });

  @override
  State<_ViewControlButton> createState() => _ViewControlButtonState();
}

class _ViewControlButtonState extends State<_ViewControlButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Dune3DAnimations.fast,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _isHovered ? Dune3DTheme.surfaceLight : Colors.transparent,
            borderRadius: BorderRadius.circular(Dune3DTheme.radiusSmall),
          ),
          child: Icon(
            widget.icon,
            size: 20,
            color: Dune3DTheme.textPrimary,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

/// Custom painter for 3D viewport
class _Viewport3DPainter extends CustomPainter {
  final Camera3D camera;
  final List<Mesh3D> meshes;

  _Viewport3DPainter({
    required this.camera,
    required this.meshes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid
    _drawGrid(canvas, size);

    // Draw meshes
    for (final mesh in meshes) {
      _drawMesh(canvas, size, mesh);
    }

    // Draw origin
    _drawOrigin(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Dune3DTheme.gridMinor
      ..strokeWidth = 1;

    const gridSize = 200.0;
    const spacing = 20.0;

    for (double i = -gridSize; i <= gridSize; i += spacing) {
      // Lines along X
      final start = camera.project(Vec3(i, -gridSize, 0), size.width, size.height);
      final end = camera.project(Vec3(i, gridSize, 0), size.width, size.height);

      if (start.x > -1000 && end.x > -1000) {
        canvas.drawLine(
          Offset(start.x, start.y),
          Offset(end.x, end.y),
          paint,
        );
      }

      // Lines along Y
      final startY = camera.project(Vec3(-gridSize, i, 0), size.width, size.height);
      final endY = camera.project(Vec3(gridSize, i, 0), size.width, size.height);

      if (startY.x > -1000 && endY.x > -1000) {
        canvas.drawLine(
          Offset(startY.x, startY.y),
          Offset(endY.x, endY.y),
          paint,
        );
      }
    }
  }

  void _drawMesh(Canvas canvas, Size size, Mesh3D mesh) {
    if (mesh.vertices.isEmpty) return;

    // Project all vertices
    final projected = mesh.vertices
        .map((v) => camera.project(v, size.width, size.height))
        .toList();

    // Draw faces with shading
    final facePaint = Paint()
      ..style = PaintingStyle.fill;

    final edgePaint = Paint()
      ..color = Dune3DTheme.sketch
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Sort faces by depth (painter's algorithm)
    final faceDepths = <int, double>{};
    for (int i = 0; i < mesh.faces.length; i++) {
      final face = mesh.faces[i];
      double avgZ = 0;
      for (final idx in face.vertexIndices) {
        avgZ += mesh.vertices[idx].z;
      }
      faceDepths[i] = avgZ / face.vertexIndices.length;
    }

    final sortedFaceIndices = faceDepths.keys.toList()
      ..sort((a, b) => faceDepths[a]!.compareTo(faceDepths[b]!));

    // Draw faces
    for (final faceIdx in sortedFaceIndices) {
      final face = mesh.faces[faceIdx];
      final path = Path();

      bool allVisible = true;
      for (int i = 0; i < face.vertexIndices.length; i++) {
        final p = projected[face.vertexIndices[i]];
        if (p.x < -1000) {
          allVisible = false;
          break;
        }
        if (i == 0) {
          path.moveTo(p.x, p.y);
        } else {
          path.lineTo(p.x, p.y);
        }
      }
      path.close();

      if (allVisible) {
        // Calculate face normal for shading
        final v0 = mesh.vertices[face.vertexIndices[0]];
        final v1 = mesh.vertices[face.vertexIndices[1]];
        final v2 = mesh.vertices[face.vertexIndices[2]];
        final normal = (v1 - v0).cross(v2 - v0).normalized;
        final lightDir = const Vec3(0.5, 0.5, 1).normalized;
        final brightness = (normal.dot(lightDir) + 1) / 2;

        facePaint.color = Color.lerp(
          Dune3DTheme.surfaceLight,
          Dune3DTheme.accent.withOpacity(0.7),
          brightness * 0.8,
        )!;

        canvas.drawPath(path, facePaint);
        canvas.drawPath(path, edgePaint..strokeWidth = 0.5);
      }
    }

    // Draw hard edges
    edgePaint
      ..strokeWidth = 1.5
      ..color = Dune3DTheme.sketch;

    for (final edge in mesh.edges) {
      if (!edge.isHard) continue;

      final p1 = projected[edge.startIndex];
      final p2 = projected[edge.endIndex];

      if (p1.x > -1000 && p2.x > -1000) {
        canvas.drawLine(
          Offset(p1.x, p1.y),
          Offset(p2.x, p2.y),
          edgePaint,
        );
      }
    }
  }

  void _drawOrigin(Canvas canvas, Size size) {
    final origin = camera.project(Vec3.zero, size.width, size.height);
    if (origin.x < -500) return;

    const axisLength = 30.0;
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // X axis (red)
    final xEnd = camera.project(const Vec3(axisLength, 0, 0), size.width, size.height);
    paint.color = Dune3DTheme.axisX;
    canvas.drawLine(
      Offset(origin.x, origin.y),
      Offset(xEnd.x, xEnd.y),
      paint,
    );

    // Y axis (green)
    final yEnd = camera.project(const Vec3(0, axisLength, 0), size.width, size.height);
    paint.color = Dune3DTheme.axisY;
    canvas.drawLine(
      Offset(origin.x, origin.y),
      Offset(yEnd.x, yEnd.y),
      paint,
    );

    // Z axis (blue)
    final zEnd = camera.project(const Vec3(0, 0, axisLength), size.width, size.height);
    paint.color = Dune3DTheme.axisZ;
    canvas.drawLine(
      Offset(origin.x, origin.y),
      Offset(zEnd.x, zEnd.y),
      paint,
    );
  }

  @override
  bool shouldRepaint(_Viewport3DPainter oldDelegate) => true;
}

/// View cube painter
class _ViewCubePainter extends CustomPainter {
  final Camera3D camera;
  final int? hoveredFace;

  _ViewCubePainter({required this.camera, this.hoveredFace});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const cubeSize = 25.0;

    // Simple 3D cube representation
    final forward = (camera.target - camera.position).normalized;
    final right = forward.cross(camera.up).normalized;
    final up = right.cross(forward).normalized;

    // Draw cube faces with labels
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw a simple cube icon
    final cubeVertices = [
      Vec3(-1, -1, -1), Vec3(1, -1, -1), Vec3(1, 1, -1), Vec3(-1, 1, -1),
      Vec3(-1, -1, 1), Vec3(1, -1, 1), Vec3(1, 1, 1), Vec3(-1, 1, 1),
    ];

    final projected = cubeVertices.map((v) {
      final rotated = Vec3(
        v.x * right.x + v.y * up.x + v.z * forward.x,
        v.x * right.y + v.y * up.y + v.z * forward.y,
        v.x * right.z + v.y * up.z + v.z * forward.z,
      );
      return Offset(
        center.dx + rotated.x * cubeSize,
        center.dy - rotated.y * cubeSize,
      );
    }).toList();

    // Draw faces
    paint.color = Dune3DTheme.surfaceLight;
    final faces = [
      [0, 1, 2, 3], // Front
      [4, 5, 6, 7], // Back
      [0, 1, 5, 4], // Bottom
      [2, 3, 7, 6], // Top
      [0, 3, 7, 4], // Left
      [1, 2, 6, 5], // Right
    ];

    for (final face in faces) {
      final path = Path()
        ..moveTo(projected[face[0]].dx, projected[face[0]].dy)
        ..lineTo(projected[face[1]].dx, projected[face[1]].dy)
        ..lineTo(projected[face[2]].dx, projected[face[2]].dy)
        ..lineTo(projected[face[3]].dx, projected[face[3]].dy)
        ..close();
      canvas.drawPath(path, paint);
    }

    // Draw edges
    paint
      ..style = PaintingStyle.stroke
      ..color = Dune3DTheme.border
      ..strokeWidth = 1;

    final edges = [
      [0, 1], [1, 2], [2, 3], [3, 0],
      [4, 5], [5, 6], [6, 7], [7, 4],
      [0, 4], [1, 5], [2, 6], [3, 7],
    ];

    for (final edge in edges) {
      canvas.drawLine(projected[edge[0]], projected[edge[1]], paint);
    }
  }

  @override
  bool shouldRepaint(_ViewCubePainter oldDelegate) =>
      oldDelegate.hoveredFace != hoveredFace;
}

/// Axis indicator painter
class _AxisIndicatorPainter extends CustomPainter {
  final Camera3D camera;

  _AxisIndicatorPainter({required this.camera});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const axisLength = 20.0;

    final forward = (camera.target - camera.position).normalized;
    final right = forward.cross(camera.up).normalized;
    final up = right.cross(forward).normalized;

    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Project axes
    final xDir = Vec3(1, 0, 0);
    final yDir = Vec3(0, 1, 0);
    final zDir = Vec3(0, 0, 1);

    final xProj = Offset(
      xDir.x * right.x + xDir.y * up.x + xDir.z * forward.x,
      -(xDir.x * right.y + xDir.y * up.y + xDir.z * forward.y),
    );
    final yProj = Offset(
      yDir.x * right.x + yDir.y * up.x + yDir.z * forward.x,
      -(yDir.x * right.y + yDir.y * up.y + yDir.z * forward.y),
    );
    final zProj = Offset(
      zDir.x * right.x + zDir.y * up.x + zDir.z * forward.x,
      -(zDir.x * right.y + zDir.y * up.y + zDir.z * forward.y),
    );

    // Draw X (red)
    paint.color = Dune3DTheme.axisX;
    canvas.drawLine(center, center + xProj * axisLength, paint);

    // Draw Y (green)
    paint.color = Dune3DTheme.axisY;
    canvas.drawLine(center, center + yProj * axisLength, paint);

    // Draw Z (blue)
    paint.color = Dune3DTheme.axisZ;
    canvas.drawLine(center, center + zProj * axisLength, paint);

    // Draw labels
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    _drawLabel(canvas, 'X', center + xProj * (axisLength + 8), textStyle);
    _drawLabel(canvas, 'Y', center + yProj * (axisLength + 8), textStyle);
    _drawLabel(canvas, 'Z', center + zProj * (axisLength + 8), textStyle);
  }

  void _drawLabel(Canvas canvas, String text, Offset position, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_AxisIndicatorPainter oldDelegate) => true;
}
