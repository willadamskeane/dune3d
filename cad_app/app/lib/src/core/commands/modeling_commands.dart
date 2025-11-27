import 'dart:ffi';

import 'command.dart';
import '../../features/viewer/domain/mesh_model.dart';
import '../../features/viewer/state/scene_providers.dart';

/// Command for adding a primitive to the scene.
class AddPrimitiveCommand implements Command {
  final MeshListNotifier _meshNotifier;
  final Mesh mesh;
  final Pointer<Void>? shapeHandle;

  AddPrimitiveCommand(
    this._meshNotifier, {
    required this.mesh,
    this.shapeHandle,
  });

  @override
  String get name => 'Add ${_meshTypeName()}';

  @override
  void execute() {
    _meshNotifier.addMesh(mesh);
  }

  @override
  void undo() {
    _meshNotifier.removeMesh(mesh.id);
  }

  String _meshTypeName() {
    if (mesh.id.contains('box')) return 'Box';
    if (mesh.id.contains('cylinder')) return 'Cylinder';
    if (mesh.id.contains('sphere')) return 'Sphere';
    return 'Primitive';
  }
}

/// Command for removing a mesh from the scene.
class RemoveMeshCommand implements Command {
  final MeshListNotifier _meshNotifier;
  final String meshId;

  Mesh? _removedMesh;

  RemoveMeshCommand(this._meshNotifier, this.meshId);

  @override
  String get name => 'Delete';

  @override
  void execute() {
    _removedMesh = _meshNotifier.getMesh(meshId);
    _meshNotifier.removeMesh(meshId);
  }

  @override
  void undo() {
    if (_removedMesh != null) {
      _meshNotifier.addMesh(_removedMesh!);
    }
  }
}

/// Command for applying fillet to edges.
class ApplyFilletCommand implements Command {
  final MeshListNotifier _meshNotifier;
  final String meshId;
  final List<int> edgeIds;
  final double radius;

  Mesh? _originalMesh;
  Mesh? _filletedMesh;

  ApplyFilletCommand(
    this._meshNotifier, {
    required this.meshId,
    required this.edgeIds,
    required this.radius,
  });

  @override
  String get name => 'Apply Fillet';

  @override
  void execute() {
    _originalMesh = _meshNotifier.getMesh(meshId);
    // TODO: Actually apply fillet via kernel and update mesh
    // For now this is a placeholder
  }

  @override
  void undo() {
    if (_originalMesh != null) {
      _meshNotifier.updateMesh(_originalMesh!);
    }
  }
}

/// Command for applying chamfer to edges.
class ApplyChamferCommand implements Command {
  final MeshListNotifier _meshNotifier;
  final String meshId;
  final List<int> edgeIds;
  final double distance;

  Mesh? _originalMesh;

  ApplyChamferCommand(
    this._meshNotifier, {
    required this.meshId,
    required this.edgeIds,
    required this.distance,
  });

  @override
  String get name => 'Apply Chamfer';

  @override
  void execute() {
    _originalMesh = _meshNotifier.getMesh(meshId);
    // TODO: Actually apply chamfer via kernel and update mesh
  }

  @override
  void undo() {
    if (_originalMesh != null) {
      _meshNotifier.updateMesh(_originalMesh!);
    }
  }
}

/// Command for boolean union operation.
class BooleanUnionCommand implements Command {
  final MeshListNotifier _meshNotifier;
  final String meshAId;
  final String meshBId;

  Mesh? _meshA;
  Mesh? _meshB;
  Mesh? _resultMesh;

  BooleanUnionCommand(
    this._meshNotifier, {
    required this.meshAId,
    required this.meshBId,
  });

  @override
  String get name => 'Boolean Union';

  @override
  void execute() {
    _meshA = _meshNotifier.getMesh(meshAId);
    _meshB = _meshNotifier.getMesh(meshBId);

    // TODO: Actually perform boolean union via kernel
    // For now create a placeholder result
    if (_meshA != null && _meshB != null) {
      _resultMesh = Mesh(
        id: 'union_${DateTime.now().microsecondsSinceEpoch}',
        positions: [..._meshA!.positions, ..._meshB!.positions],
        normals: [..._meshA!.normals, ..._meshB!.normals],
        indices: _meshA!.indices, // Simplified
      );

      _meshNotifier.removeMesh(meshAId);
      _meshNotifier.removeMesh(meshBId);
      _meshNotifier.addMesh(_resultMesh!);
    }
  }

  @override
  void undo() {
    if (_resultMesh != null) {
      _meshNotifier.removeMesh(_resultMesh!.id);
    }
    if (_meshA != null) {
      _meshNotifier.addMesh(_meshA!);
    }
    if (_meshB != null) {
      _meshNotifier.addMesh(_meshB!);
    }
  }
}

/// Command for boolean cut operation (A - B).
class BooleanCutCommand implements Command {
  final MeshListNotifier _meshNotifier;
  final String meshAId;
  final String meshBId;

  Mesh? _meshA;
  Mesh? _meshB;
  Mesh? _resultMesh;

  BooleanCutCommand(
    this._meshNotifier, {
    required this.meshAId,
    required this.meshBId,
  });

  @override
  String get name => 'Boolean Cut';

  @override
  void execute() {
    _meshA = _meshNotifier.getMesh(meshAId);
    _meshB = _meshNotifier.getMesh(meshBId);

    // TODO: Actually perform boolean cut via kernel
    if (_meshA != null && _meshB != null) {
      _resultMesh = Mesh(
        id: 'cut_${DateTime.now().microsecondsSinceEpoch}',
        positions: _meshA!.positions,
        normals: _meshA!.normals,
        indices: _meshA!.indices,
      );

      _meshNotifier.removeMesh(meshAId);
      _meshNotifier.removeMesh(meshBId);
      _meshNotifier.addMesh(_resultMesh!);
    }
  }

  @override
  void undo() {
    if (_resultMesh != null) {
      _meshNotifier.removeMesh(_resultMesh!.id);
    }
    if (_meshA != null) {
      _meshNotifier.addMesh(_meshA!);
    }
    if (_meshB != null) {
      _meshNotifier.addMesh(_meshB!);
    }
  }
}

/// Command for extruding a sketch profile.
class ExtrudeCommand implements Command {
  final MeshListNotifier _meshNotifier;
  final String profileId;
  final double height;

  Mesh? _extrudedMesh;

  ExtrudeCommand(
    this._meshNotifier, {
    required this.profileId,
    required this.height,
  });

  @override
  String get name => 'Extrude';

  @override
  void execute() {
    // TODO: Actually extrude via kernel
    _extrudedMesh = Mesh(
      id: 'extrude_${DateTime.now().microsecondsSinceEpoch}',
      positions: [],
      normals: [],
      indices: [],
    );
    _meshNotifier.addMesh(_extrudedMesh!);
  }

  @override
  void undo() {
    if (_extrudedMesh != null) {
      _meshNotifier.removeMesh(_extrudedMesh!.id);
    }
  }
}
