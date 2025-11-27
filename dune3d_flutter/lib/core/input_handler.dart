import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'geometry.dart';

/// Type of input device being used
enum InputDevice {
  finger,
  stylus,
  mouse,
  unknown,
}

/// Input mode determines how touch/stylus input is interpreted
enum InputMode {
  draw,      // Stylus/mouse draws, finger pans
  navigate,  // All input navigates (pan/zoom/rotate)
  select,    // All input selects
}

/// Represents a single pointer input with rich metadata
class PointerInput {
  final int pointerId;
  final Vec2 position;
  final Vec2 screenPosition;
  final InputDevice device;
  final double pressure;
  final double tilt;
  final double rotation;
  final bool isHovering;
  final bool isPrimaryButton;
  final bool isSecondaryButton;
  final DateTime timestamp;

  const PointerInput({
    required this.pointerId,
    required this.position,
    required this.screenPosition,
    required this.device,
    this.pressure = 1.0,
    this.tilt = 0.0,
    this.rotation = 0.0,
    this.isHovering = false,
    this.isPrimaryButton = true,
    this.isSecondaryButton = false,
    required this.timestamp,
  });

  /// Get stroke width based on pressure (for stylus)
  double get strokeWidth {
    if (device == InputDevice.stylus) {
      return 1.0 + (pressure * 3.0); // 1-4 range
    }
    return 2.0;
  }

  /// Whether this is a precise input (stylus or mouse)
  bool get isPrecise => device == InputDevice.stylus || device == InputDevice.mouse;

  /// Whether this is a touch input (finger)
  bool get isTouch => device == InputDevice.finger;

  @override
  String toString() => 'PointerInput($device, $position, pressure: $pressure)';
}

/// Detects input device type from pointer events
InputDevice detectInputDevice(PointerEvent event) {
  if (event.kind == PointerDeviceKind.stylus ||
      event.kind == PointerDeviceKind.invertedStylus) {
    return InputDevice.stylus;
  } else if (event.kind == PointerDeviceKind.touch) {
    return InputDevice.finger;
  } else if (event.kind == PointerDeviceKind.mouse) {
    return InputDevice.mouse;
  }
  return InputDevice.unknown;
}

/// Handles multi-touch gestures and input device differentiation
class InputHandler {
  final Function(Vec2 screenToWorld) screenToWorld;
  final Function(PointerInput) onDrawStart;
  final Function(PointerInput) onDrawMove;
  final Function(PointerInput) onDrawEnd;
  final Function(PointerInput)? onHover;
  final Function(Vec2 delta) onPan;
  final Function(double scale, Vec2 focalPoint) onZoom;
  final Function(double angle)? onRotate;
  final Function()? onDoubleTap;
  final Function(Vec2 position)? onLongPress;

  InputMode _mode = InputMode.draw;
  final Map<int, PointerInput> _activePointers = {};
  Vec2? _lastFocalPoint;
  double? _lastScale;
  double? _lastRotation;
  bool _isGesturing = false;
  int? _drawPointerId;
  PointerInput? _hoverPointer;

  InputHandler({
    required this.screenToWorld,
    required this.onDrawStart,
    required this.onDrawMove,
    required this.onDrawEnd,
    this.onHover,
    required this.onPan,
    required this.onZoom,
    this.onRotate,
    this.onDoubleTap,
    this.onLongPress,
  });

  InputMode get mode => _mode;
  set mode(InputMode value) => _mode = value;

  bool get isDrawing => _drawPointerId != null;
  PointerInput? get hoverPointer => _hoverPointer;

  PointerInput _createPointerInput(PointerEvent event) {
    final screenPos = Vec2(event.position.dx, event.position.dy);
    return PointerInput(
      pointerId: event.pointer,
      position: screenToWorld(screenPos),
      screenPosition: screenPos,
      device: detectInputDevice(event),
      pressure: event.pressure,
      tilt: event.tilt,
      rotation: event.orientation,
      isHovering: event is PointerHoverEvent,
      isPrimaryButton: event.buttons & kPrimaryButton != 0,
      isSecondaryButton: event.buttons & kSecondaryButton != 0,
      timestamp: DateTime.now(),
    );
  }

  void handlePointerDown(PointerDownEvent event) {
    final input = _createPointerInput(event);
    _activePointers[event.pointer] = input;

    // Determine action based on device and mode
    if (_shouldDraw(input)) {
      _drawPointerId = event.pointer;
      onDrawStart(input);
    } else if (_activePointers.length == 1) {
      // Single finger - prepare for potential pan
      _lastFocalPoint = input.screenPosition;
    }

    // Multi-touch gesture detection
    if (_activePointers.length >= 2) {
      _isGesturing = true;
      _updateGestureBaseline();
    }
  }

  void handlePointerMove(PointerMoveEvent event) {
    final input = _createPointerInput(event);
    _activePointers[event.pointer] = input;

    if (_drawPointerId == event.pointer) {
      onDrawMove(input);
      return;
    }

    if (_isGesturing && _activePointers.length >= 2) {
      _handleMultiTouchGesture();
    } else if (_activePointers.length == 1 && !isDrawing) {
      // Single touch pan
      if (_lastFocalPoint != null) {
        final delta = input.screenPosition - _lastFocalPoint!;
        onPan(delta);
      }
      _lastFocalPoint = input.screenPosition;
    }
  }

  void handlePointerUp(PointerUpEvent event) {
    final input = _createPointerInput(event);

    if (_drawPointerId == event.pointer) {
      onDrawEnd(input);
      _drawPointerId = null;
    }

    _activePointers.remove(event.pointer);

    if (_activePointers.length < 2) {
      _isGesturing = false;
      _lastScale = null;
      _lastRotation = null;
    }

    if (_activePointers.isEmpty) {
      _lastFocalPoint = null;
    } else if (_activePointers.length == 1) {
      _lastFocalPoint = _activePointers.values.first.screenPosition;
    }
  }

  void handlePointerCancel(PointerCancelEvent event) {
    if (_drawPointerId == event.pointer) {
      _drawPointerId = null;
    }
    _activePointers.remove(event.pointer);
    if (_activePointers.isEmpty) {
      _isGesturing = false;
      _lastFocalPoint = null;
      _lastScale = null;
      _lastRotation = null;
    }
  }

  void handlePointerHover(PointerHoverEvent event) {
    final input = _createPointerInput(event);
    _hoverPointer = input;
    onHover?.call(input);
  }

  void handlePointerExit(PointerExitEvent event) {
    _hoverPointer = null;
  }

  void handleScaleStart(ScaleStartDetails details) {
    // Handled by pointer events
  }

  void handleScaleUpdate(ScaleUpdateDetails details) {
    // Handle pinch zoom from gesture detector as backup
    if (!_isGesturing && _activePointers.isEmpty) {
      if (details.scale != 1.0) {
        final focalPoint = Vec2(details.focalPoint.dx, details.focalPoint.dy);
        onZoom(details.scale, focalPoint);
      }
    }
  }

  bool _shouldDraw(PointerInput input) {
    if (_mode == InputMode.navigate) return false;
    if (_mode == InputMode.select) return true;

    // In draw mode: stylus/mouse draws, finger pans
    return input.isPrecise;
  }

  void _updateGestureBaseline() {
    if (_activePointers.length < 2) return;

    final pointers = _activePointers.values.toList();
    _lastFocalPoint = _calculateFocalPoint(pointers);
    _lastScale = _calculateScale(pointers);
    _lastRotation = _calculateRotation(pointers);
  }

  void _handleMultiTouchGesture() {
    if (_activePointers.length < 2) return;

    final pointers = _activePointers.values.toList();
    final focalPoint = _calculateFocalPoint(pointers);
    final scale = _calculateScale(pointers);
    final rotation = _calculateRotation(pointers);

    // Pan
    if (_lastFocalPoint != null) {
      final delta = focalPoint - _lastFocalPoint!;
      onPan(delta);
    }

    // Zoom
    if (_lastScale != null && _lastScale! > 0) {
      final scaleChange = scale / _lastScale!;
      if ((scaleChange - 1.0).abs() > 0.01) {
        onZoom(scaleChange, focalPoint);
      }
    }

    // Rotate (for 3D view)
    if (_lastRotation != null && onRotate != null) {
      final rotationDelta = rotation - _lastRotation!;
      if (rotationDelta.abs() > 0.01) {
        onRotate!(rotationDelta);
      }
    }

    _lastFocalPoint = focalPoint;
    _lastScale = scale;
    _lastRotation = rotation;
  }

  Vec2 _calculateFocalPoint(List<PointerInput> pointers) {
    double x = 0, y = 0;
    for (final p in pointers) {
      x += p.screenPosition.x;
      y += p.screenPosition.y;
    }
    return Vec2(x / pointers.length, y / pointers.length);
  }

  double _calculateScale(List<PointerInput> pointers) {
    if (pointers.length < 2) return 1.0;
    return pointers[0].screenPosition.distanceTo(pointers[1].screenPosition);
  }

  double _calculateRotation(List<PointerInput> pointers) {
    if (pointers.length < 2) return 0.0;
    final delta = pointers[1].screenPosition - pointers[0].screenPosition;
    return delta.angle;
  }
}

/// Gesture settings for tablet optimization
class GestureSettings {
  /// Minimum movement to start a draw operation (in screen pixels)
  static const double drawThreshold = 3.0;

  /// Minimum movement for pan (in screen pixels)
  static const double panThreshold = 5.0;

  /// Time window for double tap detection
  static const Duration doubleTapWindow = Duration(milliseconds: 300);

  /// Time for long press detection
  static const Duration longPressDuration = Duration(milliseconds: 500);

  /// Touch target size for tablet (meets accessibility guidelines)
  static const double touchTargetSize = 48.0;

  /// Snap distance for geometry snapping
  static const double snapDistance = 12.0;

  /// Hover delay before showing tooltips
  static const Duration hoverDelay = Duration(milliseconds: 400);
}
