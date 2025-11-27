import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:vector_math/vector_math_64.dart';

// Native function type definitions
typedef _SolverCreateNative = Pointer<Void> Function();
typedef _SolverDestroyNative = Void Function(Pointer<Void>);
typedef _SolverDestroyDart = void Function(Pointer<Void>);

typedef _AddPointNative = Int32 Function(Pointer<Void>, Double, Double, Uint8);
typedef _AddPointDart = int Function(Pointer<Void>, double, double, int);

typedef _SetPointFixedNative = Void Function(Pointer<Void>, Int32, Uint8);
typedef _SetPointFixedDart = void Function(Pointer<Void>, int, int);

typedef _AddDistanceConstraintNative = Void Function(
    Pointer<Void>, Int32, Int32, Double);
typedef _AddDistanceConstraintDart = void Function(
    Pointer<Void>, int, int, double);

typedef _AddCoincidentConstraintNative = Void Function(
    Pointer<Void>, Int32, Int32);
typedef _AddCoincidentConstraintDart = void Function(Pointer<Void>, int, int);

typedef _AddHorizontalConstraintNative = Void Function(
    Pointer<Void>, Int32, Int32);
typedef _AddHorizontalConstraintDart = void Function(Pointer<Void>, int, int);

typedef _AddVerticalConstraintNative = Void Function(
    Pointer<Void>, Int32, Int32);
typedef _AddVerticalConstraintDart = void Function(Pointer<Void>, int, int);

typedef _AddEqualLengthConstraintNative = Void Function(
    Pointer<Void>, Int32, Int32, Int32, Int32);
typedef _AddEqualLengthConstraintDart = void Function(
    Pointer<Void>, int, int, int, int);

typedef _SolveNative = Void Function(Pointer<Void>, Int32, Pointer<Double>, Int32);
typedef _SolveDart = void Function(Pointer<Void>, int, Pointer<Double>, int);

/// FFI bindings to the ShapeOp constraint solver.
class ShapeOpBindings {
  ShapeOpBindings._(DynamicLibrary lib) : _lib = lib {
    _initBindings();
  }

  static ShapeOpBindings? _instance;

  /// Get the singleton instance of ShapeOp bindings.
  static ShapeOpBindings get instance {
    _instance ??= ShapeOpBindings._(_openLibrary());
    return _instance!;
  }

  final DynamicLibrary _lib;

  // Function pointers
  late final _SolverCreateNative _createSolver;
  late final _SolverDestroyDart _destroySolver;
  late final _AddPointDart _addPoint;
  late final _SetPointFixedDart _setPointFixed;
  late final _AddDistanceConstraintDart _addDistanceConstraint;
  late final _AddCoincidentConstraintDart _addCoincidentConstraint;
  late final _AddHorizontalConstraintDart _addHorizontalConstraint;
  late final _AddVerticalConstraintDart _addVerticalConstraint;
  late final _AddEqualLengthConstraintDart _addEqualLengthConstraint;
  late final _SolveDart _solve;

  static DynamicLibrary _openLibrary() {
    // ShapeOp is typically bundled with OCCT in the same library
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libocct_cad.so');
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libocct_cad.so');
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libocct_cad.dylib');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('occt_cad.dll');
    }
    throw UnsupportedError('Unsupported platform');
  }

  void _initBindings() {
    _createSolver = _lib.lookupFunction<_SolverCreateNative,
        _SolverCreateNative>('shapeop_create');

    _destroySolver = _lib.lookupFunction<_SolverDestroyNative,
        _SolverDestroyDart>('shapeop_destroy');

    _addPoint =
        _lib.lookupFunction<_AddPointNative, _AddPointDart>('shapeop_add_point');

    _setPointFixed = _lib.lookupFunction<_SetPointFixedNative,
        _SetPointFixedDart>('shapeop_set_point_fixed');

    _addDistanceConstraint = _lib.lookupFunction<_AddDistanceConstraintNative,
        _AddDistanceConstraintDart>('shapeop_add_distance_constraint');

    _addCoincidentConstraint = _lib.lookupFunction<
        _AddCoincidentConstraintNative,
        _AddCoincidentConstraintDart>('shapeop_add_coincident_constraint');

    _addHorizontalConstraint = _lib.lookupFunction<
        _AddHorizontalConstraintNative,
        _AddHorizontalConstraintDart>('shapeop_add_horizontal_constraint');

    _addVerticalConstraint = _lib.lookupFunction<_AddVerticalConstraintNative,
        _AddVerticalConstraintDart>('shapeop_add_vertical_constraint');

    _addEqualLengthConstraint = _lib.lookupFunction<
        _AddEqualLengthConstraintNative,
        _AddEqualLengthConstraintDart>('shapeop_add_equal_length_constraint');

    _solve = _lib.lookupFunction<_SolveNative, _SolveDart>('shapeop_solve');
  }

  /// Create a new constraint solver.
  Pointer<Void> createSolver() => _createSolver();

  /// Destroy a constraint solver.
  void destroySolver(Pointer<Void> solver) => _destroySolver(solver);

  /// Add a point to the solver.
  ///
  /// Returns the index of the added point.
  int addPoint(
    Pointer<Void> solver,
    double x,
    double y, {
    required bool isFixed,
  }) =>
      _addPoint(solver, x, y, isFixed ? 1 : 0);

  /// Set whether a point is fixed.
  void setPointFixed(Pointer<Void> solver, int pointIndex, bool isFixed) =>
      _setPointFixed(solver, pointIndex, isFixed ? 1 : 0);

  /// Add a distance constraint between two points.
  void addDistanceConstraint(
    Pointer<Void> solver,
    int p1,
    int p2,
    double distance,
  ) =>
      _addDistanceConstraint(solver, p1, p2, distance);

  /// Add a coincident constraint (two points at same location).
  void addCoincidentConstraint(
    Pointer<Void> solver,
    int p1,
    int p2,
  ) =>
      _addCoincidentConstraint(solver, p1, p2);

  /// Add a horizontal constraint (y coordinates equal).
  void addHorizontalConstraint(
    Pointer<Void> solver,
    int p1,
    int p2,
  ) =>
      _addHorizontalConstraint(solver, p1, p2);

  /// Add a vertical constraint (x coordinates equal).
  void addVerticalConstraint(
    Pointer<Void> solver,
    int p1,
    int p2,
  ) =>
      _addVerticalConstraint(solver, p1, p2);

  /// Add an equal length constraint between two segments.
  void addEqualLengthConstraint(
    Pointer<Void> solver,
    int seg1P1,
    int seg1P2,
    int seg2P1,
    int seg2P2,
  ) =>
      _addEqualLengthConstraint(solver, seg1P1, seg1P2, seg2P1, seg2P2);

  /// Solve constraints and return updated positions.
  ///
  /// Returns a map of point index (as string) to Vector2 position.
  Map<String, Vector2> solveAndFetchPositions(
    Pointer<Void> solver, {
    required int pointCount,
    required int iterations,
  }) {
    final xyCount = pointCount * 2;
    final buffer = calloc<Double>(xyCount);

    try {
      _solve(solver, iterations, buffer, pointCount);

      final positions = <String, Vector2>{};
      for (var i = 0; i < pointCount; i++) {
        final x = buffer[i * 2];
        final y = buffer[i * 2 + 1];
        positions[i.toString()] = Vector2(x, y);
      }

      return positions;
    } finally {
      calloc.free(buffer);
    }
  }
}
