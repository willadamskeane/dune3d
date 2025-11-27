import 'package:flutter/material.dart';
import 'theme.dart';
import '../core/model_3d.dart';

/// Feature/operation item for timeline
class FeatureItem {
  final String id;
  final String name;
  final String type;
  final IconData icon;
  final bool isVisible;
  final bool isLocked;
  final List<String>? details;
  final DateTime createdAt;

  FeatureItem({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    this.isVisible = true,
    this.isLocked = false,
    this.details,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory FeatureItem.fromOperation(Operation3D op) {
    IconData icon;
    List<String> details = [];

    switch (op.type) {
      case Operation3DType.extrude:
        icon = Icons.open_in_full;
        if (op is ExtrudeOperation) {
          details.add('Distance: ${op.distance.toStringAsFixed(1)} mm');
          details.add('Mode: ${op.mode.name}');
        }
        break;
      case Operation3DType.revolve:
        icon = Icons.rotate_left;
        break;
      case Operation3DType.fillet:
        icon = Icons.rounded_corner;
        if (op is FilletOperation) {
          details.add('Radius: ${op.radius.toStringAsFixed(1)} mm');
        }
        break;
      case Operation3DType.chamfer:
        icon = Icons.crop_16_9;
        break;
      default:
        icon = Icons.construction;
    }

    return FeatureItem(
      id: op.id,
      name: op.name,
      type: op.type.name,
      icon: icon,
      isVisible: op.isVisible,
      details: details.isNotEmpty ? details : null,
    );
  }
}

/// Feature timeline panel showing operation history (like Shapr3D/Fusion 360)
class FeatureTimeline extends StatefulWidget {
  final List<FeatureItem> features;
  final int? selectedIndex;
  final Function(int) onSelect;
  final Function(int, bool) onVisibilityChanged;
  final Function(int)? onEdit;
  final Function(int)? onDelete;
  final VoidCallback? onAddSketch;
  final VoidCallback? onAddExtrude;

  const FeatureTimeline({
    super.key,
    required this.features,
    this.selectedIndex,
    required this.onSelect,
    required this.onVisibilityChanged,
    this.onEdit,
    this.onDelete,
    this.onAddSketch,
    this.onAddExtrude,
  });

  @override
  State<FeatureTimeline> createState() => _FeatureTimelineState();
}

class _FeatureTimelineState extends State<FeatureTimeline> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Dune3DTheme.surface,
        border: Border(
          left: BorderSide(color: Dune3DTheme.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, color: Dune3DTheme.border),
          if (_isExpanded) ...[
            Expanded(
              child: widget.features.isEmpty
                  ? _buildEmptyState()
                  : _buildFeatureList(),
            ),
            const Divider(height: 1, color: Dune3DTheme.border),
            _buildAddButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: const EdgeInsets.all(Dune3DTheme.spacingM),
        child: Row(
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 18,
              color: Dune3DTheme.textSecondary,
            ),
            const SizedBox(width: Dune3DTheme.spacingS),
            Expanded(
              child: Text(
                'Feature Timeline',
                style: Dune3DTheme.heading3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Dune3DTheme.spacingS,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Dune3DTheme.surfaceLight,
                borderRadius: BorderRadius.circular(Dune3DTheme.radiusSmall),
              ),
              child: Text(
                '${widget.features.length}',
                style: Dune3DTheme.caption,
              ),
            ),
            const SizedBox(width: Dune3DTheme.spacingS),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 18,
              color: Dune3DTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dune3DTheme.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Dune3DTheme.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.layers_outlined,
                size: 28,
                color: Dune3DTheme.textTertiary,
              ),
            ),
            const SizedBox(height: Dune3DTheme.spacingM),
            Text(
              'No Features Yet',
              style: Dune3DTheme.bodySmall.copyWith(
                color: Dune3DTheme.textSecondary,
              ),
            ),
            const SizedBox(height: Dune3DTheme.spacingXS),
            Text(
              'Start by creating a sketch',
              style: Dune3DTheme.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: Dune3DTheme.spacingS),
      itemCount: widget.features.length,
      onReorder: (oldIndex, newIndex) {
        // Handle reorder
      },
      itemBuilder: (context, index) {
        final feature = widget.features[index];
        final isSelected = widget.selectedIndex == index;

        return _FeatureListItem(
          key: ValueKey(feature.id),
          feature: feature,
          index: index,
          isSelected: isSelected,
          isLast: index == widget.features.length - 1,
          onSelect: () => widget.onSelect(index),
          onVisibilityToggle: () => widget.onVisibilityChanged(index, !feature.isVisible),
          onEdit: widget.onEdit != null ? () => widget.onEdit!(index) : null,
          onDelete: widget.onDelete != null ? () => widget.onDelete!(index) : null,
        );
      },
    );
  }

  Widget _buildAddButtons() {
    return Container(
      padding: const EdgeInsets.all(Dune3DTheme.spacingM),
      child: Row(
        children: [
          Expanded(
            child: _AddFeatureButton(
              icon: Icons.edit_outlined,
              label: 'Sketch',
              onTap: widget.onAddSketch,
            ),
          ),
          const SizedBox(width: Dune3DTheme.spacingS),
          Expanded(
            child: _AddFeatureButton(
              icon: Icons.open_in_full,
              label: 'Extrude',
              onTap: widget.onAddExtrude,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureListItem extends StatefulWidget {
  final FeatureItem feature;
  final int index;
  final bool isSelected;
  final bool isLast;
  final VoidCallback onSelect;
  final VoidCallback onVisibilityToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _FeatureListItem({
    super.key,
    required this.feature,
    required this.index,
    required this.isSelected,
    required this.isLast,
    required this.onSelect,
    required this.onVisibilityToggle,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_FeatureListItem> createState() => _FeatureListItemState();
}

class _FeatureListItemState extends State<_FeatureListItem> {
  bool _isHovered = false;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Column(
        children: [
          // Timeline connector
          Container(
            margin: const EdgeInsets.only(left: 27),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 8,
                  color: widget.index == 0
                      ? Colors.transparent
                      : Dune3DTheme.border,
                ),
              ],
            ),
          ),
          // Feature item
          GestureDetector(
            onTap: widget.onSelect,
            onDoubleTap: widget.onEdit,
            child: AnimatedContainer(
              duration: Dune3DAnimations.fast,
              margin: const EdgeInsets.symmetric(
                horizontal: Dune3DTheme.spacingS,
              ),
              padding: const EdgeInsets.all(Dune3DTheme.spacingS),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? Dune3DTheme.accent.withOpacity(0.15)
                    : _isHovered
                        ? Dune3DTheme.surfaceLight
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(Dune3DTheme.radiusSmall),
                border: Border.all(
                  color: widget.isSelected
                      ? Dune3DTheme.accent
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Timeline dot
                  _TimelineDot(
                    isActive: widget.isSelected,
                    icon: widget.feature.icon,
                  ),
                  const SizedBox(width: Dune3DTheme.spacingM),
                  // Feature info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.feature.name,
                                style: Dune3DTheme.body.copyWith(
                                  color: widget.feature.isVisible
                                      ? Dune3DTheme.textPrimary
                                      : Dune3DTheme.textDisabled,
                                  fontWeight: widget.isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.feature.details != null)
                              GestureDetector(
                                onTap: () => setState(() => _isExpanded = !_isExpanded),
                                child: Icon(
                                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                                  size: 16,
                                  color: Dune3DTheme.textTertiary,
                                ),
                              ),
                          ],
                        ),
                        if (widget.feature.details != null && _isExpanded) ...[
                          const SizedBox(height: 4),
                          ...widget.feature.details!.map(
                            (detail) => Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                detail,
                                style: Dune3DTheme.caption,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Actions
                  if (_isHovered || widget.isSelected) ...[
                    const SizedBox(width: Dune3DTheme.spacingS),
                    _FeatureAction(
                      icon: widget.feature.isVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      onTap: widget.onVisibilityToggle,
                      tooltip: widget.feature.isVisible ? 'Hide' : 'Show',
                    ),
                    if (widget.onEdit != null)
                      _FeatureAction(
                        icon: Icons.edit_outlined,
                        onTap: widget.onEdit!,
                        tooltip: 'Edit',
                      ),
                    if (widget.onDelete != null)
                      _FeatureAction(
                        icon: Icons.delete_outline,
                        onTap: widget.onDelete!,
                        tooltip: 'Delete',
                        color: Dune3DTheme.error,
                      ),
                  ],
                ],
              ),
            ),
          ),
          // Timeline connector (bottom)
          if (!widget.isLast)
            Container(
              margin: const EdgeInsets.only(left: 27),
              child: Row(
                children: [
                  Container(
                    width: 2,
                    height: 8,
                    color: Dune3DTheme.border,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  final bool isActive;
  final IconData icon;

  const _TimelineDot({
    required this.isActive,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? Dune3DTheme.accent : Dune3DTheme.surfaceLight,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? Dune3DTheme.accent : Dune3DTheme.border,
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        size: 16,
        color: isActive ? Colors.white : Dune3DTheme.textSecondary,
      ),
    );
  }
}

class _FeatureAction extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? color;

  const _FeatureAction({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.color,
  });

  @override
  State<_FeatureAction> createState() => _FeatureActionState();
}

class _FeatureActionState extends State<_FeatureAction> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _isHovered ? Dune3DTheme.surfaceLight : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            widget.icon,
            size: 14,
            color: widget.color ?? Dune3DTheme.textSecondary,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

class _AddFeatureButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _AddFeatureButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  State<_AddFeatureButton> createState() => _AddFeatureButtonState();
}

class _AddFeatureButtonState extends State<_AddFeatureButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Dune3DAnimations.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: Dune3DTheme.spacingS,
            vertical: Dune3DTheme.spacingS,
          ),
          decoration: BoxDecoration(
            color: _isHovered ? Dune3DTheme.surfaceLight : Colors.transparent,
            borderRadius: BorderRadius.circular(Dune3DTheme.radiusSmall),
            border: Border.all(
              color: Dune3DTheme.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: Dune3DTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: Dune3DTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
