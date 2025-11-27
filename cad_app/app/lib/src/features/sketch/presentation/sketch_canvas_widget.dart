import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/sketch_providers.dart';
import '../domain/sketch_constraints.dart';
import '../../../core/commands/command_history.dart';
import 'sketch_tool_handler.dart';

/// Canvas widget for 2D sketch editing.
class SketchCanvasWidget extends ConsumerStatefulWidget {
  const SketchCanvasWidget({super.key});

  @override
  ConsumerState<SketchCanvasWidget> createState() => _SketchCanvasWidgetState();
}

class _SketchCanvasWidgetState extends ConsumerState<SketchCanvasWidget> {
  Offset _panOffset = Offset.zero;
  double _scale = 1.0;
  Offset? _lastFocalPoint;

  SketchToolHandler? _currentHandler;
  SketchToolMode? _lastToolMode;

  @override
  Widget build(BuildContext context) {
    final sketchState = ref.watch(sketchStateProvider);
    final selectedId = ref.watch(sketchSelectedEntityProvider);
    final toolMode = ref.watch(sketchToolProvider);

    // Update handler when tool mode changes
    if (toolMode != _lastToolMode) {
      _updateHandler(toolMode);
      _lastToolMode = toolMode;
    }

    return GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      onTapUp: (details) => _handleTap(details),
      child: CustomPaint(
        painter: _SketchPainter(
          sketchState: sketchState,
          lineStartPoint: null,
          selectedId: selectedId,
          panOffset: _panOffset,
          scale: _scale,
          toolHandler: _currentHandler,
        ),
        child: Container(color: Colors.white),
      ),
    );
  }

  void _updateHandler(SketchToolMode mode) {
    _currentHandler?.onDeactivate();

    final sketchNotifier = ref.read(sketchStateProvider.notifier);
    final commandHistory = ref.read(commandHistoryProvider.notifier);

    switch (mode) {
      case SketchToolMode.select:
        _currentHandler = SelectToolHandler(
          sketchNotifier: sketchNotifier,
          onSelect: (id) {
            ref.read(sketchSelectedEntityProvider.notifier).state = id;
          },
        );
        break;
      case SketchToolMode.line:
        _currentHandler = LineToolHandler(
          sketchNotifier: sketchNotifier,
          commandHistory: commandHistory,
        );
        break;
      case SketchToolMode.rectangle:
        _currentHandler = RectangleToolHandler(
          sketchNotifier: sketchNotifier,
          commandHistory: commandHistory,
        );
        break;
      case SketchToolMode.circle:
        _currentHandler = CircleToolHandler(
          sketchNotifier: sketchNotifier,
          commandHistory: commandHistory,
        );
        break;
      case SketchToolMode.arc:
        _currentHandler = ArcToolHandler(
          sketchNotifier: sketchNotifier,
          commandHistory: commandHistory,
        );
        break;
      case SketchToolMode.dimension:
      case SketchToolMode.constraint:
        _currentHandler = SelectToolHandler(
          sketchNotifier: sketchNotifier,
          onSelect: (id) {
            ref.read(sketchSelectedEntityProvider.notifier).state = id;
          },
        );
        break;
    }

    _currentHandler?.onActivate();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.focalPoint;

    if (details.pointerCount == 1) {
      final sketchCoords = _toSketchCoords(details.localFocalPoint);
      _currentHandler?.onDragStart(sketchCoords);
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final toolMode = ref.read(sketchToolProvider);

    if (details.pointerCount == 2) {
      // Two-finger pan/zoom
      if (_lastFocalPoint != null) {
        setState(() {
          _panOffset += details.focalPoint - _lastFocalPoint!;
          _scale = (_scale * details.scale).clamp(0.1, 10.0);
          _lastFocalPoint = details.focalPoint;
        });
      }
    } else if (details.pointerCount == 1) {
      final sketchCoords = _toSketchCoords(details.localFocalPoint);

      if (toolMode == SketchToolMode.select) {
        // Single finger pan in select mode
        if (_lastFocalPoint != null) {
          setState(() {
            _panOffset += details.focalPoint - _lastFocalPoint!;
            _lastFocalPoint = details.focalPoint;
          });
        }
      } else {
        // Update tool handler with drag position
        _currentHandler?.onDragUpdate(sketchCoords);
        setState(() {}); // Trigger repaint for preview
      }
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _currentHandler?.onDragEnd();
    _lastFocalPoint = null;
    setState(() {}); // Trigger repaint
  }

  void _handleTap(TapUpDetails details) {
    final sketchCoords = _toSketchCoords(details.localPosition);
    _currentHandler?.onTap(sketchCoords);
    setState(() {}); // Trigger repaint for preview updates
  }

  Offset _toSketchCoords(Offset screenPos) {
    return (screenPos - _panOffset) / _scale;
  }
}

class _SketchPainter extends CustomPainter {
  final SketchState sketchState;
  final Offset? lineStartPoint;
  final String? selectedId;
  final Offset panOffset;
  final double scale;
  final SketchToolHandler? toolHandler;

  _SketchPainter({
    required this.sketchState,
    this.lineStartPoint,
    this.selectedId,
    required this.panOffset,
    required this.scale,
    this.toolHandler,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(scale);

    _drawGrid(canvas, size);
    _drawSketchEntities(canvas);
    _drawConstraintIndicators(canvas);

    // Let tool handler draw its preview
    toolHandler?.paint(canvas, size);

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

    // Draw arcs
    for (final arc in sketchState.arcs) {
      final center = sketchState.getPoint(arc.centerPointId);
      final startPoint = sketchState.getPoint(arc.startPointId);
      final endPoint = sketchState.getPoint(arc.endPointId);

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

        var sweep = endAngle - startAngle;
        if (arc.clockwise && sweep > 0) sweep -= 2 * math.pi;
        if (!arc.clockwise && sweep < 0) sweep += 2 * math.pi;

        final paint = arc.id == selectedId ? selectedPaint : linePaint;
        paint.style = PaintingStyle.stroke;

        final rect = Rect.fromCircle(
          center: Offset(center.position.x, center.position.y),
          radius: radius,
        );

        canvas.drawArc(rect, startAngle, sweep, false, paint);
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
      } else if (constraint.type == SketchConstraintType.distance &&
          constraint.value != null) {
        // Draw distance dimension
        if (constraint.entityIds.length >= 2) {
          final p1 = sketchState.getPoint(constraint.entityIds[0]);
          final p2 = sketchState.getPoint(constraint.entityIds[1]);

          if (p1 != null && p2 != null) {
            final mid = Offset(
              (p1.position.x + p2.position.x) / 2,
              (p1.position.y + p2.position.y) / 2,
            );

            final textPainter = TextPainter(
              text: TextSpan(
                text: constraint.value!.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.purple,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.white70,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout();

            textPainter.paint(canvas, mid + const Offset(5, -15));
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
