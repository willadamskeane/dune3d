import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// Helper utilities for FFI operations.
class FfiHelpers {
  FfiHelpers._();

  /// Allocate an array of 32-bit integers.
  static Pointer<Int32> mallocIntArray(int length) => calloc<Int32>(length);

  /// Free an integer array.
  static void freeIntArray(Pointer<Int32> ptr) {
    calloc.free(ptr);
  }

  /// Allocate an array of doubles.
  static Pointer<Double> mallocDoubleArray(int length) =>
      calloc<Double>(length);

  /// Free a double array.
  static void freeDoubleArray(Pointer<Double> ptr) {
    calloc.free(ptr);
  }

  /// Allocate an array of floats.
  static Pointer<Float> mallocFloatArray(int length) => calloc<Float>(length);

  /// Free a float array.
  static void freeFloatArray(Pointer<Float> ptr) {
    calloc.free(ptr);
  }

  /// Convert a Dart string to a native UTF-8 string.
  static Pointer<Utf8> toNativeString(String str) => str.toNativeUtf8();

  /// Free a native string.
  static void freeNativeString(Pointer<Utf8> ptr) {
    calloc.free(ptr);
  }
}

/// Extension to export calloc for direct use.
export 'package:ffi/ffi.dart' show calloc;
