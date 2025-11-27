import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/mesh_model.dart';
import '../state/scene_providers.dart';
import '../state/camera_providers.dart';
import 'cad_viewport_widget.dart';
import 'viewport_renderer.dart';

/// Main 3D viewer screen with toolbar and viewport.
class ViewerScreen extends ConsumerWidget {
  const ViewerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Viewer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed('projects'),
        ),
        actions: [
          _RenderModeButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Camera',
            onPressed: () => ref.read(cameraProvider.notifier).reset(),
          ),
          IconButton(
            icon: const Icon(Icons.draw),
            tooltip: 'Sketch Mode',
            onPressed: () => context.goNamed('sketch'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.goNamed('settings'),
          ),
        ],
      ),
      body: const CadViewportWidget(),
      bottomNavigationBar: _buildToolbar(context, ref),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_primitive',
        onPressed: () => _showPrimitiveMenu(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, WidgetRef ref) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolbarButton(
            icon: Icons.crop_square,
            label: 'Box',
            onPressed: () => _addBox(ref),
          ),
          _ToolbarButton(
            icon: Icons.radio_button_unchecked,
            label: 'Cylinder',
            onPressed: () => _addCylinder(ref),
          ),
          _ToolbarButton(
            icon: Icons.circle,
            label: 'Sphere',
            onPressed: () => _addSphere(ref),
          ),
          _ToolbarButton(
            icon: Icons.change_history,
            label: 'Extrude',
            onPressed: () => _extrude(context),
          ),
          _ToolbarButton(
            icon: Icons.rounded_corner,
            label: 'Fillet',
            onPressed: () => _fillet(context),
          ),
        ],
      ),
    );
  }

  void _showPrimitiveMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.crop_square),
              title: const Text('Box'),
              onTap: () {
                Navigator.pop(context);
                _addBox(ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.radio_button_unchecked),
              title: const Text('Cylinder'),
              onTap: () {
                Navigator.pop(context);
                _addCylinder(ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.circle),
              title: const Text('Sphere'),
              onTap: () {
                Navigator.pop(context);
                _addSphere(ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addBox(WidgetRef ref) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final mesh = Mesh.cube(id, size: 2.0);
    ref.read(meshListProvider.notifier).addMesh(mesh);
    // TODO: Call ModelingService.createBox() and tessellate
  }

  void _addCylinder(WidgetRef ref) {
    // TODO: Implement cylinder creation via kernel
    final id = 'cylinder_${DateTime.now().microsecondsSinceEpoch}';
    final mesh = Mesh.empty(id);
    ref.read(meshListProvider.notifier).addMesh(mesh);
  }

  void _addSphere(WidgetRef ref) {
    // TODO: Implement sphere creation via kernel
    final id = 'sphere_${DateTime.now().microsecondsSinceEpoch}';
    final mesh = Mesh.empty(id);
    ref.read(meshListProvider.notifier).addMesh(mesh);
  }

  void _extrude(BuildContext context) {
    // TODO: Enter extrusion mode - select profile, specify height
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Extrude: Select a sketch profile first')),
    );
  }

  void _fillet(BuildContext context) {
    // TODO: Enter fillet mode - select edges, specify radius
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fillet: Select edges to fillet')),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RenderModeButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final renderMode = ref.watch(renderModeProvider);

    IconData icon;
    String tooltip;

    switch (renderMode) {
      case RenderMode.wireframe:
        icon = Icons.grid_3x3;
        tooltip = 'Wireframe';
        break;
      case RenderMode.solid:
        icon = Icons.square;
        tooltip = 'Solid';
        break;
      case RenderMode.solidWithEdges:
        icon = Icons.border_all;
        tooltip = 'Solid with Edges';
        break;
    }

    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () {
        // Cycle through render modes
        final nextMode = switch (renderMode) {
          RenderMode.wireframe => RenderMode.solid,
          RenderMode.solid => RenderMode.solidWithEdges,
          RenderMode.solidWithEdges => RenderMode.wireframe,
        };
        ref.read(renderModeProvider.notifier).state = nextMode;
      },
    );
  }
}
