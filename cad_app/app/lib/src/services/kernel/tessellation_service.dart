import 'dart:ffi';

import 'package:cad_kernel_plugin/cad_kernel_plugin.dart';
import 'package:ffi/ffi.dart';

import '../../features/viewer/domain/mesh_model.dart';

/// Service for tessellating OCCT shapes into triangle meshes.
class TessellationService {
  final OcctBindings occt;

  TessellationService({required this.occt});

  /// Tessellate a shape into a triangle mesh.
  ///
  /// [shapeHandle] - Handle to the OCCT shape.
  /// [deflection] - Maximum deviation from the true surface. Lower values
  ///                produce higher quality meshes.
  /// [meshId] - Unique identifier for the resulting mesh.
  Mesh tessellateShape({
    required Pointer<Void> shapeHandle,
    required double deflection,
    required String meshId,
  }) {
    final verticesPtrPtr = calloc<Pointer<Float>>();
    final normalsPtrPtr = calloc<Pointer<Float>>();
    final indicesPtrPtr = calloc<Pointer<Uint32>>();
    final vertexCountPtr = calloc<Int32>();
    final indexCountPtr = calloc<Int32>();

    try {
      final ok = occt.tessellateShape(
        shapeHandle,
        deflection,
        verticesPtrPtr,
        normalsPtrPtr,
        vertexCountPtr,
        indicesPtrPtr,
        indexCountPtr,
      );

      if (!ok) {
        throw TessellationException('Tessellation failed for shape $meshId');
      }

      final vertexCount = vertexCountPtr.value;
      final indexCount = indexCountPtr.value;

      final verticesPtr = verticesPtrPtr.value;
      final normalsPtr = normalsPtrPtr.value;
      final indicesPtr = indicesPtrPtr.value;

      // Copy data from native memory
      final positions = List<double>.generate(
        vertexCount * 3,
        (i) => verticesPtr[i],
      );

      final normals = List<double>.generate(
        vertexCount * 3,
        (i) => normalsPtr[i],
      );

      final indices = List<int>.generate(
        indexCount,
        (i) => indicesPtr[i],
      );

      // Free native memory
      occt.freeMesh(verticesPtr, normalsPtr, indicesPtr);

      return Mesh(
        positions: positions,
        normals: normals,
        indices: indices,
        id: meshId,
      );
    } finally {
      calloc.free(verticesPtrPtr);
      calloc.free(normalsPtrPtr);
      calloc.free(indicesPtrPtr);
      calloc.free(vertexCountPtr);
      calloc.free(indexCountPtr);
    }
  }

  /// Re-tessellate an existing mesh at a different quality level.
  Mesh retessellate({
    required Pointer<Void> shapeHandle,
    required double deflection,
    required Mesh existingMesh,
  }) {
    return tessellateShape(
      shapeHandle: shapeHandle,
      deflection: deflection,
      meshId: existingMesh.id,
    );
  }
}

/// Exception thrown when tessellation fails.
class TessellationException implements Exception {
  final String message;

  TessellationException(this.message);

  @override
  String toString() => 'TessellationException: $message';
}
