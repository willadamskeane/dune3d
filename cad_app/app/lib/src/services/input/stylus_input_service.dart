import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cad_input_plugin/cad_input_plugin.dart' as plugin;

/// Represents a single stylus input point with pressure and tilt.
class StylusPoint {
  final Offset position;
  final double pressure;
  final double? tiltX;
  final double? tiltY;
  final DateTime timestamp;
  final bool isHistorical;

  const StylusPoint({
    required this.position,
    required this.pressure,
    this.tiltX,
    this.tiltY,
    required this.timestamp,
    this.isHistorical = false,
  });

  factory StylusPoint.fromJson(Map<String, dynamic> json) {
    return StylusPoint(
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
      pressure: (json['pressure'] as num?)?.toDouble() ?? 0.5,
      tiltX: (json['tiltX'] as num?)?.toDouble(),
      tiltY: (json['tiltY'] as num?)?.toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['time'] as num).toInt(),
      ),
      isHistorical: json['historical'] as bool? ?? false,
    );
  }

  @override
  String toString() =>
      'StylusPoint(pos: $position, pressure: $pressure, time: $timestamp)';
}

/// Event types for stylus input.
enum StylusEventType {
  down,
  move,
  up,
  cancel,
}

/// A complete stylus event with type and point data.
class StylusEvent {
  final StylusEventType type;
  final StylusPoint point;
  final int pointerId;

  const StylusEvent({
    required this.type,
    required this.point,
    this.pointerId = 0,
  });
}

/// Callback type for stylus events.
typedef StylusEventCallback = void Function(StylusEvent event);

/// Service for handling raw stylus input from the native platform.
///
/// This service connects to the `cad_input_plugin` and provides a
/// high-level stream of stylus events to the app.
class StylusInputService {
  StylusInputService._internal();

  static final StylusInputService instance = StylusInputService._internal();

  final List<StylusEventCallback> _listeners = [];
  StreamSubscription<dynamic>? _subscription;
  bool _initialized = false;

  /// Initialize the stylus input service.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await plugin.initializeInput();
      _subscription = plugin.stylusEventStream.listen(_handleNativeEvent);
      _initialized = true;
    } catch (e) {
      debugPrint('StylusInputService: Failed to initialize - $e');
    }
  }

  /// Dispose of resources.
  void dispose() {
    _subscription?.cancel();
    _listeners.clear();
    _initialized = false;
  }

  /// Add a listener for stylus events.
  void addListener(StylusEventCallback callback) {
    _listeners.add(callback);
  }

  /// Remove a listener.
  void removeListener(StylusEventCallback callback) {
    _listeners.remove(callback);
  }

  /// Check if service is available.
  bool get isAvailable => _initialized;

  void _handleNativeEvent(dynamic event) {
    if (event is! String) return;

    try {
      final json = jsonDecode(event) as Map<String, dynamic>;
      final point = StylusPoint.fromJson(json);

      // Determine event type from action field if present
      final action = json['action'] as int? ?? 0;
      final type = _mapActionToType(action);

      final stylusEvent = StylusEvent(
        type: type,
        point: point,
        pointerId: json['pointerId'] as int? ?? 0,
      );

      _notifyListeners(stylusEvent);
    } catch (e) {
      debugPrint('StylusInputService: Error parsing event - $e');
    }
  }

  StylusEventType _mapActionToType(int action) {
    // Android MotionEvent action codes
    return switch (action) {
      0 => StylusEventType.down, // ACTION_DOWN
      1 => StylusEventType.up, // ACTION_UP
      2 => StylusEventType.move, // ACTION_MOVE
      3 => StylusEventType.cancel, // ACTION_CANCEL
      _ => StylusEventType.move,
    };
  }

  void _notifyListeners(StylusEvent event) {
    for (final listener in _listeners) {
      listener(event);
    }
  }

  /// Manually dispatch a stylus event (useful for testing).
  @visibleForTesting
  void dispatchEvent(StylusEvent event) {
    _notifyListeners(event);
  }
}

/// A widget that provides stylus input handling.
///
/// Wrap your sketch canvas with this widget to receive stylus events.
class StylusInputWidget extends StatefulWidget {
  final Widget child;
  final StylusEventCallback? onStylusEvent;

  const StylusInputWidget({
    super.key,
    required this.child,
    this.onStylusEvent,
  });

  @override
  State<StylusInputWidget> createState() => _StylusInputWidgetState();
}

class _StylusInputWidgetState extends State<StylusInputWidget> {
  @override
  void initState() {
    super.initState();
    if (widget.onStylusEvent != null) {
      StylusInputService.instance.addListener(widget.onStylusEvent!);
    }
  }

  @override
  void dispose() {
    if (widget.onStylusEvent != null) {
      StylusInputService.instance.removeListener(widget.onStylusEvent!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
