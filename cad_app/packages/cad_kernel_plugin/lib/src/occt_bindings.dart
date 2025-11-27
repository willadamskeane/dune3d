import 'dart:ffi';
import 'dart:io';

import 'ffi_helpers.dart';

// Native function type definitions
typedef _DocCreateNative = Pointer<Void> Function();
typedef _DocReleaseNative = Void Function(Pointer<Void>);
typedef _DocReleaseDart = void Function(Pointer<Void>);

typedef _MakeBoxNative = Pointer<Void> Function(
    Pointer<Void>, Double, Double, Double);
typedef _MakeBoxDart = Pointer<Void> Function(
    Pointer<Void>, double, double, double);

typedef _MakeCylinderNative = Pointer<Void> Function(
    Pointer<Void>, Double, Double);
typedef _MakeCylinderDart = Pointer<Void> Function(
    Pointer<Void>, double, double);

typedef _MakeSphereNative = Pointer<Void> Function(Pointer<Void>, Double);
typedef _MakeSphereDart = Pointer<Void> Function(Pointer<Void>, double);

typedef _ExtrudeProfileNative = Pointer<Void> Function(
    Pointer<Void>, Pointer<Void>, Double);
typedef _ExtrudeProfileDart = Pointer<Void> Function(
    Pointer<Void>, Pointer<Void>, double);

typedef _TessellateShapeNative = Uint8 Function(
  Pointer<Void>,
  Double,
  Pointer<Pointer<Float>>,
  Pointer<Pointer<Float>>,
  Pointer<Int32>,
  Pointer<Pointer<Uint32>>,
  Pointer<Int32>,
);
typedef _TessellateShapeDart = int Function(
  Pointer<Void>,
  double,
  Pointer<Pointer<Float>>,
  Pointer<Pointer<Float>>,
  Pointer<Int32>,
  Pointer<Pointer<Uint32>>,
  Pointer<Int32>,
);

typedef _FreeMeshNative = Void Function(
    Pointer<Float>, Pointer<Float>, Pointer<Uint32>);
typedef _FreeMeshDart = void Function(
    Pointer<Float>, Pointer<Float>, Pointer<Uint32>);

typedef _ApplyFilletNative = Uint8 Function(
    Pointer<Void>, Pointer<Void>, Pointer<Int32>, Int32, Double);
typedef _ApplyFilletDart = int Function(
    Pointer<Void>, Pointer<Void>, Pointer<Int32>, int, double);

typedef _ApplyChamferNative = Uint8 Function(
    Pointer<Void>, Pointer<Void>, Pointer<Int32>, Int32, Double);
typedef _ApplyChamferDart = int Function(
    Pointer<Void>, Pointer<Void>, Pointer<Int32>, int, double);

typedef _BooleanOpNative = Pointer<Void> Function(
    Pointer<Void>, Pointer<Void>, Pointer<Void>);
typedef _BooleanOpDart = Pointer<Void> Function(
    Pointer<Void>, Pointer<Void>, Pointer<Void>);

/// FFI bindings to the OCCT (OpenCASCADE) kernel.
class OcctBindings {
  OcctBindings._(DynamicLibrary lib) : _lib = lib {
    _initBindings();
  }

  static OcctBindings? _instance;

  /// Get the singleton instance of OCCT bindings.
  static OcctBindings get instance {
    _instance ??= OcctBindings._(_openLibrary());
    return _instance!;
  }

  final DynamicLibrary _lib;

  // Function pointers
  late final _DocCreateNative _docCreate;
  late final _DocReleaseDart _docRelease;
  late final _MakeBoxDart _makeBox;
  late final _MakeCylinderDart _makeCylinder;
  late final _MakeSphereDart _makeSphere;
  late final _ExtrudeProfileDart _extrudeProfile;
  late final _TessellateShapeDart _tessellateShape;
  late final _FreeMeshDart _freeMesh;
  late final _ApplyFilletDart _applyFillet;
  late final _ApplyChamferDart _applyChamfer;
  late final _BooleanOpDart _booleanUnion;
  late final _BooleanOpDart _booleanCut;
  late final _BooleanOpDart _booleanIntersect;

  static DynamicLibrary _openLibrary() {
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
    _docCreate = _lib
        .lookupFunction<_DocCreateNative, _DocCreateNative>('occt_doc_create');

    _docRelease = _lib
        .lookupFunction<_DocReleaseNative, _DocReleaseDart>('occt_doc_release');

    _makeBox =
        _lib.lookupFunction<_MakeBoxNative, _MakeBoxDart>('occt_make_box');

    _makeCylinder = _lib.lookupFunction<_MakeCylinderNative, _MakeCylinderDart>(
        'occt_make_cylinder');

    _makeSphere = _lib
        .lookupFunction<_MakeSphereNative, _MakeSphereDart>('occt_make_sphere');

    _extrudeProfile =
        _lib.lookupFunction<_ExtrudeProfileNative, _ExtrudeProfileDart>(
            'occt_extrude_profile');

    _tessellateShape =
        _lib.lookupFunction<_TessellateShapeNative, _TessellateShapeDart>(
            'occt_tessellate_shape');

    _freeMesh =
        _lib.lookupFunction<_FreeMeshNative, _FreeMeshDart>('occt_free_mesh');

    _applyFillet = _lib
        .lookupFunction<_ApplyFilletNative, _ApplyFilletDart>('occt_apply_fillet');

    _applyChamfer =
        _lib.lookupFunction<_ApplyChamferNative, _ApplyChamferDart>(
            'occt_apply_chamfer');

    _booleanUnion = _lib
        .lookupFunction<_BooleanOpNative, _BooleanOpDart>('occt_boolean_union');

    _booleanCut = _lib
        .lookupFunction<_BooleanOpNative, _BooleanOpDart>('occt_boolean_cut');

    _booleanIntersect =
        _lib.lookupFunction<_BooleanOpNative, _BooleanOpDart>(
            'occt_boolean_intersect');
  }

  /// Create a new OCCT document.
  Pointer<Void> docCreate() => _docCreate();

  /// Release an OCCT document.
  void docRelease(Pointer<Void> docHandle) => _docRelease(docHandle);

  /// Create a box primitive.
  Pointer<Void> makeBox(
    Pointer<Void> docHandle,
    double dx,
    double dy,
    double dz,
  ) =>
      _makeBox(docHandle, dx, dy, dz);

  /// Create a cylinder primitive.
  Pointer<Void> makeCylinder(
    Pointer<Void> docHandle,
    double radius,
    double height,
  ) =>
      _makeCylinder(docHandle, radius, height);

  /// Create a sphere primitive.
  Pointer<Void> makeSphere(
    Pointer<Void> docHandle,
    double radius,
  ) =>
      _makeSphere(docHandle, radius);

  /// Extrude a profile wire.
  Pointer<Void> extrudeProfile(
    Pointer<Void> docHandle,
    Pointer<Void> profileWire,
    double height,
  ) =>
      _extrudeProfile(docHandle, profileWire, height);

  /// Tessellate a shape into triangles.
  bool tessellateShape(
    Pointer<Void> shapeHandle,
    double deflection,
    Pointer<Pointer<Float>> outVertices,
    Pointer<Pointer<Float>> outNormals,
    Pointer<Int32> outVertexCount,
    Pointer<Pointer<Uint32>> outIndices,
    Pointer<Int32> outIndexCount,
  ) {
    return _tessellateShape(
          shapeHandle,
          deflection,
          outVertices,
          outNormals,
          outVertexCount,
          outIndices,
          outIndexCount,
        ) !=
        0;
  }

  /// Free tessellation mesh data.
  void freeMesh(
    Pointer<Float> vertices,
    Pointer<Float> normals,
    Pointer<Uint32> indices,
  ) =>
      _freeMesh(vertices, normals, indices);

  /// Apply fillet to edges.
  bool applyFillet(
    Pointer<Void> docHandle,
    Pointer<Void> bodyHandle,
    Pointer<Int32> edgeIds,
    int edgeCount,
    double radius,
  ) {
    return _applyFillet(docHandle, bodyHandle, edgeIds, edgeCount, radius) != 0;
  }

  /// Apply chamfer to edges.
  bool applyChamfer(
    Pointer<Void> docHandle,
    Pointer<Void> bodyHandle,
    Pointer<Int32> edgeIds,
    int edgeCount,
    double distance,
  ) {
    return _applyChamfer(docHandle, bodyHandle, edgeIds, edgeCount, distance) !=
        0;
  }

  /// Boolean union of two shapes.
  Pointer<Void> booleanUnion(
    Pointer<Void> docHandle,
    Pointer<Void> shapeA,
    Pointer<Void> shapeB,
  ) =>
      _booleanUnion(docHandle, shapeA, shapeB);

  /// Boolean cut (A - B).
  Pointer<Void> booleanCut(
    Pointer<Void> docHandle,
    Pointer<Void> shapeA,
    Pointer<Void> shapeB,
  ) =>
      _booleanCut(docHandle, shapeA, shapeB);

  /// Boolean intersection.
  Pointer<Void> booleanIntersect(
    Pointer<Void> docHandle,
    Pointer<Void> shapeA,
    Pointer<Void> shapeB,
  ) =>
      _booleanIntersect(docHandle, shapeA, shapeB);

  /// Allocate an integer array for edge IDs.
  Pointer<Int32> mallocIntArray(int length) => FfiHelpers.mallocIntArray(length);

  /// Free an integer array.
  void freeIntArray(Pointer<Int32> ptr) => FfiHelpers.freeIntArray(ptr);
}
