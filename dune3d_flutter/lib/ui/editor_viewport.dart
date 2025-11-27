import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../core/core.dart';

/// Main editor viewport for displaying and interacting with sketches
class EditorViewport extends StatefulWidget {
  final SketchDocument document;
  final SketchTool? currentTool;
  final VoidCallback? onViewChanged;

  const EditorViewport({
    super.key,
    required this.document,
    this.currentTool,
    this.onViewChanged,
  });

  @override
  State<EditorViewport> createState() => EditorViewportState();
}

class EditorViewportState extends State<EditorViewport> {
  // View transformation
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  // Interaction state
  Offset? _lastFocalPoint;
  double _lastScale = 1.0;

  // Coordinate system
  static const double _gridSize = 10.0;
  static const double _minScale = 0.1;
  static const double _maxScale = 10.0;

  @override
  void initState() {
    super.initState();
    widget.document.addListener(_onDocumentChanged);
  }

  @override
  void didUpdateWidget(EditorViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document != widget.document) {
      oldWidget.document.removeListener(_onDocumentChanged);
      widget.document.addListener(_onDocumentChanged);
    }
  }

  @override
  void dispose() {
    widget.document.removeListener(_onDocumentChanged);
    super.dispose();
  }

  void _onDocumentChanged() {
    setState(() {});
  }

  /// Convert screen coordinates to world coordinates
  Vec2 screenToWorld(Offset screenPoint) {
    final x = (screenPoint.dx - _offset.dx) / _scale;
    final y = (screenPoint.dy - _offset.dy) / _scale;
    return Vec2(x, y);
  }

  /// Convert world coordinates to screen coordinates
  Offset worldToScreen(Vec2 worldPoint) {
    final x = worldPoint.x * _scale + _offset.dx;
    final y = worldPoint.y * _scale + _offset.dy;
    return Offset(x, y);
  }

  /// Reset view to default
  void resetView() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
    });
    widget.onViewChanged?.call();
  }

  /// Zoom to fit all entities
  void zoomToFit() {
    if (widget.document.entityCount == 0) {
      resetView();
      return;
    }

    final bounds = widget.document.entities
        .map((e) => e.boundingBox)
        .reduce((a, b) => a.union(b));

    final size = context.size;
    if (size == null) return;

    final padding = 50.0;
    final viewWidth = size.width - padding * 2;
    final viewHeight = size.height - padding * 2;

    final scaleX = viewWidth / bounds.width;
    final scaleY = viewHeight / bounds.height;

    setState(() {
      _scale = (scaleX < scaleY ? scaleX : scaleY).clamp(_minScale, _maxScale);
      _offset = Offset(
        size.width / 2 - bounds.center.x * _scale,
        size.height / 2 - bounds.center.y * _scale,
      );
    });
    widget.onViewChanged?.call();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.localFocalPoint;
    _lastScale = _scale;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // Handle zoom
      if (details.scale != 1.0) {
        final newScale = (_lastScale * details.scale).clamp(_minScale, _maxScale);
        final focalPoint = details.localFocalPoint;

        // Zoom around focal point
        final worldFocal = screenToWorld(focalPoint);
        _scale = newScale;
        _offset = Offset(
          focalPoint.dx - worldFocal.x * _scale,
          focalPoint.dy - worldFocal.y * _scale,
        );
      }

      // Handle pan
      if (_lastFocalPoint != null) {
        final delta = details.localFocalPoint - _lastFocalPoint!;
        if (details.scale == 1.0) {
          _offset += delta;
        }
      }

      _lastFocalPoint = details.localFocalPoint;
    });
    widget.onViewChanged?.call();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final zoomFactor = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
      final newScale = (_scale * zoomFactor).clamp(_minScale, _maxScale);

      if (newScale != _scale) {
        setState(() {
          final focalPoint = event.localPosition;
          final worldFocal = screenToWorld(focalPoint);
          _scale = newScale;
          _offset = Offset(
            focalPoint.dx - worldFocal.x * _scale,
            focalPoint.dy - worldFocal.y * _scale,
          );
        });
        widget.onViewChanged?.call();
      }
    }
  }

  void _handleTapDown(TapDownDetails details) {
    final worldPos = screenToWorld(details.localPosition);
    widget.currentTool?.onPointerDown(worldPos);
  }

  void _handleTapUp(TapUpDetails details) {
    final worldPos = screenToWorld(details.localPosition);
    widget.currentTool?.onPointerUp(worldPos);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final worldPos = screenToWorld(event.localPosition);
    widget.currentTool?.onPointerMove(worldPos);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handlePointerSignal,
      onPointerMove: _handlePointerMove,
      child: GestureDetector(
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        child: Container(
          color: const Color(0xFF1E1E1E),
          child: CustomPaint(
            painter: SketchPainter(
              document: widget.document,
              tool: widget.currentTool,
              scale: _scale,
              offset: _offset,
              gridSize: _gridSize,
            ),
            child: Container(),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for rendering the sketch
class SketchPainter extends CustomPainter {
  final SketchDocument document;
  final SketchTool? tool;
  final double scale;
  final Offset offset;
  final double gridSize;

  SketchPainter({
    required this.document,
    this.tool,
    required this.scale,
    required this.offset,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Save canvas state
    canvas.save();

    // Apply view transformation
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // Draw grid
    _drawGrid(canvas, size);

    // Draw origin
    _drawOrigin(canvas);

    // Draw entities
    _drawEntities(canvas);

    // Draw preview entity from tool
    _drawPreview(canvas);

    // Draw selection box if select tool
    if (tool is SelectTool) {
      _drawSelectionBox(canvas, tool as SelectTool);
    }

    // Restore canvas state
    canvas.restore();

    // Draw UI elements (not affected by view transform)
    _drawUI(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1 / scale;

    // Calculate visible area in world coordinates
    final minX = -offset.dx / scale;
    final minY = -offset.dy / scale;
    final maxX = (size.width - offset.dx) / scale;
    final maxY = (size.height - offset.dy) / scale;

    // Grid spacing
    double spacing = gridSize;
    while (spacing * scale < 20) {
      spacing *= 2;
    }
    while (spacing * scale > 100) {
      spacing /= 2;
    }

    // Draw vertical lines
    final startX = (minX / spacing).floor() * spacing;
    for (double x = startX; x <= maxX; x += spacing) {
      final isMajor = (x / (spacing * 5)).round() * spacing * 5 == x;
      paint.color = isMajor
          ? Colors.grey.withOpacity(0.4)
          : Colors.grey.withOpacity(0.2);
      canvas.drawLine(Offset(x, minY), Offset(x, maxY), paint);
    }

    // Draw horizontal lines
    final startY = (minY / spacing).floor() * spacing;
    for (double y = startY; y <= maxY; y += spacing) {
      final isMajor = (y / (spacing * 5)).round() * spacing * 5 == y;
      paint.color = isMajor
          ? Colors.grey.withOpacity(0.4)
          : Colors.grey.withOpacity(0.2);
      canvas.drawLine(Offset(minX, y), Offset(maxX, y), paint);
    }
  }

  void _drawOrigin(Canvas canvas) {
    final paint = Paint()
      ..strokeWidth = 2 / scale
      ..strokeCap = StrokeCap.round;

    // X axis (red)
    paint.color = Colors.red.withOpacity(0.7);
    canvas.drawLine(const Offset(0, 0), Offset(50 / scale, 0), paint);

    // Y axis (green)
    paint.color = Colors.green.withOpacity(0.7);
    canvas.drawLine(const Offset(0, 0), Offset(0, 50 / scale), paint);

    // Origin point
    paint.color = Colors.white;
    canvas.drawCircle(const Offset(0, 0), 4 / scale, paint);
  }

  void _drawEntities(Canvas canvas) {
    final normalPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2 / scale
      ..style = PaintingStyle.stroke;

    final selectedPaint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 3 / scale
      ..style = PaintingStyle.stroke;

    final constructionPaint = Paint()
      ..color = Colors.orange.withOpacity(0.6)
      ..strokeWidth = 1.5 / scale
      ..style = PaintingStyle.stroke;

    for (final entity in document.entities) {
      Paint paint;
      if (entity.isSelected) {
        paint = selectedPaint;
      } else if (entity.isConstruction) {
        paint = constructionPaint;
      } else {
        paint = normalPaint;
      }

      entity.render(canvas, paint, scale: scale);

      // Draw control points for selected entities
      if (entity.isSelected) {
        _drawControlPoints(canvas, entity);
      }
    }
  }

  void _drawControlPoints(Canvas canvas, SketchEntity entity) {
    final paint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 / scale;

    final pointSize = 5 / scale;

    for (final point in entity.controlPoints) {
      canvas.drawCircle(Offset(point.x, point.y), pointSize, paint);
      canvas.drawCircle(Offset(point.x, point.y), pointSize, outlinePaint);
    }
  }

  void _drawPreview(Canvas canvas) {
    final preview = tool?.previewEntity;
    if (preview == null) return;

    final previewPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.8)
      ..strokeWidth = 2 / scale
      ..style = PaintingStyle.stroke;

    preview.render(canvas, previewPaint, scale: scale);

    // Draw preview points
    final pointPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    for (final point in tool!.previewPoints) {
      canvas.drawCircle(Offset(point.x, point.y), 4 / scale, pointPaint);
    }
  }

  void _drawSelectionBox(Canvas canvas, SelectTool selectTool) {
    final box = selectTool.selectionBox;
    if (box == null) return;

    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..strokeWidth = 1 / scale
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTRB(box.min.x, box.min.y, box.max.x, box.max.y);
    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, strokePaint);
  }

  void _drawUI(Canvas canvas, Size size) {
    // Draw zoom level indicator
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(scale * 100).toStringAsFixed(0)}%',
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - textPainter.width - 10, 10));

    // Draw entity count
    final countPainter = TextPainter(
      text: TextSpan(
        text: 'Entities: ${document.entityCount}',
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    countPainter.layout();
    countPainter.paint(canvas, Offset(10, size.height - countPainter.height - 10));
  }

  @override
  bool shouldRepaint(SketchPainter oldDelegate) {
    return true; // Always repaint for smooth interaction
  }
}
