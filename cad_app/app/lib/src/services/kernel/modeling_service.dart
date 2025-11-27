import 'dart:ffi';

import 'package:cad_kernel_plugin/cad_kernel_plugin.dart';

import 'tessellation_service.dart';
import '../../features/viewer/domain/mesh_model.dart';

/// Service for creating and manipulating 3D geometry via OCCT.
class ModelingService {
  final OcctBindings occt;
  final TessellationService tessellationService;

  ModelingService({
    required this.occt,
    required this.tessellationService,
  });

  /// Create a new OCCT document.
  Pointer<Void> createDocument() => occt.docCreate();

  /// Release an OCCT document.
  void releaseDocument(Pointer<Void> docHandle) => occt.docRelease(docHandle);

  /// Create a box primitive.
  ///
  /// Returns the shape handle and tessellated mesh.
  ({Pointer<Void> shapeHandle, Mesh mesh}) createBox({
    required Pointer<Void> docHandle,
    required double dx,
    required double dy,
    required double dz,
    double deflection = 0.1,
  }) {
    final shapeHandle = occt.makeBox(docHandle, dx, dy, dz);
    final mesh = tessellationService.tessellateShape(
      shapeHandle: shapeHandle,
      deflection: deflection,
      meshId: 'box_${DateTime.now().microsecondsSinceEpoch}',
    );
    return (shapeHandle: shapeHandle, mesh: mesh);
  }

  /// Create a cylinder primitive.
  ///
  /// Returns the shape handle and tessellated mesh.
  ({Pointer<Void> shapeHandle, Mesh mesh}) createCylinder({
    required Pointer<Void> docHandle,
    required double radius,
    required double height,
    double deflection = 0.1,
  }) {
    final shapeHandle = occt.makeCylinder(docHandle, radius, height);
    final mesh = tessellationService.tessellateShape(
      shapeHandle: shapeHandle,
      deflection: deflection,
      meshId: 'cylinder_${DateTime.now().microsecondsSinceEpoch}',
    );
    return (shapeHandle: shapeHandle, mesh: mesh);
  }

  /// Create a sphere primitive.
  ///
  /// Returns the shape handle and tessellated mesh.
  ({Pointer<Void> shapeHandle, Mesh mesh}) createSphere({
    required Pointer<Void> docHandle,
    required double radius,
    double deflection = 0.1,
  }) {
    final shapeHandle = occt.makeSphere(docHandle, radius);
    final mesh = tessellationService.tessellateShape(
      shapeHandle: shapeHandle,
      deflection: deflection,
      meshId: 'sphere_${DateTime.now().microsecondsSinceEpoch}',
    );
    return (shapeHandle: shapeHandle, mesh: mesh);
  }

  /// Extrude a profile wire into a solid.
  Pointer<Void> extrudeProfile({
    required Pointer<Void> docHandle,
    required Pointer<Void> profileWire,
    required double height,
  }) {
    return occt.extrudeProfile(docHandle, profileWire, height);
  }

  /// Apply fillet to edges.
  bool applyFillet({
    required Pointer<Void> docHandle,
    required Pointer<Void> bodyHandle,
    required List<int> edgeIds,
    required double radius,
  }) {
    final edgeArray = occt.mallocIntArray(edgeIds.length);
    for (var i = 0; i < edgeIds.length; i++) {
      edgeArray[i] = edgeIds[i];
    }

    final success = occt.applyFillet(
      docHandle,
      bodyHandle,
      edgeArray,
      edgeIds.length,
      radius,
    );

    occt.freeIntArray(edgeArray);
    return success;
  }

  /// Apply chamfer to edges.
  bool applyChamfer({
    required Pointer<Void> docHandle,
    required Pointer<Void> bodyHandle,
    required List<int> edgeIds,
    required double distance,
  }) {
    final edgeArray = occt.mallocIntArray(edgeIds.length);
    for (var i = 0; i < edgeIds.length; i++) {
      edgeArray[i] = edgeIds[i];
    }

    final success = occt.applyChamfer(
      docHandle,
      bodyHandle,
      edgeArray,
      edgeIds.length,
      distance,
    );

    occt.freeIntArray(edgeArray);
    return success;
  }

  /// Perform boolean union of two shapes.
  Pointer<Void> booleanUnion({
    required Pointer<Void> docHandle,
    required Pointer<Void> shapeA,
    required Pointer<Void> shapeB,
  }) {
    return occt.booleanUnion(docHandle, shapeA, shapeB);
  }

  /// Perform boolean subtraction (A - B).
  Pointer<Void> booleanCut({
    required Pointer<Void> docHandle,
    required Pointer<Void> shapeA,
    required Pointer<Void> shapeB,
  }) {
    return occt.booleanCut(docHandle, shapeA, shapeB);
  }

  /// Perform boolean intersection.
  Pointer<Void> booleanIntersect({
    required Pointer<Void> docHandle,
    required Pointer<Void> shapeA,
    required Pointer<Void> shapeB,
  }) {
    return occt.booleanIntersect(docHandle, shapeA, shapeB);
  }
}
