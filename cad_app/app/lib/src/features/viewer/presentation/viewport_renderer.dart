import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../domain/mesh_model.dart';
import '../domain/camera_model.dart';

/// Rendering mode for the viewport.
enum RenderMode {
  wireframe,
  solid,
  solidWithEdges,
}

/// Software renderer for 3D meshes.
class ViewportRenderer {
  /// Render meshes to a canvas using software rendering.
  static void render({
    required Canvas canvas,
    required Size size,
    required List<Mesh> meshes,
    required CameraModel camera,
    required RenderMode mode,
    String? selectedId,
    String? hoveredId,
  }) {
    // Build view and projection matrices
    final viewMatrix = camera.viewMatrix;
    final aspect = size.width / size.height;
    final projectionMatrix = camera.projectionMatrix(aspect);
    final vpMatrix = projectionMatrix * viewMatrix;

    // Collect all triangles with their depths for sorting
    final triangles = <_RenderTriangle>[];

    for (final mesh in meshes) {
      final isSelected = mesh.id == selectedId;
      final isHovered = mesh.id == hoveredId;

      _collectTriangles(
        mesh: mesh,
        vpMatrix: vpMatrix,
        viewMatrix: viewMatrix,
        size: size,
        triangles: triangles,
        isSelected: isSelected,
        isHovered: isHovered,
        lightDir: Vector3(0.3, 0.5, 1.0).normalized(),
        cameraPos: camera.position,
      );
    }

    // Sort by depth (painter's algorithm - back to front)
    triangles.sort((a, b) => b.depth.compareTo(a.depth));

    // Render triangles
    for (final tri in triangles) {
      _drawTriangle(canvas, tri, mode);
    }

    // Draw coordinate axes
    _drawAxes(canvas, size, vpMatrix);
  }

  static void _collectTriangles({
    required Mesh mesh,
    required Matrix4 vpMatrix,
    required Matrix4 viewMatrix,
    required Size size,
    required List<_RenderTriangle> triangles,
    required bool isSelected,
    required bool isHovered,
    required Vector3 lightDir,
    required Vector3 cameraPos,
  }) {
    for (var i = 0; i < mesh.triangleCount; i++) {
      final i0 = mesh.indices[i * 3];
      final i1 = mesh.indices[i * 3 + 1];
      final i2 = mesh.indices[i * 3 + 2];

      // Get vertex positions
      final v0 = Vector3(
        mesh.positions[i0 * 3],
        mesh.positions[i0 * 3 + 1],
        mesh.positions[i0 * 3 + 2],
      );
      final v1 = Vector3(
        mesh.positions[i1 * 3],
        mesh.positions[i1 * 3 + 1],
        mesh.positions[i1 * 3 + 2],
      );
      final v2 = Vector3(
        mesh.positions[i2 * 3],
        mesh.positions[i2 * 3 + 1],
        mesh.positions[i2 * 3 + 2],
      );

      // Transform to clip space
      final p0 = _transformPoint(v0, vpMatrix, size);
      final p1 = _transformPoint(v1, vpMatrix, size);
      final p2 = _transformPoint(v2, vpMatrix, size);

      // Skip if behind camera
      if (p0 == null || p1 == null || p2 == null) continue;

      // Calculate face normal for lighting
      final edge1 = v1 - v0;
      final edge2 = v2 - v0;
      final normal = edge1.cross(edge2);
      if (normal.length < 0.0001) continue; // Degenerate triangle
      normal.normalize();

      // Calculate center of triangle
      final center = (v0 + v1 + v2) / 3.0;

      // View direction from center to camera
      final viewDir = (cameraPos - center)..normalize();

      // Back-face culling - skip if facing away from camera
      if (normal.dot(viewDir) < 0) continue;

      // Calculate lighting
      final ndotl = math.max(0.0, normal.dot(lightDir));
      const ambient = 0.3;
      final lighting = (ambient + ndotl * 0.7).clamp(0.0, 1.0);

      // Determine color
      Color baseColor;
      if (isSelected) {
        baseColor = Colors.blue;
      } else if (isHovered) {
        baseColor = Colors.lightBlue;
      } else {
        baseColor = Colors.grey.shade400;
      }

      final shadedColor = Color.fromRGBO(
        (baseColor.red * lighting).round(),
        (baseColor.green * lighting).round(),
        (baseColor.blue * lighting).round(),
        1.0,
      );

      // Average depth for sorting (in view space)
      final depth = (p0.z + p1.z + p2.z) / 3;

      triangles.add(_RenderTriangle(
        p0: Offset(p0.x, p0.y),
        p1: Offset(p1.x, p1.y),
        p2: Offset(p2.x, p2.y),
        depth: depth,
        color: shadedColor,
        edgeColor: isSelected ? Colors.blue.shade900 : Colors.black54,
      ));
    }
  }

  static Vector3? _transformPoint(Vector3 point, Matrix4 mvp, Size size) {
    // Transform point by MVP matrix
    final v4 = Vector4(point.x, point.y, point.z, 1.0);
    mvp.transform(v4);

    // Perspective divide
    if (v4.w <= 0) return null; // Behind camera

    final ndc = Vector3(
      v4.x / v4.w,
      v4.y / v4.w,
      v4.z / v4.w,
    );

    // Clip to NDC bounds
    if (ndc.x < -1.5 || ndc.x > 1.5 || ndc.y < -1.5 || ndc.y > 1.5) {
      // Allow some margin for triangles partially visible
    }

    // Convert to screen coordinates
    return Vector3(
      (ndc.x + 1) * size.width / 2,
      (1 - ndc.y) * size.height / 2, // Flip Y
      ndc.z,
    );
  }

  static void _drawTriangle(Canvas canvas, _RenderTriangle tri, RenderMode mode) {
    final path = Path()
      ..moveTo(tri.p0.dx, tri.p0.dy)
      ..lineTo(tri.p1.dx, tri.p1.dy)
      ..lineTo(tri.p2.dx, tri.p2.dy)
      ..close();

    if (mode == RenderMode.solid || mode == RenderMode.solidWithEdges) {
      canvas.drawPath(
        path,
        Paint()
          ..color = tri.color
          ..style = PaintingStyle.fill,
      );
    }

    if (mode == RenderMode.wireframe || mode == RenderMode.solidWithEdges) {
      canvas.drawPath(
        path,
        Paint()
          ..color = tri.edgeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  static void _drawAxes(Canvas canvas, Size size, Matrix4 vpMatrix) {
    const axisLength = 1.0;
    final origin = Vector3.zero();
    final xEnd = Vector3(axisLength, 0, 0);
    final yEnd = Vector3(0, axisLength, 0);
    final zEnd = Vector3(0, 0, axisLength);

    final originScreen = _transformPoint(origin, vpMatrix, size);
    final xScreen = _transformPoint(xEnd, vpMatrix, size);
    final yScreen = _transformPoint(yEnd, vpMatrix, size);
    final zScreen = _transformPoint(zEnd, vpMatrix, size);

    if (originScreen == null) return;

    final axisPaint = Paint()
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // X axis (red)
    if (xScreen != null) {
      axisPaint.color = Colors.red;
      canvas.drawLine(
        Offset(originScreen.x, originScreen.y),
        Offset(xScreen.x, xScreen.y),
        axisPaint,
      );
      _drawAxisLabel(canvas, xScreen, 'X', Colors.red);
    }

    // Y axis (green)
    if (yScreen != null) {
      axisPaint.color = Colors.green;
      canvas.drawLine(
        Offset(originScreen.x, originScreen.y),
        Offset(yScreen.x, yScreen.y),
        axisPaint,
      );
      _drawAxisLabel(canvas, yScreen, 'Y', Colors.green);
    }

    // Z axis (blue)
    if (zScreen != null) {
      axisPaint.color = Colors.blue;
      canvas.drawLine(
        Offset(originScreen.x, originScreen.y),
        Offset(zScreen.x, zScreen.y),
        axisPaint,
      );
      _drawAxisLabel(canvas, zScreen, 'Z', Colors.blue);
    }
  }

  static void _drawAxisLabel(Canvas canvas, Vector3 pos, String label, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(pos.x + 5, pos.y - 5));
  }

  /// Draw a ground grid for reference.
  static void drawGroundGrid(
    Canvas canvas,
    Size size,
    Matrix4 vpMatrix, {
    double gridSize = 10.0,
    int divisions = 10,
  }) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.0;

    final halfSize = gridSize / 2;
    final step = gridSize / divisions;

    for (var i = 0; i <= divisions; i++) {
      final pos = -halfSize + i * step;

      // Lines parallel to X axis
      final xStart = _transformPoint(Vector3(-halfSize, 0, pos), vpMatrix, size);
      final xEnd = _transformPoint(Vector3(halfSize, 0, pos), vpMatrix, size);
      if (xStart != null && xEnd != null) {
        canvas.drawLine(
          Offset(xStart.x, xStart.y),
          Offset(xEnd.x, xEnd.y),
          gridPaint,
        );
      }

      // Lines parallel to Z axis
      final zStart = _transformPoint(Vector3(pos, 0, -halfSize), vpMatrix, size);
      final zEnd = _transformPoint(Vector3(pos, 0, halfSize), vpMatrix, size);
      if (zStart != null && zEnd != null) {
        canvas.drawLine(
          Offset(zStart.x, zStart.y),
          Offset(zEnd.x, zEnd.y),
          gridPaint,
        );
      }
    }
  }
}

class _RenderTriangle {
  final Offset p0;
  final Offset p1;
  final Offset p2;
  final double depth;
  final Color color;
  final Color edgeColor;

  _RenderTriangle({
    required this.p0,
    required this.p1,
    required this.p2,
    required this.depth,
    required this.color,
    required this.edgeColor,
  });
}
