import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Types of pointer input devices.
enum PointerType {
  touch,
  stylus,
  mouse,
  unknown,
}

/// Represents a stylus input event with extended data.
class StylusEvent {
  final Offset position;
  final double pressure;
  final double tilt;
  final double orientation;
  final PointerType pointerType;
  final int pointerId;
  final DateTime timestamp;

  const StylusEvent({
    required this.position,
    this.pressure = 1.0,
    this.tilt = 0.0,
    this.orientation = 0.0,
    this.pointerType = PointerType.touch,
    required this.pointerId,
    required this.timestamp,
  });

  factory StylusEvent.fromPointerEvent(PointerEvent event) {
    PointerType type;
    if (event.kind == PointerDeviceKind.stylus) {
      type = PointerType.stylus;
    } else if (event.kind == PointerDeviceKind.touch) {
      type = PointerType.touch;
    } else if (event.kind == PointerDeviceKind.mouse) {
      type = PointerType.mouse;
    } else {
      type = PointerType.unknown;
    }

    return StylusEvent(
      position: event.localPosition,
      pressure: event.pressure,
      tilt: event.tilt,
      orientation: event.orientation,
      pointerType: type,
      pointerId: event.pointer,
      timestamp: DateTime.now(),
    );
  }
}

/// Current gesture state.
enum GestureState {
  idle,
  panning,
  orbiting,
  zooming,
  drawing,
  selecting,
}

/// Configuration for gesture handling.
class GestureConfig {
  /// Minimum movement before recognizing a gesture.
  final double dragThreshold;

  /// Time threshold for distinguishing tap from drag.
  final Duration tapTimeout;

  /// Enable palm rejection for stylus input.
  final bool palmRejection;

  /// Minimum contact size to consider as palm.
  final double palmSizeThreshold;

  /// Pressure threshold for stylus drawing.
  final double drawPressureThreshold;

  /// Enable inertia scrolling.
  final bool inertiaEnabled;

  /// Inertia decay factor (0-1).
  final double inertiaDecay;

  const GestureConfig({
    this.dragThreshold = 8.0,
    this.tapTimeout = const Duration(milliseconds: 200),
    this.palmRejection = true,
    this.palmSizeThreshold = 30.0,
    this.drawPressureThreshold = 0.05,
    this.inertiaEnabled = true,
    this.inertiaDecay = 0.95,
  });
}

/// Callback types for gesture events.
typedef OnTapCallback = void Function(Offset position);
typedef OnDoubleTapCallback = void Function(Offset position);
typedef OnLongPressCallback = void Function(Offset position);
typedef OnPanCallback = void Function(Offset delta);
typedef OnOrbitCallback = void Function(double deltaAzimuth, double deltaElevation);
typedef OnZoomCallback = void Function(double factor);
typedef OnDrawCallback = void Function(StylusEvent event);
typedef OnDrawStartCallback = void Function(StylusEvent event);
typedef OnDrawEndCallback = void Function();

/// Advanced gesture handler for CAD applications.
class CadGestureHandler {
  final GestureConfig config;

  // State
  GestureState _state = GestureState.idle;
  final Map<int, StylusEvent> _activePointers = {};
  Offset? _lastFocalPoint;
  double? _lastPointerDistance;
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;
  Offset? _velocity;

  // Callbacks
  OnTapCallback? onTap;
  OnDoubleTapCallback? onDoubleTap;
  OnLongPressCallback? onLongPress;
  OnPanCallback? onPan;
  OnOrbitCallback? onOrbit;
  OnZoomCallback? onZoom;
  OnDrawCallback? onDraw;
  OnDrawStartCallback? onDrawStart;
  OnDrawEndCallback? onDrawEnd;

  CadGestureHandler({
    this.config = const GestureConfig(),
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onPan,
    this.onOrbit,
    this.onZoom,
    this.onDraw,
    this.onDrawStart,
    this.onDrawEnd,
  });

  GestureState get state => _state;
  int get pointerCount => _activePointers.length;

  /// Handle pointer down event.
  void handlePointerDown(PointerDownEvent event) {
    final stylusEvent = StylusEvent.fromPointerEvent(event);

    // Palm rejection check
    if (config.palmRejection && _isPalmContact(event)) {
      return;
    }

    _activePointers[event.pointer] = stylusEvent;

    if (_activePointers.length == 1) {
      _lastFocalPoint = event.localPosition;

      // Check for stylus drawing
      if (stylusEvent.pointerType == PointerType.stylus &&
          stylusEvent.pressure > config.drawPressureThreshold) {
        _state = GestureState.drawing;
        onDrawStart?.call(stylusEvent);
      }
    } else if (_activePointers.length == 2) {
      // Two-finger gesture starting
      _state = GestureState.panning;
      _lastPointerDistance = _calculatePointerDistance();
      _lastFocalPoint = _calculateFocalPoint();
    }
  }

  /// Handle pointer move event.
  void handlePointerMove(PointerMoveEvent event) {
    if (!_activePointers.containsKey(event.pointer)) {
      return;
    }

    final stylusEvent = StylusEvent.fromPointerEvent(event);
    _activePointers[event.pointer] = stylusEvent;

    switch (_state) {
      case GestureState.idle:
        // Check if we should start a gesture
        if (_lastFocalPoint != null) {
          final delta = event.localPosition - _lastFocalPoint!;
          if (delta.distance > config.dragThreshold) {
            if (_activePointers.length == 1) {
              // Single pointer - orbit or select
              final pointerType = stylusEvent.pointerType;
              if (pointerType == PointerType.mouse) {
                _state = GestureState.orbiting;
              } else {
                _state = GestureState.orbiting;
              }
            }
          }
        }
        break;

      case GestureState.drawing:
        onDraw?.call(stylusEvent);
        break;

      case GestureState.panning:
        if (_activePointers.length >= 2) {
          final focalPoint = _calculateFocalPoint();
          final distance = _calculatePointerDistance();

          // Calculate pan
          if (_lastFocalPoint != null) {
            final delta = focalPoint - _lastFocalPoint!;
            onPan?.call(delta);
          }

          // Calculate zoom
          if (_lastPointerDistance != null && distance > 0) {
            final factor = distance / _lastPointerDistance!;
            if ((factor - 1.0).abs() > 0.01) {
              onZoom?.call(factor);
            }
          }

          _lastFocalPoint = focalPoint;
          _lastPointerDistance = distance;
        }
        break;

      case GestureState.orbiting:
        if (_lastFocalPoint != null) {
          final delta = event.localPosition - _lastFocalPoint!;
          final sensitivity = 0.005;
          onOrbit?.call(delta.dx * sensitivity, delta.dy * sensitivity);
        }
        _lastFocalPoint = event.localPosition;
        break;

      case GestureState.zooming:
        // Handled in panning state with pinch
        break;

      case GestureState.selecting:
        // Update selection box
        break;
    }
  }

  /// Handle pointer up event.
  void handlePointerUp(PointerUpEvent event) {
    final wasDrawing = _state == GestureState.drawing;

    _activePointers.remove(event.pointer);

    if (_activePointers.isEmpty) {
      if (wasDrawing) {
        onDrawEnd?.call();
      } else if (_state == GestureState.idle && _lastFocalPoint != null) {
        // This was a tap
        final now = DateTime.now();
        final tapPosition = event.localPosition;

        // Check for double tap
        if (_lastTapTime != null &&
            _lastTapPosition != null &&
            now.difference(_lastTapTime!) < const Duration(milliseconds: 300) &&
            (tapPosition - _lastTapPosition!).distance < 30) {
          onDoubleTap?.call(tapPosition);
          _lastTapTime = null;
          _lastTapPosition = null;
        } else {
          onTap?.call(tapPosition);
          _lastTapTime = now;
          _lastTapPosition = tapPosition;
        }
      }

      _state = GestureState.idle;
      _lastFocalPoint = null;
      _lastPointerDistance = null;
    } else if (_activePointers.length == 1) {
      // Transition from multi-touch to single touch
      _state = GestureState.orbiting;
      _lastFocalPoint = _activePointers.values.first.position;
    }
  }

  /// Handle pointer cancel event.
  void handlePointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);

    if (_state == GestureState.drawing) {
      onDrawEnd?.call();
    }

    if (_activePointers.isEmpty) {
      _state = GestureState.idle;
      _lastFocalPoint = null;
      _lastPointerDistance = null;
    }
  }

  /// Handle scroll event (mouse wheel).
  void handleScroll(PointerScrollEvent event) {
    final factor = 1.0 - event.scrollDelta.dy * 0.001;
    onZoom?.call(factor.clamp(0.5, 2.0));
  }

  /// Check if contact is likely a palm.
  bool _isPalmContact(PointerDownEvent event) {
    // On devices that support it, check contact size
    if (event.size > 0 && event.size > config.palmSizeThreshold) {
      return true;
    }

    // Check for very large radius major
    if (event.radiusMajor > config.palmSizeThreshold) {
      return true;
    }

    return false;
  }

  /// Calculate focal point of all active pointers.
  Offset _calculateFocalPoint() {
    if (_activePointers.isEmpty) return Offset.zero;

    var sum = Offset.zero;
    for (final pointer in _activePointers.values) {
      sum += pointer.position;
    }
    return sum / _activePointers.length.toDouble();
  }

  /// Calculate distance between first two pointers.
  double _calculatePointerDistance() {
    if (_activePointers.length < 2) return 0;

    final pointers = _activePointers.values.toList();
    return (pointers[0].position - pointers[1].position).distance;
  }

  /// Reset gesture state.
  void reset() {
    _state = GestureState.idle;
    _activePointers.clear();
    _lastFocalPoint = null;
    _lastPointerDistance = null;
    _velocity = null;
  }
}

/// Widget wrapper for CAD gesture handling.
class CadGestureDetector extends StatefulWidget {
  final Widget child;
  final GestureConfig config;
  final OnTapCallback? onTap;
  final OnDoubleTapCallback? onDoubleTap;
  final OnLongPressCallback? onLongPress;
  final OnPanCallback? onPan;
  final OnOrbitCallback? onOrbit;
  final OnZoomCallback? onZoom;
  final OnDrawCallback? onDraw;
  final OnDrawStartCallback? onDrawStart;
  final OnDrawEndCallback? onDrawEnd;

  const CadGestureDetector({
    super.key,
    required this.child,
    this.config = const GestureConfig(),
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onPan,
    this.onOrbit,
    this.onZoom,
    this.onDraw,
    this.onDrawStart,
    this.onDrawEnd,
  });

  @override
  State<CadGestureDetector> createState() => _CadGestureDetectorState();
}

class _CadGestureDetectorState extends State<CadGestureDetector> {
  late CadGestureHandler _handler;

  @override
  void initState() {
    super.initState();
    _updateHandler();
  }

  @override
  void didUpdateWidget(CadGestureDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateHandler();
  }

  void _updateHandler() {
    _handler = CadGestureHandler(
      config: widget.config,
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      onLongPress: widget.onLongPress,
      onPan: widget.onPan,
      onOrbit: widget.onOrbit,
      onZoom: widget.onZoom,
      onDraw: widget.onDraw,
      onDrawStart: widget.onDrawStart,
      onDrawEnd: widget.onDrawEnd,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handler.handlePointerDown,
      onPointerMove: _handler.handlePointerMove,
      onPointerUp: _handler.handlePointerUp,
      onPointerCancel: _handler.handlePointerCancel,
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _handler.handleScroll(event);
        }
      },
      child: widget.child,
    );
  }
}
