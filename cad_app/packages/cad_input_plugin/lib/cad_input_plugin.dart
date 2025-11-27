library cad_input_plugin;

import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('cad_input_plugin/methods');
const EventChannel _stylusEventChannel =
    EventChannel('cad_input_plugin/stylus_events');

/// Stream of raw stylus events from the native platform.
///
/// Events are JSON-encoded strings containing:
/// - x: X coordinate
/// - y: Y coordinate
/// - pressure: Pressure value (0.0 - 1.0)
/// - tiltX: Tilt X angle (optional)
/// - tiltY: Tilt Y angle (optional)
/// - time: Event timestamp in milliseconds
/// - action: MotionEvent action code
/// - historical: Whether this is a historical point
Stream<dynamic> get stylusEventStream =>
    _stylusEventChannel.receiveBroadcastStream();

/// Initialize the stylus input system.
///
/// Call this once during app startup.
Future<void> initializeInput() async {
  await _channel.invokeMethod('initialize');
}

/// Check if stylus input is supported on this device.
Future<bool> isStylusSupported() async {
  return await _channel.invokeMethod<bool>('isStylusSupported') ?? false;
}

/// Enable or disable stylus-only mode.
///
/// When enabled, only stylus input is processed; touch input is ignored.
Future<void> setStylusOnlyMode(bool enabled) async {
  await _channel.invokeMethod('setStylusOnlyMode', {'enabled': enabled});
}

/// Get the current stylus-only mode setting.
Future<bool> getStylusOnlyMode() async {
  return await _channel.invokeMethod<bool>('getStylusOnlyMode') ?? false;
}

/// Platform view type for embedding the CAD input view.
const String cadInputViewType = 'cad_input_plugin/CadInputView';
