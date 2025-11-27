import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../state/sketch_providers.dart';
import '../domain/sketch_constraints.dart';

/// Canvas widget for 2D sketch editing.
class SketchCanvasWidget extends ConsumerStatefulWidget {
  const SketchCanvasWidget({super.key});

  @override
  ConsumerState<SketchCanvasWidget> createState() => _SketchCanvasWidgetState();
}

class _SketchCanvasWidgetState extends ConsumerState<SketchCanvasWidget> {
  final List<_StrokePoint> _currentStroke = [];
  Offset? _lineStartPoint;
  bool _isDrawingLine = false;
  Offset _panOffset = Offset.zero;
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final sketchState = ref.watch(sketchStateProvider);
    final selectedId = ref.watch(sketchSelectedEntityProvider);
    final toolMode = ref.watch(sketchToolProvider);

    return GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      onTapUp: (details) => _handleTap(details, toolMode),
      child: CustomPaint(
        painter: _SketchPainter(
          sketchState: sketchState,
          currentStroke: _currentStroke,
          lineStartPoint: _lineStartPoint,
          selectedId: selectedId,
          panOffset: _panOffset,
          scale: _scale,
        ),
        child: Container(color: Colors.white),
      ),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    final toolMode = ref.read(sketchToolProvider);

    if (toolMode == SketchToolMode.line && details.pointerCount == 1) {
      setState(() {
        _lineStartPoint = _toSketchCoords(details.focalPoint);
        _isDrawingLine = true;
      });
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final toolMode = ref.read(sketchToolProvider);

    if (_isDrawingLine && details.pointerCount == 1) {
      // Update line preview
      setState(() {});
    } else if (details.pointerCount == 2) {
      // Two-finger pan/zoom
      setState(() {
        _panOffset += details.focalPointDelta;
        _scale = (_scale * details.scale).clamp(0.1, 10.0);
      });
    } else if (toolMode == SketchToolMode.select && details.pointerCount == 1) {
      // Single finger pan in select mode
      setState(() {
        _panOffset += details.focalPointDelta;
      });
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (_isDrawingLine && _lineStartPoint != null) {
      // Finalize the line
      final endPoint = _lineStartPoint!; // Would need to track this properly
      _finalizeLine(_lineStartPoint!, endPoint);
    }

    setState(() {
      _isDrawingLine = false;
      _lineStartPoint = null;
    });
  }

  void _handleTap(TapUpDetails details, SketchToolMode toolMode) {
    final sketchCoords = _toSketchCoords(details.localPosition);

    switch (toolMode) {
      case SketchToolMode.select:
        _handleSelection(sketchCoords);
        break;
      case SketchToolMode.line:
        _handleLinePoint(sketchCoords);
        break;
      case SketchToolMode.circle:
        _handleCirclePoint(sketchCoords);
        break;
      default:
        break;
    }
  }

  Offset _toSketchCoords(Offset screenPos) {
    return (screenPos - _panOffset) / _scale;
  }

  void _handleSelection(Offset pos) {
    final sketchState = ref.read(sketchStateProvider);

    // Find nearest point within threshold
    const threshold = 20.0;
    String? nearestId;
    double nearestDist = threshold;

    for (final point in sketchState.points) {
      final dist = (Offset(point.position.x, point.position.y) - pos).distance;
      if (dist < nearestDist) {
        nearestDist = dist;
        nearestId = point.id;
      }
    }

    ref.read(sketchSelectedEntityProvider.notifier).state = nearestId;
  }

  void _handleLinePoint(Offset pos) {
    if (_lineStartPoint == null) {
      setState(() {
        _lineStartPoint = pos;
      });
    } else {
      _finalizeLine(_lineStartPoint!, pos);
      setState(() {
        _lineStartPoint = null;
      });
    }
  }

  void _finalizeLine(Offset start, Offset end) {
    final notifier = ref.read(sketchStateProvider.notifier);
    final startPoint = notifier.addPoint(start.dx, start.dy);
    final endPoint = notifier.addPoint(end.dx, end.dy);
    notifier.addSegment(startPoint.id, endPoint.id);
  }

  void _handleCirclePoint(Offset pos) {
    // TODO: Implement circle creation (two-click: center then radius)
  }
}

class _StrokePoint {
  final Offset position;
  final double pressure;

  _StrokePoint(this.position, this.pressure);
}

class _SketchPainter extends CustomPainter {
  final SketchState sketchState;
  final List<_StrokePoint> currentStroke;
  final Offset? lineStartPoint;
  final String? selectedId;
  final Offset panOffset;
  final double scale;

  _SketchPainter({
    required this.sketchState,
    required this.currentStroke,
    this.lineStartPoint,
    this.selectedId,
    required this.panOffset,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(scale);

    _drawGrid(canvas, size);
    _drawSketchEntities(canvas);
    _drawCurrentStroke(canvas);
    _drawLinePreview(canvas);
    _drawConstraintIndicators(canvas);

    canvas.restore();

    _drawStatusOverlay(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;

    const gridSize = 20.0;
    final adjustedSize = Size(size.width / scale, size.height / scale);
    final startX = -panOffset.dx / scale;
    final startY = -panOffset.dy / scale;

    for (var x = (startX ~/ gridSize) * gridSize;
        x < startX + adjustedSize.width;
        x += gridSize) {
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, startY + adjustedSize.height),
        gridPaint,
      );
    }

    for (var y = (startY ~/ gridSize) * gridSize;
        y < startY + adjustedSize.height;
        y += gridSize) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + adjustedSize.width, y),
        gridPaint,
      );
    }

    // Draw axes
    final axisPaint = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // X axis
    axisPaint.color = Colors.red.withOpacity(0.5);
    canvas.drawLine(
      Offset(startX, 0),
      Offset(startX + adjustedSize.width, 0),
      axisPaint,
    );

    // Y axis
    axisPaint.color = Colors.green.withOpacity(0.5);
    canvas.drawLine(
      Offset(0, startY),
      Offset(0, startY + adjustedSize.height),
      axisPaint,
    );
  }

  void _drawSketchEntities(Canvas canvas) {
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final selectedPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final constrainedPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    // Draw segments
    for (final segment in sketchState.segments) {
      final start = sketchState.getPoint(segment.startPointId);
      final end = sketchState.getPoint(segment.endPointId);

      if (start != null && end != null) {
        final paint = segment.id == selectedId ? selectedPaint : linePaint;
        canvas.drawLine(
          Offset(start.position.x, start.position.y),
          Offset(end.position.x, end.position.y),
          paint,
        );
      }
    }

    // Draw circles
    for (final circle in sketchState.circles) {
      final center = sketchState.getPoint(circle.centerPointId);
      final radiusPoint = sketchState.getPoint(circle.radiusPointId);

      if (center != null && radiusPoint != null) {
        final radius = (radiusPoint.position - center.position).length;
        final paint = circle.id == selectedId ? selectedPaint : linePaint;
        canvas.drawCircle(
          Offset(center.position.x, center.position.y),
          radius,
          paint..style = PaintingStyle.stroke,
        );
      }
    }

    // Draw points
    for (final point in sketchState.points) {
      final paint = point.isFixed ? constrainedPaint : pointPaint;
      final isSelected = point.id == selectedId;

      canvas.drawCircle(
        Offset(point.position.x, point.position.y),
        isSelected ? 6.0 : 4.0,
        paint,
      );

      if (isSelected) {
        canvas.drawCircle(
          Offset(point.position.x, point.position.y),
          8.0,
          Paint()
            ..color = Colors.blue.withOpacity(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      }
    }
  }

  void _drawCurrentStroke(Canvas canvas) {
    if (currentStroke.length < 2) return;

    final points = currentStroke
        .map((sp) => Point(sp.position.dx, sp.position.dy, sp.pressure))
        .toList();

    final pathPoints = getStroke(points);
    if (pathPoints.isEmpty) return;

    final path = Path()..moveTo(pathPoints.first.x, pathPoints.first.y);

    for (var i = 1; i < pathPoints.length; i++) {
      path.lineTo(pathPoints[i].x, pathPoints[i].y);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.grey.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  void _drawLinePreview(Canvas canvas) {
    if (lineStartPoint == null) return;

    canvas.drawCircle(
      lineStartPoint!,
      5.0,
      Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill,
    );
  }

  void _drawConstraintIndicators(Canvas canvas) {
    for (final constraint in sketchState.constraints) {
      if (constraint.type == SketchConstraintType.horizontal ||
          constraint.type == SketchConstraintType.vertical) {
        // Draw small indicator for H/V constraints
        final entityId = constraint.entityIds.first;
        final segment = sketchState.segments
            .where((s) => s.id == entityId)
            .firstOrNull;

        if (segment != null) {
          final start = sketchState.getPoint(segment.startPointId);
          final end = sketchState.getPoint(segment.endPointId);

          if (start != null && end != null) {
            final mid = Offset(
              (start.position.x + end.position.x) / 2,
              (start.position.y + end.position.y) / 2,
            );

            final text = constraint.type == SketchConstraintType.horizontal
                ? 'H'
                : 'V';
            final textPainter = TextPainter(
              text: TextSpan(
                text: text,
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout();

            textPainter.paint(canvas, mid + const Offset(5, -5));
          }
        }
      }
    }
  }

  void _drawStatusOverlay(Canvas canvas, Size size) {
    final solveStatus = sketchState.lastSolveResult;
    if (solveStatus == null) return;

    final color = switch (solveStatus) {
      SolveResult.fullyConstrained => Colors.green,
      SolveResult.underConstrained => Colors.orange,
      SolveResult.overConstrained => Colors.red,
      SolveResult.failed => Colors.red,
    };

    final text = switch (solveStatus) {
      SolveResult.fullyConstrained => 'Fully Constrained',
      SolveResult.underConstrained => 'Under Constrained',
      SolveResult.overConstrained => 'Over Constrained',
      SolveResult.failed => 'Solve Failed',
    };

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(size.width - textPainter.width - 10, 10));
  }

  @override
  bool shouldRepaint(covariant _SketchPainter oldDelegate) {
    return true; // Simplified; could optimize
  }
}
