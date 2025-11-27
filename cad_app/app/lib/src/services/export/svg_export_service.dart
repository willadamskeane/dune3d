import 'dart:io';
import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../../features/sketch/domain/sketch_entities.dart';
import '../../features/sketch/state/sketch_providers.dart';

/// Service for exporting 2D sketches to SVG format.
class SvgExportService {
  SvgExportService._();

  static final SvgExportService instance = SvgExportService._();

  /// Export a sketch state to SVG.
  Future<void> exportSketch(
    SketchState sketch,
    String filePath, {
    double strokeWidth = 1.0,
    String strokeColor = '#000000',
    double padding = 10.0,
    bool includePoints = true,
  }) async {
    final bounds = _calculateBounds(sketch);
    if (bounds == null) {
      throw ArgumentError('Sketch is empty');
    }

    final width = bounds.width + padding * 2;
    final height = bounds.height + padding * 2;
    final offsetX = -bounds.minX + padding;
    final offsetY = -bounds.minY + padding;

    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
        '<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">');
    buffer.writeln('  <title>CAD Sketch Export</title>');
    buffer.writeln('  <g transform="translate($offsetX, $offsetY)">');

    // Draw segments
    for (final segment in sketch.segments) {
      final startPoint = sketch.getPoint(segment.startPointId);
      final endPoint = sketch.getPoint(segment.endPointId);

      if (startPoint != null && endPoint != null) {
        buffer.writeln(
            '    <line x1="${startPoint.position.x}" y1="${startPoint.position.y}" '
            'x2="${endPoint.position.x}" y2="${endPoint.position.y}" '
            'stroke="$strokeColor" stroke-width="$strokeWidth" stroke-linecap="round"/>');
      }
    }

    // Draw circles
    for (final circle in sketch.circles) {
      final center = sketch.getPoint(circle.centerPointId);
      final radiusPoint = sketch.getPoint(circle.radiusPointId);

      if (center != null && radiusPoint != null) {
        final radius = (radiusPoint.position - center.position).length;
        buffer.writeln(
            '    <circle cx="${center.position.x}" cy="${center.position.y}" r="$radius" '
            'fill="none" stroke="$strokeColor" stroke-width="$strokeWidth"/>');
      }
    }

    // Draw arcs
    for (final arc in sketch.arcs) {
      final center = sketch.getPoint(arc.centerPointId);
      final startPoint = sketch.getPoint(arc.startPointId);
      final endPoint = sketch.getPoint(arc.endPointId);

      if (center != null && startPoint != null && endPoint != null) {
        final radius = (startPoint.position - center.position).length;
        final startAngle = math.atan2(
          startPoint.position.y - center.position.y,
          startPoint.position.x - center.position.x,
        );
        final endAngle = math.atan2(
          endPoint.position.y - center.position.y,
          endPoint.position.x - center.position.x,
        );

        // Calculate arc sweep
        var sweep = endAngle - startAngle;
        if (arc.clockwise && sweep > 0) sweep -= 2 * math.pi;
        if (!arc.clockwise && sweep < 0) sweep += 2 * math.pi;

        final largeArc = sweep.abs() > math.pi ? 1 : 0;
        final sweepFlag = arc.clockwise ? 0 : 1;

        buffer.writeln(
            '    <path d="M ${startPoint.position.x} ${startPoint.position.y} '
            'A $radius $radius 0 $largeArc $sweepFlag ${endPoint.position.x} ${endPoint.position.y}" '
            'fill="none" stroke="$strokeColor" stroke-width="$strokeWidth"/>');
      }
    }

    // Draw points
    if (includePoints) {
      for (final point in sketch.points) {
        final color = point.isFixed ? '#FF5722' : '#2196F3';
        buffer.writeln(
            '    <circle cx="${point.position.x}" cy="${point.position.y}" r="3" '
            'fill="$color"/>');
      }
    }

    buffer.writeln('  </g>');
    buffer.writeln('</svg>');

    final file = File(filePath);
    await file.writeAsString(buffer.toString());
  }

  /// Export sketch to DXF format (simplified).
  Future<void> exportDxf(
    SketchState sketch,
    String filePath,
  ) async {
    final buffer = StringBuffer();

    // DXF Header
    buffer.writeln('0');
    buffer.writeln('SECTION');
    buffer.writeln('2');
    buffer.writeln('HEADER');
    buffer.writeln('0');
    buffer.writeln('ENDSEC');

    // Entities section
    buffer.writeln('0');
    buffer.writeln('SECTION');
    buffer.writeln('2');
    buffer.writeln('ENTITIES');

    // Export segments as LINE entities
    for (final segment in sketch.segments) {
      final startPoint = sketch.getPoint(segment.startPointId);
      final endPoint = sketch.getPoint(segment.endPointId);

      if (startPoint != null && endPoint != null) {
        buffer.writeln('0');
        buffer.writeln('LINE');
        buffer.writeln('8');
        buffer.writeln('0'); // Layer
        buffer.writeln('10');
        buffer.writeln('${startPoint.position.x}');
        buffer.writeln('20');
        buffer.writeln('${startPoint.position.y}');
        buffer.writeln('30');
        buffer.writeln('0');
        buffer.writeln('11');
        buffer.writeln('${endPoint.position.x}');
        buffer.writeln('21');
        buffer.writeln('${endPoint.position.y}');
        buffer.writeln('31');
        buffer.writeln('0');
      }
    }

    // Export circles as CIRCLE entities
    for (final circle in sketch.circles) {
      final center = sketch.getPoint(circle.centerPointId);
      final radiusPoint = sketch.getPoint(circle.radiusPointId);

      if (center != null && radiusPoint != null) {
        final radius = (radiusPoint.position - center.position).length;
        buffer.writeln('0');
        buffer.writeln('CIRCLE');
        buffer.writeln('8');
        buffer.writeln('0'); // Layer
        buffer.writeln('10');
        buffer.writeln('${center.position.x}');
        buffer.writeln('20');
        buffer.writeln('${center.position.y}');
        buffer.writeln('30');
        buffer.writeln('0');
        buffer.writeln('40');
        buffer.writeln('$radius');
      }
    }

    buffer.writeln('0');
    buffer.writeln('ENDSEC');
    buffer.writeln('0');
    buffer.writeln('EOF');

    final file = File(filePath);
    await file.writeAsString(buffer.toString());
  }

  _Bounds? _calculateBounds(SketchState sketch) {
    if (sketch.points.isEmpty) return null;

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final point in sketch.points) {
      minX = math.min(minX, point.position.x);
      maxX = math.max(maxX, point.position.x);
      minY = math.min(minY, point.position.y);
      maxY = math.max(maxY, point.position.y);
    }

    return _Bounds(minX, minY, maxX - minX, maxY - minY);
  }
}

class _Bounds {
  final double minX;
  final double minY;
  final double width;
  final double height;

  _Bounds(this.minX, this.minY, this.width, this.height);
}
