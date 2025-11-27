import 'package:flutter/material.dart';
import 'theme.dart';
import '../core/tools.dart';

/// Tool category for grouping related tools
enum ToolCategory {
  sketch,
  modify,
  model,
  measure,
}

/// Tool definition with metadata
class ToolDefinition {
  final ToolType type;
  final String name;
  final String shortcut;
  final IconData icon;
  final ToolCategory category;
  final String? tooltip;

  const ToolDefinition({
    required this.type,
    required this.name,
    required this.shortcut,
    required this.icon,
    required this.category,
    this.tooltip,
  });
}

/// All available tools organized by category
class ToolDefinitions {
  static const List<ToolDefinition> all = [
    // Sketch Tools
    ToolDefinition(
      type: ToolType.select,
      name: 'Select',
      shortcut: 'V',
      icon: Icons.near_me_outlined,
      category: ToolCategory.sketch,
      tooltip: 'Select and move entities',
    ),
    ToolDefinition(
      type: ToolType.line,
      name: 'Line',
      shortcut: 'L',
      icon: Icons.timeline,
      category: ToolCategory.sketch,
      tooltip: 'Draw line segments',
    ),
    ToolDefinition(
      type: ToolType.rectangle,
      name: 'Rectangle',
      shortcut: 'R',
      icon: Icons.crop_square_outlined,
      category: ToolCategory.sketch,
      tooltip: 'Draw rectangles',
    ),
    ToolDefinition(
      type: ToolType.circle,
      name: 'Circle',
      shortcut: 'C',
      icon: Icons.circle_outlined,
      category: ToolCategory.sketch,
      tooltip: 'Draw circles',
    ),
    ToolDefinition(
      type: ToolType.arc,
      name: 'Arc',
      shortcut: 'A',
      icon: Icons.architecture,
      category: ToolCategory.sketch,
      tooltip: 'Draw arcs (3-point)',
    ),
    ToolDefinition(
      type: ToolType.point,
      name: 'Point',
      shortcut: 'P',
      icon: Icons.fiber_manual_record_outlined,
      category: ToolCategory.sketch,
      tooltip: 'Place points',
    ),
    // Modify Tools
    ToolDefinition(
      type: ToolType.trim,
      name: 'Trim',
      shortcut: 'T',
      icon: Icons.content_cut,
      category: ToolCategory.modify,
      tooltip: 'Trim entities at intersections',
    ),
    ToolDefinition(
      type: ToolType.delete,
      name: 'Delete',
      shortcut: 'X',
      icon: Icons.delete_outline,
      category: ToolCategory.modify,
      tooltip: 'Delete entities',
    ),
  ];

  static List<ToolDefinition> byCategory(ToolCategory category) {
    return all.where((t) => t.category == category).toList();
  }

  static ToolDefinition? findByType(ToolType type) {
    try {
      return all.firstWhere((t) => t.type == type);
    } catch (_) {
      return null;
    }
  }
}

/// Modern side toolbar with expandable categories
class SideToolbar extends StatefulWidget {
  final ToolType currentTool;
  final Function(ToolType) onToolSelected;
  final VoidCallback? onExtrude;
  final VoidCallback? onRevolve;
  final VoidCallback? onFillet;
  final VoidCallback? onChamfer;
  final bool hasSelection;
  final bool hasClosedSketch;

  const SideToolbar({
    super.key,
    required this.currentTool,
    required this.onToolSelected,
    this.onExtrude,
    this.onRevolve,
    this.onFillet,
    this.onChamfer,
    this.hasSelection = false,
    this.hasClosedSketch = false,
  });

  @override
  State<SideToolbar> createState() => _SideToolbarState();
}

class _SideToolbarState extends State<SideToolbar> with TickerProviderStateMixin {
  ToolCategory _expandedCategory = ToolCategory.sketch;
  bool _showModelTools = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: Dune3DTheme.surface,
        border: Border(
          right: BorderSide(color: Dune3DTheme.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: Dune3DTheme.spacingM),
          // Logo/Brand
          _buildLogo(),
          const SizedBox(height: Dune3DTheme.spacingL),
          Divider(color: Dune3DTheme.border, height: 1),
          const SizedBox(height: Dune3DTheme.spacingM),
          // Tool Categories
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Dune3DTheme.spacingS),
              child: Column(
                children: [
                  _buildCategorySection(
                    title: 'SKETCH',
                    category: ToolCategory.sketch,
                    icon: Icons.edit_outlined,
                  ),
                  const SizedBox(height: Dune3DTheme.spacingS),
                  _buildCategorySection(
                    title: 'MODIFY',
                    category: ToolCategory.modify,
                    icon: Icons.auto_fix_high,
                  ),
                  const SizedBox(height: Dune3DTheme.spacingL),
                  Divider(color: Dune3DTheme.border, height: 1),
                  const SizedBox(height: Dune3DTheme.spacingM),
                  _buildModelSection(),
                ],
              ),
            ),
          ),
          // Bottom actions
          Divider(color: Dune3DTheme.border, height: 1),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Dune3DTheme.accent, Dune3DTheme.accentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Dune3DTheme.radiusMedium),
        boxShadow: Dune3DTheme.elevation1,
      ),
      child: const Icon(
        Icons.view_in_ar,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required ToolCategory category,
    required IconData icon,
  }) {
    final isExpanded = _expandedCategory == category;
    final tools = ToolDefinitions.byCategory(category);

    return AnimatedContainer(
      duration: Dune3DAnimations.normal,
      curve: Dune3DAnimations.defaultCurve,
      decoration: BoxDecoration(
        color: isExpanded ? Dune3DTheme.surfaceLight.withOpacity(0.5) : Colors.transparent,
        borderRadius: BorderRadius.circular(Dune3DTheme.radiusMedium),
      ),
      child: Column(
        children: [
          // Category Header
          _ToolbarButton(
            icon: icon,
            label: title,
            isHeader: true,
            isExpanded: isExpanded,
            onTap: () {
              setState(() {
                _expandedCategory = category;
              });
            },
          ),
          // Tools
          AnimatedCrossFade(
            duration: Dune3DAnimations.normal,
            crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Column(
              children: tools.map((tool) => _buildToolButton(tool)).toList(),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(ToolDefinition tool) {
    final isSelected = widget.currentTool == tool.type;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: _ToolbarButton(
        icon: tool.icon,
        label: tool.name,
        shortcut: tool.shortcut,
        isSelected: isSelected,
        tooltip: tool.tooltip,
        onTap: () => widget.onToolSelected(tool.type),
      ),
    );
  }

  Widget _buildModelSection() {
    return Column(
      children: [
        _ToolbarButton(
          icon: Icons.layers_outlined,
          label: 'MODEL',
          isHeader: true,
          isExpanded: _showModelTools,
          onTap: () {
            setState(() {
              _showModelTools = !_showModelTools;
            });
          },
        ),
        AnimatedCrossFade(
          duration: Dune3DAnimations.normal,
          crossFadeState: _showModelTools ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(
            children: [
              _ToolbarButton(
                icon: Icons.open_in_full,
                label: 'Extrude',
                shortcut: 'E',
                isEnabled: widget.hasClosedSketch,
                tooltip: 'Extrude sketch to 3D',
                onTap: widget.onExtrude,
              ),
              _ToolbarButton(
                icon: Icons.rotate_left,
                label: 'Revolve',
                isEnabled: widget.hasClosedSketch,
                tooltip: 'Revolve sketch around axis',
                onTap: widget.onRevolve,
              ),
              _ToolbarButton(
                icon: Icons.rounded_corner,
                label: 'Fillet',
                isEnabled: widget.hasSelection,
                tooltip: 'Round edges',
                onTap: widget.onFillet,
              ),
              _ToolbarButton(
                icon: Icons.crop_16_9,
                label: 'Chamfer',
                isEnabled: widget.hasSelection,
                tooltip: 'Bevel edges',
                onTap: widget.onChamfer,
              ),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(Dune3DTheme.spacingS),
      child: Column(
        children: [
          _ToolbarButton(
            icon: Icons.undo,
            label: 'Undo',
            shortcut: 'Z',
            onTap: () {},
          ),
          _ToolbarButton(
            icon: Icons.redo,
            label: 'Redo',
            shortcut: 'Y',
            onTap: () {},
          ),
          const SizedBox(height: Dune3DTheme.spacingS),
          _ToolbarButton(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

/// Individual toolbar button with hover states and animations
class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? shortcut;
  final String? tooltip;
  final bool isSelected;
  final bool isHeader;
  final bool isExpanded;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    this.shortcut,
    this.tooltip,
    this.isSelected = false,
    this.isHeader = false,
    this.isExpanded = false,
    this.isEnabled = true,
    this.onTap,
  });

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isEnabled && (widget.onTap != null);
    final showTooltip = widget.tooltip != null || widget.shortcut != null;

    Widget button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: isActive ? widget.onTap : null,
        child: AnimatedContainer(
          duration: Dune3DAnimations.fast,
          width: double.infinity,
          height: Dune3DTheme.toolButtonSize,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Dune3DTheme.accent.withOpacity(0.2)
                : _isHovered && isActive
                    ? Dune3DTheme.surfaceLight
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(Dune3DTheme.radiusSmall),
            border: Border.all(
              color: widget.isSelected ? Dune3DTheme.accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: widget.isHeader ? 18 : 20,
                color: !isActive
                    ? Dune3DTheme.textDisabled
                    : widget.isSelected
                        ? Dune3DTheme.accent
                        : widget.isHeader
                            ? Dune3DTheme.textSecondary
                            : Dune3DTheme.textPrimary,
              ),
              if (widget.isHeader) ...[
                const SizedBox(width: 4),
                Icon(
                  widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 14,
                  color: Dune3DTheme.textTertiary,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (showTooltip) {
      final tooltipText = widget.shortcut != null
          ? '${widget.label} (${widget.shortcut})'
          : widget.label;
      final fullTooltip = widget.tooltip != null
          ? '$tooltipText\n${widget.tooltip}'
          : tooltipText;

      button = Tooltip(
        message: fullTooltip,
        preferBelow: false,
        verticalOffset: 0,
        waitDuration: const Duration(milliseconds: 500),
        child: button,
      );
    }

    return button;
  }
}

/// Compact floating toolbar for quick access (Shapr3D style)
class QuickToolbar extends StatelessWidget {
  final ToolType currentTool;
  final Function(ToolType) onToolSelected;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;

  const QuickToolbar({
    super.key,
    required this.currentTool,
    required this.onToolSelected,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dune3DTheme.spacingM,
        vertical: Dune3DTheme.spacingS,
      ),
      decoration: Dune3DDecorations.floatingPanel(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Undo/Redo
          _QuickButton(
            icon: Icons.undo,
            isEnabled: canUndo,
            onTap: onUndo,
          ),
          _QuickButton(
            icon: Icons.redo,
            isEnabled: canRedo,
            onTap: onRedo,
          ),
          const SizedBox(width: Dune3DTheme.spacingS),
          Container(width: 1, height: 24, color: Dune3DTheme.border),
          const SizedBox(width: Dune3DTheme.spacingS),
          // Primary tools
          _QuickButton(
            icon: Icons.near_me_outlined,
            isSelected: currentTool == ToolType.select,
            onTap: () => onToolSelected(ToolType.select),
          ),
          _QuickButton(
            icon: Icons.timeline,
            isSelected: currentTool == ToolType.line,
            onTap: () => onToolSelected(ToolType.line),
          ),
          _QuickButton(
            icon: Icons.crop_square_outlined,
            isSelected: currentTool == ToolType.rectangle,
            onTap: () => onToolSelected(ToolType.rectangle),
          ),
          _QuickButton(
            icon: Icons.circle_outlined,
            isSelected: currentTool == ToolType.circle,
            onTap: () => onToolSelected(ToolType.circle),
          ),
        ],
      ),
    );
  }
}

class _QuickButton extends StatefulWidget {
  final IconData icon;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _QuickButton({
    required this.icon,
    this.isSelected = false,
    this.isEnabled = true,
    this.onTap,
  });

  @override
  State<_QuickButton> createState() => _QuickButtonState();
}

class _QuickButtonState extends State<_QuickButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isEnabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: Dune3DAnimations.fast,
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Dune3DTheme.accent
                : _isHovered && widget.isEnabled
                    ? Dune3DTheme.surfaceLight
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(Dune3DTheme.radiusSmall),
          ),
          child: Icon(
            widget.icon,
            size: 20,
            color: !widget.isEnabled
                ? Dune3DTheme.textDisabled
                : widget.isSelected
                    ? Colors.white
                    : Dune3DTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
