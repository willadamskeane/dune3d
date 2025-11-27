import 'package:flutter/material.dart';
import '../core/core.dart';

/// Panel for managing constraints on the current sketch
class ConstraintsPanel extends StatefulWidget {
  final SketchDocument document;

  const ConstraintsPanel({super.key, required this.document});

  @override
  State<ConstraintsPanel> createState() => _ConstraintsPanelState();
}

class _ConstraintsPanelState extends State<ConstraintsPanel> {
  @override
  void initState() {
    super.initState();
    widget.document.addListener(_onDocumentChanged);
  }

  @override
  void dispose() {
    widget.document.removeListener(_onDocumentChanged);
    super.dispose();
  }

  void _onDocumentChanged() {
    setState(() {});
  }

  void _showAddConstraintDialog() {
    final selectedEntities = widget.document.selectedEntities;

    if (selectedEntities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select entities first to add constraints')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => _AddConstraintSheet(
        document: widget.document,
        selectedEntities: selectedEntities,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final constraints = widget.document.constraints.toList();
    final entities = widget.document.entities.toList();

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            border: Border(bottom: BorderSide(color: Colors.grey.shade800)),
          ),
          child: Row(
            children: [
              const Icon(Icons.transform, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Constraints',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _showAddConstraintDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
        ),

        // Entity list
        Expanded(
          child: Row(
            children: [
              // Entities column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: const Color(0xFF252525),
                      child: Row(
                        children: [
                          const Icon(Icons.category, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Entities (${entities.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: entities.isEmpty
                          ? const Center(
                              child: Text(
                                'No entities yet.\nSwitch to Sketch tab to draw.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: entities.length,
                              itemBuilder: (context, index) {
                                final entity = entities[index];
                                return _EntityTile(
                                  entity: entity,
                                  onTap: () {
                                    widget.document.toggleEntitySelection(entity.id);
                                  },
                                  onDelete: () {
                                    widget.document.removeEntity(entity.id);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),

              const VerticalDivider(width: 1),

              // Constraints column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: const Color(0xFF252525),
                      child: Row(
                        children: [
                          const Icon(Icons.link, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Constraints (${constraints.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: constraints.isEmpty
                          ? const Center(
                              child: Text(
                                'No constraints yet.\nSelect entities and tap Add.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: constraints.length,
                              itemBuilder: (context, index) {
                                final constraint = constraints[index];
                                return _ConstraintTile(
                                  constraint: constraint,
                                  onDelete: () {
                                    widget.document.removeConstraint(constraint.id);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EntityTile extends StatelessWidget {
  final SketchEntity entity;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EntityTile({
    required this.entity,
    required this.onTap,
    required this.onDelete,
  });

  IconData _getIcon() {
    switch (entity.type) {
      case EntityType.point:
        return Icons.fiber_manual_record;
      case EntityType.line:
        return Icons.remove;
      case EntityType.circle:
        return Icons.circle_outlined;
      case EntityType.arc:
        return Icons.architecture;
      case EntityType.rectangle:
        return Icons.crop_square;
    }
  }

  String _getDescription() {
    switch (entity.type) {
      case EntityType.point:
        final p = entity as PointEntity;
        return 'Point (${p.position.x.toStringAsFixed(1)}, ${p.position.y.toStringAsFixed(1)})';
      case EntityType.line:
        final l = entity as LineEntity;
        return 'Line L=${l.length.toStringAsFixed(1)}';
      case EntityType.circle:
        final c = entity as CircleEntity;
        return 'Circle R=${c.radius.toStringAsFixed(1)}';
      case EntityType.arc:
        final a = entity as ArcEntity;
        return 'Arc R=${a.radius.toStringAsFixed(1)}';
      case EntityType.rectangle:
        final r = entity as RectangleEntity;
        return 'Rect ${r.width.toStringAsFixed(1)}x${r.height.toStringAsFixed(1)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        _getIcon(),
        size: 18,
        color: entity.isSelected ? Colors.cyan : null,
      ),
      title: Text(
        entity.id,
        style: TextStyle(
          fontWeight: entity.isSelected ? FontWeight.bold : FontWeight.normal,
          color: entity.isSelected ? Colors.cyan : null,
        ),
      ),
      subtitle: Text(_getDescription(), style: const TextStyle(fontSize: 11)),
      trailing: IconButton(
        icon: const Icon(Icons.delete, size: 18),
        onPressed: onDelete,
      ),
      selected: entity.isSelected,
      onTap: onTap,
    );
  }
}

class _ConstraintTile extends StatelessWidget {
  final Constraint constraint;
  final VoidCallback onDelete;

  const _ConstraintTile({
    required this.constraint,
    required this.onDelete,
  });

  IconData _getIcon() {
    switch (constraint.type) {
      case ConstraintType.horizontal:
        return Icons.horizontal_rule;
      case ConstraintType.vertical:
        return Icons.vertical_align_center;
      case ConstraintType.parallel:
        return Icons.reorder;
      case ConstraintType.perpendicular:
        return Icons.add;
      case ConstraintType.coincident:
        return Icons.adjust;
      case ConstraintType.equal:
        return Icons.drag_handle;
      case ConstraintType.fixed:
        return Icons.push_pin;
      case ConstraintType.distance:
        return Icons.straighten;
      case ConstraintType.angle:
        return Icons.rotate_90_degrees_ccw;
      case ConstraintType.radius:
        return Icons.radio_button_unchecked;
      case ConstraintType.tangent:
        return Icons.gesture;
      case ConstraintType.midpoint:
        return Icons.vertical_align_center;
      case ConstraintType.symmetric:
        return Icons.flip;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        _getIcon(),
        size: 18,
        color: constraint.isSatisfied ? Colors.green : Colors.orange,
      ),
      title: Text(constraint.description),
      subtitle: Text(
        'Entities: ${constraint.entityIds.join(", ")}',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete, size: 18),
        onPressed: onDelete,
      ),
    );
  }
}

class _AddConstraintSheet extends StatelessWidget {
  final SketchDocument document;
  final List<SketchEntity> selectedEntities;

  const _AddConstraintSheet({
    required this.document,
    required this.selectedEntities,
  });

  bool _canAddConstraint(ConstraintType type) {
    switch (type) {
      case ConstraintType.horizontal:
      case ConstraintType.vertical:
        return selectedEntities.length == 1 &&
            selectedEntities.first is LineEntity;
      case ConstraintType.distance:
        return selectedEntities.length == 1 &&
                selectedEntities.first is LineEntity ||
            selectedEntities.length == 2;
      case ConstraintType.radius:
        return selectedEntities.length == 1 &&
            (selectedEntities.first is CircleEntity ||
                selectedEntities.first is ArcEntity);
      case ConstraintType.parallel:
      case ConstraintType.perpendicular:
        return selectedEntities.length == 2 &&
            selectedEntities.every((e) => e is LineEntity);
      case ConstraintType.equal:
        return selectedEntities.length == 2 &&
            (selectedEntities.every((e) => e is LineEntity) ||
                selectedEntities.every((e) => e is CircleEntity));
      case ConstraintType.coincident:
        return selectedEntities.length == 2;
      default:
        return false;
    }
  }

  void _addConstraint(BuildContext context, ConstraintType type) {
    final ids = selectedEntities.map((e) => e.id).toList();

    switch (type) {
      case ConstraintType.horizontal:
        document.addHorizontalConstraint(ids[0]);
        break;
      case ConstraintType.vertical:
        document.addVerticalConstraint(ids[0]);
        break;
      case ConstraintType.parallel:
        document.addParallelConstraint(ids[0], ids[1]);
        break;
      case ConstraintType.perpendicular:
        document.addPerpendicularConstraint(ids[0], ids[1]);
        break;
      case ConstraintType.equal:
        document.addEqualConstraint(ids[0], ids[1]);
        break;
      case ConstraintType.coincident:
        document.addCoincidentConstraint(ids[0], ids[1]);
        break;
      case ConstraintType.distance:
        _showValueDialog(context, 'Distance', (value) {
          document.addDistanceConstraint(ids, value);
        });
        return;
      case ConstraintType.radius:
        _showValueDialog(context, 'Radius', (value) {
          document.addRadiusConstraint(ids[0], value);
        });
        return;
      case ConstraintType.angle:
        _showValueDialog(context, 'Angle (degrees)', (value) {
          document.addAngleConstraint(ids, value);
        });
        return;
      default:
        break;
    }

    Navigator.pop(context);
  }

  void _showValueDialog(
      BuildContext context, String label, void Function(double) onSubmit) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter $label'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(labelText: label),
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
                onSubmit(value);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close sheet
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Constraint',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Selected: ${selectedEntities.map((e) => e.id).join(", ")}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ConstraintButton(
                icon: Icons.horizontal_rule,
                label: 'Horizontal',
                enabled: _canAddConstraint(ConstraintType.horizontal),
                onPressed: () => _addConstraint(context, ConstraintType.horizontal),
              ),
              _ConstraintButton(
                icon: Icons.vertical_align_center,
                label: 'Vertical',
                enabled: _canAddConstraint(ConstraintType.vertical),
                onPressed: () => _addConstraint(context, ConstraintType.vertical),
              ),
              _ConstraintButton(
                icon: Icons.reorder,
                label: 'Parallel',
                enabled: _canAddConstraint(ConstraintType.parallel),
                onPressed: () => _addConstraint(context, ConstraintType.parallel),
              ),
              _ConstraintButton(
                icon: Icons.add,
                label: 'Perpendicular',
                enabled: _canAddConstraint(ConstraintType.perpendicular),
                onPressed: () =>
                    _addConstraint(context, ConstraintType.perpendicular),
              ),
              _ConstraintButton(
                icon: Icons.drag_handle,
                label: 'Equal',
                enabled: _canAddConstraint(ConstraintType.equal),
                onPressed: () => _addConstraint(context, ConstraintType.equal),
              ),
              _ConstraintButton(
                icon: Icons.adjust,
                label: 'Coincident',
                enabled: _canAddConstraint(ConstraintType.coincident),
                onPressed: () => _addConstraint(context, ConstraintType.coincident),
              ),
              _ConstraintButton(
                icon: Icons.straighten,
                label: 'Distance',
                enabled: _canAddConstraint(ConstraintType.distance),
                onPressed: () => _addConstraint(context, ConstraintType.distance),
              ),
              _ConstraintButton(
                icon: Icons.radio_button_unchecked,
                label: 'Radius',
                enabled: _canAddConstraint(ConstraintType.radius),
                onPressed: () => _addConstraint(context, ConstraintType.radius),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ConstraintButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _ConstraintButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
