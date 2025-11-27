import 'package:flutter/material.dart';

import '../state/sketch_providers.dart';
import '../domain/sketch_entities.dart';
import '../../../core/commands/command_history.dart';
import '../../../core/commands/sketch_commands.dart';

/// Handles input for different sketch tools.
abstract class SketchToolHandler {
  /// Called when the tool is activated.
  void onActivate() {}

  /// Called when the tool is deactivated.
  void onDeactivate() {}

  /// Called when a tap occurs.
  void onTap(Offset position) {}

  /// Called when a drag starts.
  void onDragStart(Offset position) {}

  /// Called when a drag updates.
  void onDragUpdate(Offset position) {}

  /// Called when a drag ends.
  void onDragEnd() {}

  /// Called to paint tool-specific preview.
  void paint(Canvas canvas, Size size) {}

  /// Reset any in-progress operation.
  void reset() {}
}

/// Tool handler for selection mode.
class SelectToolHandler extends SketchToolHandler {
  final SketchStateNotifier sketchNotifier;
  final void Function(String?) onSelect;
  final double selectionThreshold;

  SelectToolHandler({
    required this.sketchNotifier,
    required this.onSelect,
    this.selectionThreshold = 20.0,
  });

  @override
  void onTap(Offset position) {
    final state = sketchNotifier.currentState;
    String? nearestId;
    double nearestDist = selectionThreshold;

    // Check points
    for (final point in state.points) {
      final dist = (Offset(point.position.x, point.position.y) - position).distance;
      if (dist < nearestDist) {
        nearestDist = dist;
        nearestId = point.id;
      }
    }

    // Check segments (find nearest point on segment)
    for (final segment in state.segments) {
      final start = state.getPoint(segment.startPointId);
      final end = state.getPoint(segment.endPointId);
      if (start != null && end != null) {
        final dist = _distanceToSegment(
          position,
          Offset(start.position.x, start.position.y),
          Offset(end.position.x, end.position.y),
        );
        if (dist < nearestDist) {
          nearestDist = dist;
          nearestId = segment.id;
        }
      }
    }

    onSelect(nearestId);
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final l2 = (end - start).distanceSquared;
    if (l2 == 0) return (point - start).distance;

    var t = ((point - start).dx * (end - start).dx +
            (point - start).dy * (end - start).dy) /
        l2;
    t = t.clamp(0.0, 1.0);

    final projection = start + (end - start) * t;
    return (point - projection).distance;
  }
}

/// Tool handler for drawing lines.
class LineToolHandler extends SketchToolHandler {
  final SketchStateNotifier sketchNotifier;
  final CommandHistoryNotifier commandHistory;

  Offset? _startPoint;
  Offset? _currentPoint;
  bool _isDrawing = false;

  LineToolHandler({
    required this.sketchNotifier,
    required this.commandHistory,
  });

  @override
  void onTap(Offset position) {
    if (_startPoint == null) {
      _startPoint = position;
      _isDrawing = true;
    } else {
      _finalizeLine(position);
    }
  }

  @override
  void onDragStart(Offset position) {
    _startPoint = position;
    _currentPoint = position;
    _isDrawing = true;
  }

  @override
  void onDragUpdate(Offset position) {
    _currentPoint = position;
  }

  @override
  void onDragEnd() {
    if (_startPoint != null && _currentPoint != null) {
      _finalizeLine(_currentPoint!);
    }
    reset();
  }

  void _finalizeLine(Offset endPoint) {
    if (_startPoint == null) return;

    final command = CreateLineCommand(
      sketchNotifier,
      startX: _startPoint!.dx,
      startY: _startPoint!.dy,
      endX: endPoint.dx,
      endY: endPoint.dy,
    );

    commandHistory.execute(command);
    _startPoint = null;
    _currentPoint = null;
    _isDrawing = false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_startPoint == null || !_isDrawing) return;

    final end = _currentPoint ?? _startPoint!;

    canvas.drawLine(
      _startPoint!,
      end,
      Paint()
        ..color = Colors.blue.withOpacity(0.5)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Draw start point indicator
    canvas.drawCircle(
      _startPoint!,
      5,
      Paint()..color = Colors.blue,
    );
  }

  @override
  void reset() {
    _startPoint = null;
    _currentPoint = null;
    _isDrawing = false;
  }
}

/// Tool handler for drawing rectangles.
class RectangleToolHandler extends SketchToolHandler {
  final SketchStateNotifier sketchNotifier;
  final CommandHistoryNotifier commandHistory;

  Offset? _corner1;
  Offset? _corner2;
  bool _isDrawing = false;

  RectangleToolHandler({
    required this.sketchNotifier,
    required this.commandHistory,
  });

  @override
  void onDragStart(Offset position) {
    _corner1 = position;
    _corner2 = position;
    _isDrawing = true;
  }

  @override
  void onDragUpdate(Offset position) {
    _corner2 = position;
  }

  @override
  void onDragEnd() {
    if (_corner1 != null && _corner2 != null) {
      final command = CreateRectangleCommand(
        sketchNotifier,
        x1: _corner1!.dx,
        y1: _corner1!.dy,
        x2: _corner2!.dx,
        y2: _corner2!.dy,
      );

      commandHistory.execute(command);
    }
    reset();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_corner1 == null || _corner2 == null || !_isDrawing) return;

    final rect = Rect.fromPoints(_corner1!, _corner2!);

    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.blue.withOpacity(0.5)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );

    // Draw corner points
    for (final corner in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight
    ]) {
      canvas.drawCircle(
        corner,
        4,
        Paint()..color = Colors.blue,
      );
    }
  }

  @override
  void reset() {
    _corner1 = null;
    _corner2 = null;
    _isDrawing = false;
  }
}

/// Tool handler for drawing circles.
class CircleToolHandler extends SketchToolHandler {
  final SketchStateNotifier sketchNotifier;
  final CommandHistoryNotifier commandHistory;

  Offset? _center;
  Offset? _radiusPoint;
  bool _isDrawing = false;

  CircleToolHandler({
    required this.sketchNotifier,
    required this.commandHistory,
  });

  @override
  void onTap(Offset position) {
    if (_center == null) {
      _center = position;
      _isDrawing = true;
    } else {
      _finalizeCircle(position);
    }
  }

  @override
  void onDragStart(Offset position) {
    _center = position;
    _radiusPoint = position;
    _isDrawing = true;
  }

  @override
  void onDragUpdate(Offset position) {
    _radiusPoint = position;
  }

  @override
  void onDragEnd() {
    if (_center != null && _radiusPoint != null) {
      _finalizeCircle(_radiusPoint!);
    }
  }

  void _finalizeCircle(Offset radiusPoint) {
    if (_center == null) return;

    // Create center point
    final centerPoint = sketchNotifier.addPoint(_center!.dx, _center!.dy);
    // Create radius point
    final radPoint = sketchNotifier.addPoint(radiusPoint.dx, radiusPoint.dy);
    // Create circle
    sketchNotifier.addCircle(centerPoint.id, radPoint.id);

    reset();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_center == null || !_isDrawing) return;

    final radiusPoint = _radiusPoint ?? _center!;
    final radius = (radiusPoint - _center!).distance;

    if (radius > 0) {
      canvas.drawCircle(
        _center!,
        radius,
        Paint()
          ..color = Colors.blue.withOpacity(0.5)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
      );
    }

    // Draw center point
    canvas.drawCircle(
      _center!,
      5,
      Paint()..color = Colors.blue,
    );

    // Draw radius line
    if (_radiusPoint != null) {
      canvas.drawLine(
        _center!,
        _radiusPoint!,
        Paint()
          ..color = Colors.blue.withOpacity(0.3)
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  void reset() {
    _center = null;
    _radiusPoint = null;
    _isDrawing = false;
  }
}

/// Tool handler for drawing arcs (3-point arc).
class ArcToolHandler extends SketchToolHandler {
  final SketchStateNotifier sketchNotifier;
  final CommandHistoryNotifier commandHistory;

  Offset? _startPoint;
  Offset? _midPoint;
  Offset? _endPoint;
  int _clickCount = 0;

  ArcToolHandler({
    required this.sketchNotifier,
    required this.commandHistory,
  });

  @override
  void onTap(Offset position) {
    switch (_clickCount) {
      case 0:
        _startPoint = position;
        _clickCount = 1;
        break;
      case 1:
        _midPoint = position;
        _clickCount = 2;
        break;
      case 2:
        _endPoint = position;
        _finalizeArc();
        break;
    }
  }

  void _finalizeArc() {
    if (_startPoint == null || _midPoint == null || _endPoint == null) return;

    // Calculate center from 3 points
    final center = _calculateCircleCenter(
      _startPoint!,
      _midPoint!,
      _endPoint!,
    );

    if (center != null) {
      // Create points
      final centerPoint = sketchNotifier.addPoint(center.dx, center.dy);
      final startPt = sketchNotifier.addPoint(_startPoint!.dx, _startPoint!.dy);
      final endPt = sketchNotifier.addPoint(_endPoint!.dx, _endPoint!.dy);

      // Determine clockwise direction
      final clockwise = _isClockwise(_startPoint!, _midPoint!, _endPoint!);

      // Create arc
      sketchNotifier.addArc(centerPoint.id, startPt.id, endPt.id,
          clockwise: clockwise);
    }

    reset();
  }

  Offset? _calculateCircleCenter(Offset p1, Offset p2, Offset p3) {
    // Calculate circle center from 3 points using perpendicular bisectors
    final ax = p1.dx;
    final ay = p1.dy;
    final bx = p2.dx;
    final by = p2.dy;
    final cx = p3.dx;
    final cy = p3.dy;

    final d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by));
    if (d.abs() < 1e-10) return null;

    final ux = ((ax * ax + ay * ay) * (by - cy) +
            (bx * bx + by * by) * (cy - ay) +
            (cx * cx + cy * cy) * (ay - by)) /
        d;
    final uy = ((ax * ax + ay * ay) * (cx - bx) +
            (bx * bx + by * by) * (ax - cx) +
            (cx * cx + cy * cy) * (bx - ax)) /
        d;

    return Offset(ux, uy);
  }

  bool _isClockwise(Offset p1, Offset p2, Offset p3) {
    return (p2.dx - p1.dx) * (p3.dy - p1.dy) -
            (p2.dy - p1.dy) * (p3.dx - p1.dx) <
        0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    if (_startPoint != null) {
      canvas.drawCircle(_startPoint!, 5, paint);
    }
    if (_midPoint != null) {
      canvas.drawCircle(_midPoint!, 5, paint);

      // Draw preview arc
      if (_startPoint != null) {
        canvas.drawLine(
          _startPoint!,
          _midPoint!,
          Paint()
            ..color = Colors.blue.withOpacity(0.3)
            ..strokeWidth = 1.0,
        );
      }
    }
  }

  @override
  void reset() {
    _startPoint = null;
    _midPoint = null;
    _endPoint = null;
    _clickCount = 0;
  }
}
