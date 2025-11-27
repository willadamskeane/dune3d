import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/sketch_providers.dart';
import '../domain/sketch_constraints.dart';
import 'sketch_canvas_widget.dart';

/// Screen for 2D sketch editing with constraint-based drawing.
class SketchScreen extends ConsumerWidget {
  const SketchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolMode = ref.watch(sketchToolProvider);
    final sketchState = ref.watch(sketchStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sketch'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context, ref),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: () {
              // TODO: Implement undo
            },
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
            onPressed: () {
              // TODO: Implement redo
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Sketch',
            onPressed: () => _confirmClear(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Finish Sketch',
            onPressed: () => _finishSketch(context, ref),
          ),
        ],
      ),
      body: const SketchCanvasWidget(),
      bottomNavigationBar: _buildToolbar(context, ref, toolMode),
      floatingActionButton: sketchState.isEmpty
          ? null
          : FloatingActionButton(
              heroTag: 'solve_sketch',
              onPressed: () => _solveSketch(ref),
              child: const Icon(Icons.auto_fix_high),
            ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    WidgetRef ref,
    SketchToolMode currentTool,
  ) {
    return BottomAppBar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ToolButton(
              icon: Icons.near_me,
              label: 'Select',
              isSelected: currentTool == SketchToolMode.select,
              onPressed: () => ref.read(sketchToolProvider.notifier).state =
                  SketchToolMode.select,
            ),
            _ToolButton(
              icon: Icons.show_chart,
              label: 'Line',
              isSelected: currentTool == SketchToolMode.line,
              onPressed: () => ref.read(sketchToolProvider.notifier).state =
                  SketchToolMode.line,
            ),
            _ToolButton(
              icon: Icons.crop_square,
              label: 'Rectangle',
              isSelected: currentTool == SketchToolMode.rectangle,
              onPressed: () => ref.read(sketchToolProvider.notifier).state =
                  SketchToolMode.rectangle,
            ),
            _ToolButton(
              icon: Icons.circle_outlined,
              label: 'Circle',
              isSelected: currentTool == SketchToolMode.circle,
              onPressed: () => ref.read(sketchToolProvider.notifier).state =
                  SketchToolMode.circle,
            ),
            _ToolButton(
              icon: Icons.arc_outlined,
              label: 'Arc',
              isSelected: currentTool == SketchToolMode.arc,
              onPressed: () =>
                  ref.read(sketchToolProvider.notifier).state = SketchToolMode.arc,
            ),
            const VerticalDivider(),
            _ToolButton(
              icon: Icons.straighten,
              label: 'Dimension',
              isSelected: currentTool == SketchToolMode.dimension,
              onPressed: () => ref.read(sketchToolProvider.notifier).state =
                  SketchToolMode.dimension,
            ),
            _ToolButton(
              icon: Icons.link,
              label: 'Constraint',
              isSelected: currentTool == SketchToolMode.constraint,
              onPressed: () => _showConstraintMenu(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _showConstraintMenu(BuildContext context, WidgetRef ref) {
    final selectedId = ref.read(sketchSelectedEntityProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Add Constraint',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.horizontal_rule),
              title: const Text('Horizontal'),
              enabled: selectedId != null,
              onTap: () {
                Navigator.pop(context);
                _addConstraint(ref, SketchConstraintType.horizontal);
              },
            ),
            ListTile(
              leading: const Icon(Icons.vertical_align_center),
              title: const Text('Vertical'),
              enabled: selectedId != null,
              onTap: () {
                Navigator.pop(context);
                _addConstraint(ref, SketchConstraintType.vertical);
              },
            ),
            ListTile(
              leading: const Icon(Icons.compare_arrows),
              title: const Text('Equal Length'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Select two segments')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.straighten),
              title: const Text('Distance'),
              onTap: () {
                Navigator.pop(context);
                _showDistanceDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.push_pin),
              title: const Text('Fix Point'),
              enabled: selectedId != null,
              onTap: () {
                Navigator.pop(context);
                _addConstraint(ref, SketchConstraintType.fixedPoint);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addConstraint(WidgetRef ref, SketchConstraintType type) {
    final selectedId = ref.read(sketchSelectedEntityProvider);
    if (selectedId != null) {
      ref.read(sketchStateProvider.notifier).addConstraint(
        type,
        [selectedId],
      );
    }
  }

  void _showDistanceDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Distance'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Distance',
            suffix: Text('mm'),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                // TODO: Apply distance constraint to selected entities
              }
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _solveSketch(WidgetRef ref) {
    // TODO: Call SketchSolverService and update state
    final notifier = ref.read(sketchStateProvider.notifier);
    // For now, just set a mock result
    notifier.setSolveResult(SolveResult.underConstrained);
  }

  void _confirmExit(BuildContext context, WidgetRef ref) {
    final sketchState = ref.read(sketchStateProvider);
    if (sketchState.isEmpty) {
      context.goNamed('viewer');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Sketch?'),
        content: const Text('Any unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(sketchStateProvider.notifier).clear();
              context.goNamed('viewer');
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Sketch?'),
        content: const Text('This will remove all entities and constraints.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(sketchStateProvider.notifier).clear();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _finishSketch(BuildContext context, WidgetRef ref) {
    // TODO: Convert sketch to wire profile and pass to modeling service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sketch saved. Ready for extrusion.')),
    );
    context.goNamed('viewer');
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
