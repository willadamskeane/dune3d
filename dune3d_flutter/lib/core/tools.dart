import 'dart:math' as math;
import 'geometry.dart';
import 'entities.dart';
import 'sketch_document.dart';

/// Tool identifiers
enum ToolType {
  select,
  line,
  circle,
  rectangle,
  arc,
  point,
  trim,
  delete,
}

/// Base class for sketch tools
abstract class SketchTool {
  final ToolType type;
  final SketchDocument document;

  SketchTool({required this.type, required this.document});

  /// Called when the tool becomes active
  void activate() {}

  /// Called when the tool becomes inactive
  void deactivate() {}

  /// Handle pointer down event
  void onPointerDown(Vec2 position);

  /// Handle pointer move event
  void onPointerMove(Vec2 position);

  /// Handle pointer up event
  void onPointerUp(Vec2 position);

  /// Handle cancel (escape key, etc.)
  void cancel();

  /// Get the preview entity to render (if any)
  SketchEntity? get previewEntity => null;

  /// Get preview points (e.g., for snapping indicators)
  List<Vec2> get previewPoints => [];

  /// Whether this tool is currently in a drawing operation
  bool get isDrawing;
}

/// Select tool - for selecting and moving entities
class SelectTool extends SketchTool {
  Vec2? _dragStart;
  Vec2? _lastPosition;
  bool _isDragging = false;
  bool _isBoxSelecting = false;
  Vec2? _boxSelectStart;

  SelectTool({required super.document}) : super(type: ToolType.select);

  @override
  bool get isDrawing => _isDragging || _isBoxSelecting;

  BoundingBox? get selectionBox {
    if (!_isBoxSelecting || _boxSelectStart == null || _lastPosition == null) {
      return null;
    }
    return BoundingBox.fromPoints([_boxSelectStart!, _lastPosition!]);
  }

  @override
  void onPointerDown(Vec2 position) {
    _dragStart = position;
    _lastPosition = position;

    // Try to find entity at position
    final hitEntity = document.findEntityAt(position, 10);

    if (hitEntity != null) {
      if (!hitEntity.isSelected) {
        document.selectEntity(hitEntity.id);
      }
      document.beginDrag();
      _isDragging = true;
    } else {
      // Start box selection
      document.clearSelection();
      _isBoxSelecting = true;
      _boxSelectStart = position;
    }
  }

  @override
  void onPointerMove(Vec2 position) {
    if (_isDragging && _lastPosition != null) {
      final delta = position - _lastPosition!;
      document.moveSelectedEntities(delta);
    }
    _lastPosition = position;
  }

  @override
  void onPointerUp(Vec2 position) {
    if (_isBoxSelecting && _boxSelectStart != null) {
      final box = BoundingBox.fromPoints([_boxSelectStart!, position]);
      document.selectInBox(box);
    }

    _dragStart = null;
    _lastPosition = null;
    _isDragging = false;
    _isBoxSelecting = false;
    _boxSelectStart = null;
  }

  @override
  void cancel() {
    _dragStart = null;
    _lastPosition = null;
    _isDragging = false;
    _isBoxSelecting = false;
    _boxSelectStart = null;
  }
}

/// Line tool - for drawing line segments
class LineTool extends SketchTool {
  Vec2? _startPoint;
  Vec2? _currentPoint;
  bool _isDrawing = false;
  LineEntity? _preview;

  LineTool({required super.document}) : super(type: ToolType.line);

  @override
  bool get isDrawing => _isDrawing;

  @override
  SketchEntity? get previewEntity => _preview;

  @override
  List<Vec2> get previewPoints =>
      _startPoint != null ? [_startPoint!] : [];

  @override
  void onPointerDown(Vec2 position) {
    if (!_isDrawing) {
      _startPoint = GeometryUtils.snapToGrid(position, 10);
      _currentPoint = _startPoint;
      _isDrawing = true;
      _updatePreview();
    } else {
      // Complete the line
      final endPoint = GeometryUtils.snapToGrid(position, 10);
      if (_startPoint!.distanceTo(endPoint) > 1) {
        document.addLine(_startPoint!, endPoint);
      }
      // Continue drawing from end point
      _startPoint = endPoint;
      _updatePreview();
    }
  }

  @override
  void onPointerMove(Vec2 position) {
    if (_isDrawing) {
      _currentPoint = GeometryUtils.snapToGrid(position, 10);
      _updatePreview();
    }
  }

  @override
  void onPointerUp(Vec2 position) {
    // Line tool continues until cancelled
  }

  @override
  void cancel() {
    _startPoint = null;
    _currentPoint = null;
    _isDrawing = false;
    _preview = null;
  }

  void _updatePreview() {
    if (_startPoint != null && _currentPoint != null) {
      _preview = LineEntity(
        id: 'preview',
        start: _startPoint!,
        end: _currentPoint!,
      );
    } else {
      _preview = null;
    }
  }
}

/// Circle tool - for drawing circles
class CircleTool extends SketchTool {
  Vec2? _center;
  Vec2? _currentPoint;
  bool _isDrawing = false;
  CircleEntity? _preview;

  CircleTool({required super.document}) : super(type: ToolType.circle);

  @override
  bool get isDrawing => _isDrawing;

  @override
  SketchEntity? get previewEntity => _preview;

  @override
  List<Vec2> get previewPoints => _center != null ? [_center!] : [];

  @override
  void onPointerDown(Vec2 position) {
    if (!_isDrawing) {
      _center = GeometryUtils.snapToGrid(position, 10);
      _currentPoint = _center;
      _isDrawing = true;
      _updatePreview();
    } else {
      // Complete the circle
      final endPoint = GeometryUtils.snapToGrid(position, 10);
      final radius = _center!.distanceTo(endPoint);
      if (radius > 1) {
        document.addCircle(_center!, radius);
      }
      cancel();
    }
  }

  @override
  void onPointerMove(Vec2 position) {
    if (_isDrawing) {
      _currentPoint = GeometryUtils.snapToGrid(position, 10);
      _updatePreview();
    }
  }

  @override
  void onPointerUp(Vec2 position) {
    // Circle tool waits for second click
  }

  @override
  void cancel() {
    _center = null;
    _currentPoint = null;
    _isDrawing = false;
    _preview = null;
  }

  void _updatePreview() {
    if (_center != null && _currentPoint != null) {
      final radius = _center!.distanceTo(_currentPoint!);
      _preview = CircleEntity(
        id: 'preview',
        center: _center!,
        radius: radius > 0 ? radius : 1,
      );
    } else {
      _preview = null;
    }
  }
}

/// Rectangle tool - for drawing rectangles
class RectangleTool extends SketchTool {
  Vec2? _corner1;
  Vec2? _currentPoint;
  bool _isDrawing = false;
  RectangleEntity? _preview;

  RectangleTool({required super.document}) : super(type: ToolType.rectangle);

  @override
  bool get isDrawing => _isDrawing;

  @override
  SketchEntity? get previewEntity => _preview;

  @override
  List<Vec2> get previewPoints => _corner1 != null ? [_corner1!] : [];

  @override
  void onPointerDown(Vec2 position) {
    if (!_isDrawing) {
      _corner1 = GeometryUtils.snapToGrid(position, 10);
      _currentPoint = _corner1;
      _isDrawing = true;
      _updatePreview();
    } else {
      // Complete the rectangle
      final corner2 = GeometryUtils.snapToGrid(position, 10);
      if (_corner1!.distanceTo(corner2) > 1) {
        document.addRectangle(_corner1!, corner2);
      }
      cancel();
    }
  }

  @override
  void onPointerMove(Vec2 position) {
    if (_isDrawing) {
      _currentPoint = GeometryUtils.snapToGrid(position, 10);
      _updatePreview();
    }
  }

  @override
  void onPointerUp(Vec2 position) {
    // Rectangle tool waits for second click
  }

  @override
  void cancel() {
    _corner1 = null;
    _currentPoint = null;
    _isDrawing = false;
    _preview = null;
  }

  void _updatePreview() {
    if (_corner1 != null && _currentPoint != null) {
      _preview = RectangleEntity(
        id: 'preview',
        corner1: _corner1!,
        corner2: _currentPoint!,
      );
    } else {
      _preview = null;
    }
  }
}

/// Arc tool - for drawing arcs (three-point arc)
class ArcTool extends SketchTool {
  Vec2? _startPoint;
  Vec2? _midPoint;
  Vec2? _currentPoint;
  int _clickCount = 0;
  ArcEntity? _preview;

  ArcTool({required super.document}) : super(type: ToolType.arc);

  @override
  bool get isDrawing => _clickCount > 0;

  @override
  SketchEntity? get previewEntity => _preview;

  @override
  List<Vec2> get previewPoints {
    final points = <Vec2>[];
    if (_startPoint != null) points.add(_startPoint!);
    if (_midPoint != null) points.add(_midPoint!);
    return points;
  }

  @override
  void onPointerDown(Vec2 position) {
    final snapped = GeometryUtils.snapToGrid(position, 10);

    switch (_clickCount) {
      case 0:
        _startPoint = snapped;
        _clickCount = 1;
        break;
      case 1:
        _midPoint = snapped;
        _clickCount = 2;
        break;
      case 2:
        // Complete the arc
        final arcData = _calculateArc(_startPoint!, _midPoint!, snapped);
        if (arcData != null) {
          document.addArc(
            arcData.center,
            arcData.radius,
            arcData.startAngle,
            arcData.sweepAngle,
          );
        }
        cancel();
        break;
    }
    _currentPoint = snapped;
    _updatePreview();
  }

  @override
  void onPointerMove(Vec2 position) {
    _currentPoint = GeometryUtils.snapToGrid(position, 10);
    _updatePreview();
  }

  @override
  void onPointerUp(Vec2 position) {
    // Arc tool waits for clicks
  }

  @override
  void cancel() {
    _startPoint = null;
    _midPoint = null;
    _currentPoint = null;
    _clickCount = 0;
    _preview = null;
  }

  void _updatePreview() {
    if (_clickCount < 2 || _startPoint == null || _midPoint == null || _currentPoint == null) {
      _preview = null;
      return;
    }

    final arcData = _calculateArc(_startPoint!, _midPoint!, _currentPoint!);
    if (arcData != null) {
      _preview = ArcEntity(
        id: 'preview',
        center: arcData.center,
        radius: arcData.radius,
        startAngle: arcData.startAngle,
        sweepAngle: arcData.sweepAngle,
      );
    }
  }

  _ArcData? _calculateArc(Vec2 p1, Vec2 p2, Vec2 p3) {
    // Calculate circumcircle of three points
    final ax = p1.x, ay = p1.y;
    final bx = p2.x, by = p2.y;
    final cx = p3.x, cy = p3.y;

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

    final center = Vec2(ux, uy);
    final radius = center.distanceTo(p1);

    // Calculate angles
    final startAngle = math.atan2(p1.y - center.y, p1.x - center.x);
    final endAngle = math.atan2(p3.y - center.y, p3.x - center.x);
    final midAngle = math.atan2(p2.y - center.y, p2.x - center.x);

    // Determine sweep direction
    var sweep = endAngle - startAngle;
    final midSweep = midAngle - startAngle;

    // Normalize angles
    while (sweep < -math.pi) sweep += 2 * math.pi;
    while (sweep > math.pi) sweep -= 2 * math.pi;

    var normalizedMidSweep = midSweep;
    while (normalizedMidSweep < -math.pi) normalizedMidSweep += 2 * math.pi;
    while (normalizedMidSweep > math.pi) normalizedMidSweep -= 2 * math.pi;

    // Check if mid point is on the short arc
    if ((sweep > 0 && normalizedMidSweep < 0) ||
        (sweep < 0 && normalizedMidSweep > 0)) {
      // Need to go the long way
      if (sweep > 0) {
        sweep = sweep - 2 * math.pi;
      } else {
        sweep = sweep + 2 * math.pi;
      }
    }

    return _ArcData(center, radius, startAngle, sweep);
  }
}

class _ArcData {
  final Vec2 center;
  final double radius;
  final double startAngle;
  final double sweepAngle;

  _ArcData(this.center, this.radius, this.startAngle, this.sweepAngle);
}

/// Delete tool - for deleting entities
class DeleteTool extends SketchTool {
  DeleteTool({required super.document}) : super(type: ToolType.delete);

  @override
  bool get isDrawing => false;

  @override
  void onPointerDown(Vec2 position) {
    final entity = document.findEntityAt(position, 10);
    if (entity != null) {
      document.removeEntity(entity.id);
    }
  }

  @override
  void onPointerMove(Vec2 position) {}

  @override
  void onPointerUp(Vec2 position) {}

  @override
  void cancel() {}
}

/// Trim tool - for trimming entities at intersections
class TrimTool extends SketchTool {
  TrimTool({required super.document}) : super(type: ToolType.trim);

  @override
  bool get isDrawing => false;

  @override
  void onPointerDown(Vec2 position) {
    final entity = document.findEntityAt(position, 10);
    if (entity == null) return;

    // For now, just delete the entity (proper trim would split at intersections)
    // A full implementation would find intersections and split the entity
    if (entity is LineEntity) {
      // Find intersections with other entities
      final intersections = <Vec2>[];

      for (final other in document.entities) {
        if (other.id == entity.id) continue;

        if (other is LineEntity) {
          final inter = GeometryUtils.segmentIntersection(
            entity.start,
            entity.end,
            other.start,
            other.end,
          );
          if (inter != null) {
            intersections.add(inter);
          }
        } else if (other is CircleEntity) {
          final inters = GeometryUtils.lineCircleIntersection(
            entity.start,
            entity.end,
            other.center,
            other.radius,
          );
          intersections.addAll(inters);
        }
      }

      if (intersections.isEmpty) {
        // No intersections, just delete
        document.removeEntity(entity.id);
        return;
      }

      // Sort intersections by distance from click point
      intersections.sort(
          (a, b) => a.distanceTo(position).compareTo(b.distanceTo(position)));

      // Find which segment the click is in
      // For simplicity, delete the entity
      // A full implementation would create new entities for remaining segments
      document.removeEntity(entity.id);
    } else {
      // For other entity types, just delete
      document.removeEntity(entity.id);
    }
  }

  @override
  void onPointerMove(Vec2 position) {}

  @override
  void onPointerUp(Vec2 position) {}

  @override
  void cancel() {}
}

/// Tool factory
class ToolFactory {
  static SketchTool createTool(ToolType type, SketchDocument document) {
    switch (type) {
      case ToolType.select:
        return SelectTool(document: document);
      case ToolType.line:
        return LineTool(document: document);
      case ToolType.circle:
        return CircleTool(document: document);
      case ToolType.rectangle:
        return RectangleTool(document: document);
      case ToolType.arc:
        return ArcTool(document: document);
      case ToolType.point:
        return _PointTool(document: document);
      case ToolType.trim:
        return TrimTool(document: document);
      case ToolType.delete:
        return DeleteTool(document: document);
    }
  }
}

/// Point tool - for placing individual points
class _PointTool extends SketchTool {
  _PointTool({required super.document}) : super(type: ToolType.point);

  @override
  bool get isDrawing => false;

  @override
  void onPointerDown(Vec2 position) {
    final snapped = GeometryUtils.snapToGrid(position, 10);
    document.addPoint(snapped);
  }

  @override
  void onPointerMove(Vec2 position) {}

  @override
  void onPointerUp(Vec2 position) {}

  @override
  void cancel() {}
}
