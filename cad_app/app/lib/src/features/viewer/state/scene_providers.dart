import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/mesh_model.dart';

/// Provider for the list of meshes in the scene.
final meshListProvider = StateNotifierProvider<MeshListNotifier, List<Mesh>>((ref) {
  return MeshListNotifier();
});

/// Notifier for managing the mesh list.
class MeshListNotifier extends StateNotifier<List<Mesh>> {
  MeshListNotifier() : super([]);

  /// Add a mesh to the scene.
  void addMesh(Mesh mesh) {
    state = [...state, mesh];
  }

  /// Remove a mesh from the scene by ID.
  void removeMesh(String id) {
    state = state.where((m) => m.id != id).toList();
  }

  /// Update a mesh in the scene.
  void updateMesh(Mesh mesh) {
    state = state.map((m) => m.id == mesh.id ? mesh : m).toList();
  }

  /// Clear all meshes.
  void clear() {
    state = [];
  }

  /// Get a mesh by ID.
  Mesh? getMesh(String id) {
    try {
      return state.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Provider for the currently selected entity ID.
final selectedEntityIdProvider = StateProvider<String?>((ref) => null);

/// Provider for the hover entity ID (for highlighting).
final hoverEntityIdProvider = StateProvider<String?>((ref) => null);
