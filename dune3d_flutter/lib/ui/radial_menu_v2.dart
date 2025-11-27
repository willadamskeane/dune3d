import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'theme.dart';
import '../core/tools.dart';

/// Modern radial menu item definition
class RadialMenuItem {
  final String id;
  final String label;
  final IconData icon;
  final Color? color;
  final List<RadialMenuItem>? children;
  final bool isEnabled;

  const RadialMenuItem({
    required this.id,
    required this.label,
    required this.icon,
    this.color,
    this.children,
    this.isEnabled = true,
  });
}

/// Enhanced radial menu with smooth animations and nested support
class RadialMenuV2 extends StatefulWidget {
  final Offset position;
  final VoidCallback onClose;
  final Function(String) onItemSelected;
  final List<RadialMenuItem>? customItems;

  const RadialMenuV2({
    super.key,
    required this.position,
    required this.onClose,
    required this.onItemSelected,
    this.customItems,
  });

  // Default CAD tools menu
  static List<RadialMenuItem> get defaultItems => [
    const RadialMenuItem(
      id: 'select',
      label: 'Select',
      icon: Icons.near_me_outlined,
    ),
    RadialMenuItem(
      id: 'sketch',
      label: 'Sketch',
      icon: Icons.edit_outlined,
      children: [
        const RadialMenuItem(id: 'line', label: 'Line', icon: Icons.timeline),
        const RadialMenuItem(id: 'rect', label: 'Rectangle', icon: Icons.crop_square_outlined),
        const RadialMenuItem(id: 'circle', label: 'Circle', icon: Icons.circle_outlined),
        const RadialMenuItem(id: 'arc', label: 'Arc', icon: Icons.architecture),
        const RadialMenuItem(id: 'point', label: 'Point', icon: Icons.fiber_manual_record_outlined),
      ],
    ),
    RadialMenuItem(
      id: 'modify',
      label: 'Modify',
      icon: Icons.auto_fix_high,
      children: [
        const RadialMenuItem(id: 'trim', label: 'Trim', icon: Icons.content_cut),
        const RadialMenuItem(id: 'delete', label: 'Delete', icon: Icons.delete_outline),
        const RadialMenuItem(id: 'mirror', label: 'Mirror', icon: Icons.flip),
        const RadialMenuItem(id: 'offset', label: 'Offset', icon: Icons.open_in_full),
      ],
    ),
    RadialMenuItem(
      id: 'model',
      label: 'Model',
      icon: Icons.view_in_ar,
      color: Dune3DTheme.accent,
      children: [
        const RadialMenuItem(id: 'extrude', label: 'Extrude', icon: Icons.open_in_full),
        const RadialMenuItem(id: 'revolve', label: 'Revolve', icon: Icons.rotate_left),
        const RadialMenuItem(id: 'fillet', label: 'Fillet', icon: Icons.rounded_corner),
        const RadialMenuItem(id: 'chamfer', label: 'Chamfer', icon: Icons.crop_16_9),
      ],
    ),
    const RadialMenuItem(
      id: 'constraint',
      label: 'Constrain',
      icon: Icons.lock_outline,
    ),
    const RadialMenuItem(
      id: 'measure',
      label: 'Measure',
      icon: Icons.straighten,
    ),
  ];

  @override
  State<RadialMenuV2> createState() => _RadialMenuV2State();
}

class _RadialMenuV2State extends State<RadialMenuV2> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _subController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  List<RadialMenuItem> _currentItems = [];
  RadialMenuItem? _selectedParent;
  int? _hoveredIndex;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentItems = widget.customItems ?? RadialMenuV2.defaultItems;

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _subController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOut,
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _subController.dispose();
    super.dispose();
  }

  void _navigateToChildren(RadialMenuItem item) {
    if (item.children == null || item.children!.isEmpty) return;

    setState(() {
      _selectedParent = item;
      _currentItems = item.children!;
      _hoveredIndex = null;
    });

    _subController.forward(from: 0);
  }

  void _navigateBack() {
    if (_selectedParent != null) {
      setState(() {
        _selectedParent = null;
        _currentItems = widget.customItems ?? RadialMenuV2.defaultItems;
        _hoveredIndex = null;
      });

      _subController.forward(from: 0);
    }
  }

  void _selectItem(RadialMenuItem item) {
    if (item.children != null && item.children!.isNotEmpty) {
      _navigateToChildren(item);
    } else {
      widget.onItemSelected(item.id);
      widget.onClose();
    }
  }

  Offset _getItemPosition(int index, int total, double radius) {
    final angle = (2 * math.pi * index / total) - math.pi / 2;
    return Offset(
      radius * math.cos(angle),
      radius * math.sin(angle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safePosition = _clampToScreen(widget.position, screenSize);

    return Stack(
      children: [
        // Backdrop
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            onPanStart: (_) => setState(() => _isDragging = true),
            onPanUpdate: (details) {
              if (_isDragging) {
                setState(() {
                  _dragOffset += details.delta;
                });
                _checkDragSelection(safePosition + _dragOffset);
              }
            },
            onPanEnd: (_) {
              if (_hoveredIndex != null) {
                _selectItem(_currentItems[_hoveredIndex!]);
              }
              setState(() => _isDragging = false);
            },
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Container(
                  color: Colors.black.withOpacity(0.4 * _fadeAnimation.value),
                );
              },
            ),
          ),
        ),
        // Menu
        Positioned(
          left: safePosition.dx - 150,
          top: safePosition.dy - 150,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background ring
                  _buildBackgroundRing(),
                  // Menu items
                  ..._buildMenuItems(),
                  // Center button
                  _buildCenterButton(),
                  // Hover indicator
                  if (_hoveredIndex != null) _buildHoverIndicator(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundRing() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Dune3DTheme.surface.withOpacity(0.95),
        border: Border.all(color: Dune3DTheme.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    final List<Widget> items = [];
    const radius = 85.0;
    const itemRadius = 28.0;

    for (int i = 0; i < _currentItems.length; i++) {
      final item = _currentItems[i];
      final position = _getItemPosition(i, _currentItems.length, radius);
      final isHovered = _hoveredIndex == i;

      items.add(
        Transform.translate(
          offset: position,
          child: _RadialMenuItemWidget(
            item: item,
            isHovered: isHovered,
            hasChildren: item.children != null && item.children!.isNotEmpty,
            onTap: () => _selectItem(item),
            onHover: (hovered) {
              setState(() {
                _hoveredIndex = hovered ? i : null;
              });
            },
          ),
        ),
      );
    }

    return items;
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: _selectedParent != null ? _navigateBack : widget.onClose,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: Dune3DAnimations.fast,
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: _selectedParent != null
                  ? [Dune3DTheme.surfaceLight, Dune3DTheme.surface]
                  : [Dune3DTheme.accent, Dune3DTheme.accentDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: Dune3DTheme.elevation2,
          ),
          child: Icon(
            _selectedParent != null ? Icons.arrow_back : Icons.close,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildHoverIndicator() {
    if (_hoveredIndex == null) return const SizedBox.shrink();

    final position = _getItemPosition(_hoveredIndex!, _currentItems.length, 85);
    final item = _currentItems[_hoveredIndex!];

    return Transform.translate(
      offset: Offset(0, 130),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dune3DTheme.spacingM,
          vertical: Dune3DTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: Dune3DTheme.surfaceBright,
          borderRadius: BorderRadius.circular(Dune3DTheme.radiusMedium),
          boxShadow: Dune3DTheme.elevation1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 16, color: item.color ?? Dune3DTheme.textPrimary),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: Dune3DTheme.bodySmall.copyWith(color: Dune3DTheme.textPrimary),
            ),
            if (item.children != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 14, color: Dune3DTheme.textTertiary),
            ],
          ],
        ),
      ),
    );
  }

  Offset _clampToScreen(Offset position, Size screenSize) {
    const padding = 160.0;
    return Offset(
      position.dx.clamp(padding, screenSize.width - padding),
      position.dy.clamp(padding, screenSize.height - padding),
    );
  }

  void _checkDragSelection(Offset center) {
    const radius = 85.0;
    final dragPos = center + _dragOffset - widget.position;
    final distance = dragPos.distance;

    if (distance > 30 && distance < 130) {
      final angle = math.atan2(dragPos.dy, dragPos.dx) + math.pi / 2;
      final normalizedAngle = angle < 0 ? angle + 2 * math.pi : angle;
      final segmentAngle = 2 * math.pi / _currentItems.length;
      final index = (normalizedAngle / segmentAngle).floor() % _currentItems.length;

      setState(() {
        _hoveredIndex = index;
      });
    } else {
      setState(() {
        _hoveredIndex = null;
      });
    }
  }
}

class _RadialMenuItemWidget extends StatefulWidget {
  final RadialMenuItem item;
  final bool isHovered;
  final bool hasChildren;
  final VoidCallback onTap;
  final Function(bool) onHover;

  const _RadialMenuItemWidget({
    required this.item,
    required this.isHovered,
    required this.hasChildren,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<_RadialMenuItemWidget> createState() => _RadialMenuItemWidgetState();
}

class _RadialMenuItemWidgetState extends State<_RadialMenuItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Dune3DAnimations.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(_RadialMenuItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHovered && !oldWidget.isHovered) {
      _controller.forward();
    } else if (!widget.isHovered && oldWidget.isHovered) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.onHover(true),
      onExit: (_) => widget.onHover(false),
      child: GestureDetector(
        onTap: widget.item.isEnabled ? widget.onTap : null,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isHovered
                  ? (widget.item.color ?? Dune3DTheme.accent)
                  : Dune3DTheme.surfaceLight,
              border: Border.all(
                color: widget.isHovered
                    ? (widget.item.color ?? Dune3DTheme.accent)
                    : Dune3DTheme.border,
                width: 2,
              ),
              boxShadow: widget.isHovered ? Dune3DTheme.elevation2 : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  widget.item.icon,
                  size: 24,
                  color: widget.isHovered
                      ? Colors.white
                      : (widget.item.color ?? Dune3DTheme.textPrimary),
                ),
                if (widget.hasChildren)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isHovered
                            ? Colors.white.withOpacity(0.3)
                            : Dune3DTheme.surfaceBright,
                      ),
                      child: Icon(
                        Icons.more_horiz,
                        size: 10,
                        color: widget.isHovered ? Colors.white : Dune3DTheme.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
