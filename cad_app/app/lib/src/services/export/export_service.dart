import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../features/viewer/domain/mesh_model.dart';

/// Supported export formats.
enum ExportFormat {
  stlBinary,
  stlAscii,
  obj,
  ply,
}

/// Service for exporting mesh data to various file formats.
class ExportService {
  ExportService._();

  static final ExportService instance = ExportService._();

  /// Export a mesh to the specified format.
  Future<void> exportMesh(
    Mesh mesh,
    String filePath,
    ExportFormat format,
  ) async {
    switch (format) {
      case ExportFormat.stlBinary:
        await _exportStlBinary(mesh, filePath);
        break;
      case ExportFormat.stlAscii:
        await _exportStlAscii(mesh, filePath);
        break;
      case ExportFormat.obj:
        await _exportObj(mesh, filePath);
        break;
      case ExportFormat.ply:
        await _exportPly(mesh, filePath);
        break;
    }
  }

  /// Export multiple meshes to STL (merged).
  Future<void> exportMeshes(
    List<Mesh> meshes,
    String filePath,
    ExportFormat format,
  ) async {
    if (meshes.isEmpty) {
      throw ArgumentError('No meshes to export');
    }

    if (meshes.length == 1) {
      await exportMesh(meshes.first, filePath, format);
      return;
    }

    // Merge meshes for export
    final mergedMesh = _mergeMeshes(meshes);
    await exportMesh(mergedMesh, filePath, format);
  }

  /// Export to binary STL format.
  Future<void> _exportStlBinary(Mesh mesh, String filePath) async {
    final file = File(filePath);
    final triangleCount = mesh.triangleCount;

    // Binary STL format:
    // 80 bytes - header
    // 4 bytes - number of triangles (uint32)
    // For each triangle:
    //   12 bytes - normal (3 floats)
    //   36 bytes - vertices (3 vertices * 3 floats)
    //   2 bytes - attribute byte count (usually 0)

    final bufferSize = 80 + 4 + triangleCount * 50;
    final buffer = ByteData(bufferSize);

    // Header (80 bytes) - filled with spaces
    for (var i = 0; i < 80; i++) {
      buffer.setUint8(i, 0x20); // space character
    }

    // Write header text
    final headerText = 'CAD App Export - ${mesh.id}';
    for (var i = 0; i < headerText.length && i < 80; i++) {
      buffer.setUint8(i, headerText.codeUnitAt(i));
    }

    // Number of triangles
    buffer.setUint32(80, triangleCount, Endian.little);

    var offset = 84;

    for (var i = 0; i < triangleCount; i++) {
      final i0 = mesh.indices[i * 3];
      final i1 = mesh.indices[i * 3 + 1];
      final i2 = mesh.indices[i * 3 + 2];

      // Vertex positions
      final v0x = mesh.positions[i0 * 3];
      final v0y = mesh.positions[i0 * 3 + 1];
      final v0z = mesh.positions[i0 * 3 + 2];
      final v1x = mesh.positions[i1 * 3];
      final v1y = mesh.positions[i1 * 3 + 1];
      final v1z = mesh.positions[i1 * 3 + 2];
      final v2x = mesh.positions[i2 * 3];
      final v2y = mesh.positions[i2 * 3 + 1];
      final v2z = mesh.positions[i2 * 3 + 2];

      // Calculate face normal
      final e1x = v1x - v0x;
      final e1y = v1y - v0y;
      final e1z = v1z - v0z;
      final e2x = v2x - v0x;
      final e2y = v2y - v0y;
      final e2z = v2z - v0z;

      var nx = e1y * e2z - e1z * e2y;
      var ny = e1z * e2x - e1x * e2z;
      var nz = e1x * e2y - e1y * e2x;

      // Normalize
      final len = _sqrt(nx * nx + ny * ny + nz * nz);
      if (len > 0) {
        nx /= len;
        ny /= len;
        nz /= len;
      }

      // Write normal
      buffer.setFloat32(offset, nx, Endian.little);
      buffer.setFloat32(offset + 4, ny, Endian.little);
      buffer.setFloat32(offset + 8, nz, Endian.little);
      offset += 12;

      // Write vertices
      buffer.setFloat32(offset, v0x, Endian.little);
      buffer.setFloat32(offset + 4, v0y, Endian.little);
      buffer.setFloat32(offset + 8, v0z, Endian.little);
      offset += 12;

      buffer.setFloat32(offset, v1x, Endian.little);
      buffer.setFloat32(offset + 4, v1y, Endian.little);
      buffer.setFloat32(offset + 8, v1z, Endian.little);
      offset += 12;

      buffer.setFloat32(offset, v2x, Endian.little);
      buffer.setFloat32(offset + 4, v2y, Endian.little);
      buffer.setFloat32(offset + 8, v2z, Endian.little);
      offset += 12;

      // Attribute byte count
      buffer.setUint16(offset, 0, Endian.little);
      offset += 2;
    }

    await file.writeAsBytes(buffer.buffer.asUint8List());
  }

  /// Export to ASCII STL format.
  Future<void> _exportStlAscii(Mesh mesh, String filePath) async {
    final buffer = StringBuffer();

    buffer.writeln('solid ${mesh.id}');

    for (var i = 0; i < mesh.triangleCount; i++) {
      final i0 = mesh.indices[i * 3];
      final i1 = mesh.indices[i * 3 + 1];
      final i2 = mesh.indices[i * 3 + 2];

      // Vertex positions
      final v0x = mesh.positions[i0 * 3];
      final v0y = mesh.positions[i0 * 3 + 1];
      final v0z = mesh.positions[i0 * 3 + 2];
      final v1x = mesh.positions[i1 * 3];
      final v1y = mesh.positions[i1 * 3 + 1];
      final v1z = mesh.positions[i1 * 3 + 2];
      final v2x = mesh.positions[i2 * 3];
      final v2y = mesh.positions[i2 * 3 + 1];
      final v2z = mesh.positions[i2 * 3 + 2];

      // Calculate face normal
      final e1x = v1x - v0x;
      final e1y = v1y - v0y;
      final e1z = v1z - v0z;
      final e2x = v2x - v0x;
      final e2y = v2y - v0y;
      final e2z = v2z - v0z;

      var nx = e1y * e2z - e1z * e2y;
      var ny = e1z * e2x - e1x * e2z;
      var nz = e1x * e2y - e1y * e2x;

      final len = _sqrt(nx * nx + ny * ny + nz * nz);
      if (len > 0) {
        nx /= len;
        ny /= len;
        nz /= len;
      }

      buffer.writeln('  facet normal $nx $ny $nz');
      buffer.writeln('    outer loop');
      buffer.writeln('      vertex $v0x $v0y $v0z');
      buffer.writeln('      vertex $v1x $v1y $v1z');
      buffer.writeln('      vertex $v2x $v2y $v2z');
      buffer.writeln('    endloop');
      buffer.writeln('  endfacet');
    }

    buffer.writeln('endsolid ${mesh.id}');

    final file = File(filePath);
    await file.writeAsString(buffer.toString());
  }

  /// Export to OBJ format.
  Future<void> _exportObj(Mesh mesh, String filePath) async {
    final buffer = StringBuffer();

    buffer.writeln('# CAD App OBJ Export');
    buffer.writeln('# Mesh: ${mesh.id}');
    buffer.writeln('# Vertices: ${mesh.vertexCount}');
    buffer.writeln('# Triangles: ${mesh.triangleCount}');
    buffer.writeln();
    buffer.writeln('o ${mesh.id}');
    buffer.writeln();

    // Write vertices
    for (var i = 0; i < mesh.vertexCount; i++) {
      final x = mesh.positions[i * 3];
      final y = mesh.positions[i * 3 + 1];
      final z = mesh.positions[i * 3 + 2];
      buffer.writeln('v $x $y $z');
    }

    buffer.writeln();

    // Write normals
    for (var i = 0; i < mesh.vertexCount; i++) {
      final nx = mesh.normals[i * 3];
      final ny = mesh.normals[i * 3 + 1];
      final nz = mesh.normals[i * 3 + 2];
      buffer.writeln('vn $nx $ny $nz');
    }

    buffer.writeln();

    // Write faces (1-indexed in OBJ)
    for (var i = 0; i < mesh.triangleCount; i++) {
      final i0 = mesh.indices[i * 3] + 1;
      final i1 = mesh.indices[i * 3 + 1] + 1;
      final i2 = mesh.indices[i * 3 + 2] + 1;
      buffer.writeln('f $i0//$i0 $i1//$i1 $i2//$i2');
    }

    final file = File(filePath);
    await file.writeAsString(buffer.toString());
  }

  /// Export to PLY format.
  Future<void> _exportPly(Mesh mesh, String filePath) async {
    final buffer = StringBuffer();

    buffer.writeln('ply');
    buffer.writeln('format ascii 1.0');
    buffer.writeln('comment CAD App Export');
    buffer.writeln('element vertex ${mesh.vertexCount}');
    buffer.writeln('property float x');
    buffer.writeln('property float y');
    buffer.writeln('property float z');
    buffer.writeln('property float nx');
    buffer.writeln('property float ny');
    buffer.writeln('property float nz');
    buffer.writeln('element face ${mesh.triangleCount}');
    buffer.writeln('property list uchar int vertex_indices');
    buffer.writeln('end_header');

    // Write vertices with normals
    for (var i = 0; i < mesh.vertexCount; i++) {
      final x = mesh.positions[i * 3];
      final y = mesh.positions[i * 3 + 1];
      final z = mesh.positions[i * 3 + 2];
      final nx = mesh.normals[i * 3];
      final ny = mesh.normals[i * 3 + 1];
      final nz = mesh.normals[i * 3 + 2];
      buffer.writeln('$x $y $z $nx $ny $nz');
    }

    // Write faces
    for (var i = 0; i < mesh.triangleCount; i++) {
      final i0 = mesh.indices[i * 3];
      final i1 = mesh.indices[i * 3 + 1];
      final i2 = mesh.indices[i * 3 + 2];
      buffer.writeln('3 $i0 $i1 $i2');
    }

    final file = File(filePath);
    await file.writeAsString(buffer.toString());
  }

  /// Merge multiple meshes into one.
  Mesh _mergeMeshes(List<Mesh> meshes) {
    final allPositions = <double>[];
    final allNormals = <double>[];
    final allIndices = <int>[];

    var vertexOffset = 0;

    for (final mesh in meshes) {
      allPositions.addAll(mesh.positions);
      allNormals.addAll(mesh.normals);

      // Offset indices
      for (final index in mesh.indices) {
        allIndices.add(index + vertexOffset);
      }

      vertexOffset += mesh.vertexCount;
    }

    return Mesh(
      id: 'merged_${DateTime.now().microsecondsSinceEpoch}',
      positions: allPositions,
      normals: allNormals,
      indices: allIndices,
    );
  }

  double _sqrt(double x) {
    // Simple Newton-Raphson square root
    if (x <= 0) return 0;
    var guess = x / 2;
    for (var i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  /// Get file extension for format.
  static String getExtension(ExportFormat format) {
    return switch (format) {
      ExportFormat.stlBinary => '.stl',
      ExportFormat.stlAscii => '.stl',
      ExportFormat.obj => '.obj',
      ExportFormat.ply => '.ply',
    };
  }

  /// Get MIME type for format.
  static String getMimeType(ExportFormat format) {
    return switch (format) {
      ExportFormat.stlBinary => 'application/sla',
      ExportFormat.stlAscii => 'application/sla',
      ExportFormat.obj => 'model/obj',
      ExportFormat.ply => 'application/x-ply',
    };
  }
}
