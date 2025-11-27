import 'package:flutter/foundation.dart';
import 'package:cad_kernel_plugin/cad_kernel_plugin.dart';

import 'modeling_service.dart';
import 'tessellation_service.dart';

/// Central entry point for native kernel FFI operations.
///
/// This singleton provides access to OCCT and ShapeOp bindings,
/// keeping the rest of the app decoupled from FFI details.
class KernelBridge {
  KernelBridge._internal();

  static final KernelBridge instance = KernelBridge._internal();

  /// Access to OCCT kernel bindings.
  OcctBindings get occt => OcctBindings.instance;

  /// Access to ShapeOp constraint solver bindings.
  ShapeOpBindings get shapeOp => ShapeOpBindings.instance;

  late final ModelingService modelingService = ModelingService(
    occt: occt,
    tessellationService: tessellationService,
  );

  late final TessellationService tessellationService = TessellationService(
    occt: occt,
  );

  bool _initialized = false;

  /// Initialize the kernel bridge.
  ///
  /// Should be called once at app startup.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kDebugMode) {
        // Perform a smoke test FFI call
        final docHandle = occt.docCreate();
        occt.docRelease(docHandle);
        debugPrint('KernelBridge: OCCT smoke test passed');
      }
      _initialized = true;
    } catch (e) {
      debugPrint('KernelBridge: Failed to initialize - $e');
      // In development, we may not have the native library yet
      if (!kDebugMode) rethrow;
    }
  }

  /// Check if the kernel is available.
  bool get isAvailable => _initialized;
}
