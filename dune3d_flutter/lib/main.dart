import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/core.dart';
import 'core/model_3d.dart';
import 'ui/theme.dart';
import 'ui/editor_viewport.dart';
import 'ui/radial_menu_v2.dart';
import 'ui/side_toolbar.dart';
import 'ui/viewport_3d.dart';
import 'ui/feature_timeline.dart';
import 'ui/extrude_panel.dart';
import 'ui/tool_options_panel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Dune3DTheme.background,
  ));
  runApp(const Dune3DApp());
}

class Dune3DApp extends StatelessWidget {
  const Dune3DApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dune 3D',
      debugShowCheckedModeBanner: false,
      theme: Dune3DTheme.themeData,
      home: const MainScreen(),
    );
  }
}

/// Main app view mode
enum ViewMode {
  sketch,      // 2D sketching view
  model,       // 3D modeling view
  split,       // Split view (both)
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  // View state
  ViewMode _viewMode = ViewMode.sketch;
  bool _showFeatureTimeline = true;

  // Radial menu state
  Offset? _radialMenuPosition;

  // Sketch state
  late SketchDocument _document;
  late SketchTool _currentTool;
  ToolType _currentToolType = ToolType.select;

  // 3D state
  final List<Operation3D> _operations = [];
  final List<Mesh3D> _meshes = [];
  int? _selectedOperationIndex;

  // Extrude panel state
  bool _showExtrudePanel = false;
  double _extrudeDistance = 50.0;
  ExtrudeMode _extrudeMode = ExtrudeMode.single;

  // Animation controllers
  late AnimationController _viewTransitionController;

  // Viewport key for accessing state
  final GlobalKey<EditorViewportState> _viewportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _document = SketchDocument(name: 'New Design');
    _currentTool = ToolFactory.createTool(_currentToolType, _document);

    _viewTransitionController = AnimationController(
      vsync: this,
      duration: Dune3DAnimations.normal,
    );
  }

  @override
  void dispose() {
    _viewTransitionController.dispose();
    super.dispose();
  }

  void _setTool(ToolType type) {
    setState(() {
      _currentTool.cancel();
      _currentToolType = type;
      _currentTool = ToolFactory.createTool(type, _document);
    });
  }

  void _showRadialMenu(Offset position) {
    setState(() {
      _radialMenuPosition = position;
    });
  }

  void _hideRadialMenu() {
    setState(() {
      _radialMenuPosition = null;
    });
  }

  void _handleToolSelection(String toolId) {
    switch (toolId) {
      case 'select':
        _setTool(ToolType.select);
        break;
      case 'line':
        _setTool(ToolType.line);
        break;
      case 'circle':
        _setTool(ToolType.circle);
        break;
      case 'rect':
        _setTool(ToolType.rectangle);
        break;
      case 'arc':
        _setTool(ToolType.arc);
        break;
      case 'point':
        _setTool(ToolType.point);
        break;
      case 'trim':
        _setTool(ToolType.trim);
        break;
      case 'delete':
        if (_document.hasSelection) {
          _document.removeSelectedEntities();
        } else {
          _setTool(ToolType.delete);
        }
        break;
      case 'extrude':
        _startExtrude();
        break;
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Escape - cancel current tool or close panels
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_showExtrudePanel) {
          _cancelExtrude();
        } else {
          _currentTool.cancel();
          _setTool(ToolType.select);
        }
      }
      // Delete - remove selected entities
      else if (event.logicalKey == LogicalKeyboardKey.delete ||
          event.logicalKey == LogicalKeyboardKey.backspace) {
        _document.removeSelectedEntities();
      }
      // Ctrl+Z - undo
      else if (event.logicalKey == LogicalKeyboardKey.keyZ &&
          HardwareKeyboard.instance.isControlPressed) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          _document.redo();
        } else {
          _document.undo();
        }
      }
      // Ctrl+A - select all
      else if (event.logicalKey == LogicalKeyboardKey.keyA &&
          HardwareKeyboard.instance.isControlPressed) {
        _document.selectAll();
      }
      // E - Extrude
      else if (event.logicalKey == LogicalKeyboardKey.keyE) {
        _startExtrude();
      }
      // Tab - toggle view mode
      else if (event.logicalKey == LogicalKeyboardKey.tab) {
        _toggleViewMode();
      }
      // Tool shortcuts
      else if (event.logicalKey == LogicalKeyboardKey.keyL) {
        _setTool(ToolType.line);
      } else if (event.logicalKey == LogicalKeyboardKey.keyC) {
        _setTool(ToolType.circle);
      } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
        _setTool(ToolType.rectangle);
      } else if (event.logicalKey == LogicalKeyboardKey.keyV) {
        _setTool(ToolType.select);
      } else if (event.logicalKey == LogicalKeyboardKey.keyA) {
        _setTool(ToolType.arc);
      }
    }
  }

  void _toggleViewMode() {
    setState(() {
      switch (_viewMode) {
        case ViewMode.sketch:
          _viewMode = ViewMode.model;
          break;
        case ViewMode.model:
          _viewMode = ViewMode.split;
          break;
        case ViewMode.split:
          _viewMode = ViewMode.sketch;
          break;
      }
    });
  }

  bool get _hasClosedSketch {
    // Check if there are closed shapes that can be extruded
    return _document.entities.any((e) =>
        e is RectangleEntity || e is CircleEntity);
  }

  void _startExtrude() {
    if (!_hasClosedSketch) {
      _showSnackBar('Draw a closed shape (rectangle or circle) first');
      return;
    }

    setState(() {
      _showExtrudePanel = true;
      _viewMode = ViewMode.split;
    });

    _updateExtrudePreview();
  }

  void _updateExtrudePreview() {
    // Get all closed shapes
    final closedShapes = _document.entities
        .where((e) => e is RectangleEntity || e is CircleEntity)
        .toList();

    if (closedShapes.isEmpty) return;

    // Create preview extrusion
    final extrudeOp = ExtrudeOperation(
      id: 'preview',
      distance: _extrudeDistance,
      mode: _extrudeMode,
      profileEntityIds: closedShapes.map((e) => e.id).toList(),
    );

    final mesh = extrudeOp.generateMesh(closedShapes);

    setState(() {
      _meshes.clear();
      _meshes.add(mesh);
    });
  }

  void _confirmExtrude() {
    final closedShapes = _document.entities
        .where((e) => e is RectangleEntity || e is CircleEntity)
        .toList();

    if (closedShapes.isEmpty) return;

    final extrudeOp = ExtrudeOperation(
      id: 'extrude_${DateTime.now().millisecondsSinceEpoch}',
      distance: _extrudeDistance,
      mode: _extrudeMode,
      profileEntityIds: closedShapes.map((e) => e.id).toList(),
    );

    final mesh = extrudeOp.generateMesh(closedShapes);

    setState(() {
      _operations.add(extrudeOp);
      _meshes.clear();
      _meshes.add(mesh);
      _showExtrudePanel = false;
      _viewMode = ViewMode.model;
    });

    _showSnackBar('Extrusion created successfully');
  }

  void _cancelExtrude() {
    setState(() {
      _showExtrudePanel = false;
      _meshes.clear();
      if (_operations.isEmpty) {
        _viewMode = ViewMode.sketch;
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: Dune3DTheme.surfaceBright,
      ),
    );
  }

  List<FeatureItem> get _featureItems {
    final items = <FeatureItem>[];

    // Add sketch as first item
    if (_document.entityCount > 0) {
      items.add(FeatureItem(
        id: 'sketch_1',
        name: 'Sketch 1',
        type: 'sketch',
        icon: Icons.edit_outlined,
        details: ['${_document.entityCount} entities'],
      ));
    }

    // Add operations
    for (final op in _operations) {
      items.add(FeatureItem.fromOperation(op));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Stack(
          children: [
            Row(
              children: [
                // Side Toolbar
                SideToolbar(
                  currentTool: _currentToolType,
                  onToolSelected: _setTool,
                  onExtrude: _startExtrude,
                  hasSelection: _document.hasSelection,
                  hasClosedSketch: _hasClosedSketch,
                ),
                // Main Content Area
                Expanded(
                  child: _buildMainContent(),
                ),
                // Feature Timeline (right side)
                if (_showFeatureTimeline)
                  FeatureTimeline(
                    features: _featureItems,
                    selectedIndex: _selectedOperationIndex,
                    onSelect: (index) {
                      setState(() {
                        _selectedOperationIndex = index;
                      });
                    },
                    onVisibilityChanged: (index, visible) {
                      // Toggle visibility
                    },
                    onAddSketch: () {
                      setState(() {
                        _viewMode = ViewMode.sketch;
                      });
                    },
                    onAddExtrude: _startExtrude,
                  ),
              ],
            ),
            // Radial Menu
            if (_radialMenuPosition != null)
              RadialMenuV2(
                position: _radialMenuPosition!,
                onClose: _hideRadialMenu,
                onItemSelected: (toolId) {
                  _handleToolSelection(toolId);
                },
              ),
            // Extrude Panel
            if (_showExtrudePanel)
              Positioned(
                top: Dune3DTheme.spacingL,
                right: _showFeatureTimeline ? 280 : Dune3DTheme.spacingL,
                child: ExtrudePanel(
                  initialDistance: _extrudeDistance,
                  initialMode: _extrudeMode,
                  onUpdate: (distance, mode, secondDistance) {
                    setState(() {
                      _extrudeDistance = distance;
                      _extrudeMode = mode;
                    });
                    _updateExtrudePreview();
                  },
                  onConfirm: _confirmExtrude,
                  onCancel: _cancelExtrude,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_viewMode) {
      case ViewMode.sketch:
        return _buildSketchView();
      case ViewMode.model:
        return _build3DView();
      case ViewMode.split:
        return _buildSplitView();
    }
  }

  Widget _buildSketchView() {
    return Column(
      children: [
        _buildViewModeBar(),
        Expanded(
          child: Stack(
            children: [
              // The Viewport
              Positioned.fill(
                child: GestureDetector(
                  onLongPressStart: (details) {
                    _showRadialMenu(details.globalPosition);
                  },
                  child: EditorViewport(
                    key: _viewportKey,
                    document: _document,
                    currentTool: _currentTool,
                  ),
                ),
              ),
              // Quick toolbar (floating)
              Positioned(
                top: Dune3DTheme.spacingL,
                left: 0,
                right: 0,
                child: Center(
                  child: QuickToolbar(
                    currentTool: _currentToolType,
                    onToolSelected: _setTool,
                    onUndo: _document.canUndo ? () => _document.undo() : null,
                    onRedo: _document.canRedo ? () => _document.redo() : null,
                    canUndo: _document.canUndo,
                    canRedo: _document.canRedo,
                  ),
                ),
              ),
              // Tool options panel
              if (_currentTool.isDrawing)
                Positioned(
                  bottom: Dune3DTheme.spacingXL + 48,
                  left: Dune3DTheme.spacingL,
                  child: ToolOptionsPanel(
                    currentTool: _currentToolType,
                    isDrawing: _currentTool.isDrawing,
                    onOptionChanged: (key, value) {
                      // Handle option changes
                    },
                    onCancel: () {
                      _currentTool.cancel();
                      setState(() {});
                    },
                  ),
                ),
              // Status bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildStatusBar(),
              ),
              // Floating Action Button for radial menu
              Positioned(
                bottom: Dune3DTheme.spacingXL + 48,
                right: Dune3DTheme.spacingL,
                child: _RadialMenuFAB(
                  onPressed: () {
                    _showRadialMenu(
                      MediaQuery.of(context).size.center(Offset.zero),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _build3DView() {
    return Column(
      children: [
        _buildViewModeBar(),
        Expanded(
          child: Viewport3D(
            meshes: _meshes,
            operations: _operations,
            selectedOperationIndex: _selectedOperationIndex,
            onOperationSelected: (index) {
              setState(() {
                _selectedOperationIndex = index;
              });
            },
            onRequestExtrude: _hasClosedSketch ? _startExtrude : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSplitView() {
    return Column(
      children: [
        _buildViewModeBar(),
        Expanded(
          child: Row(
            children: [
              // Sketch view (left)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Dune3DTheme.border, width: 1),
                    ),
                  ),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onLongPressStart: (details) {
                          _showRadialMenu(details.globalPosition);
                        },
                        child: EditorViewport(
                          document: _document,
                          currentTool: _currentTool,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildMiniStatusBar(),
                      ),
                    ],
                  ),
                ),
              ),
              // 3D view (right)
              Expanded(
                child: Viewport3D(
                  meshes: _meshes,
                  operations: _operations,
                  selectedOperationIndex: _selectedOperationIndex,
                  onOperationSelected: (index) {
                    setState(() {
                      _selectedOperationIndex = index;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewModeBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: Dune3DTheme.spacingM),
      decoration: BoxDecoration(
        color: Dune3DTheme.surface,
        border: Border(
          bottom: BorderSide(color: Dune3DTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Document name
          Text(
            _document.name,
            style: Dune3DTheme.heading3,
          ),
          const Spacer(),
          // View mode tabs
          _ViewModeTab(
            icon: Icons.edit_outlined,
            label: 'Sketch',
            isSelected: _viewMode == ViewMode.sketch,
            onTap: () => setState(() => _viewMode = ViewMode.sketch),
          ),
          const SizedBox(width: Dune3DTheme.spacingXS),
          _ViewModeTab(
            icon: Icons.view_in_ar,
            label: '3D',
            isSelected: _viewMode == ViewMode.model,
            onTap: () => setState(() => _viewMode = ViewMode.model),
          ),
          const SizedBox(width: Dune3DTheme.spacingXS),
          _ViewModeTab(
            icon: Icons.view_column,
            label: 'Split',
            isSelected: _viewMode == ViewMode.split,
            onTap: () => setState(() => _viewMode = ViewMode.split),
          ),
          const SizedBox(width: Dune3DTheme.spacingL),
          // Toggle feature timeline
          IconButton(
            icon: Icon(
              _showFeatureTimeline
                  ? Icons.view_sidebar
                  : Icons.view_sidebar_outlined,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _showFeatureTimeline = !_showFeatureTimeline;
              });
            },
            tooltip: 'Toggle Timeline',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dune3DTheme.spacingL,
        vertical: Dune3DTheme.spacingM,
      ),
      decoration: BoxDecoration(
        color: Dune3DTheme.surface,
        border: Border(
          top: BorderSide(color: Dune3DTheme.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Current tool indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dune3DTheme.spacingM,
              vertical: Dune3DTheme.spacingXS,
            ),
            decoration: BoxDecoration(
              color: Dune3DTheme.surfaceLight,
              borderRadius: BorderRadius.circular(Dune3DTheme.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getToolIcon(_currentToolType),
                  size: 14,
                  color: Dune3DTheme.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  _currentToolType.name.toUpperCase(),
                  style: Dune3DTheme.caption.copyWith(
                    color: Dune3DTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Dune3DTheme.spacingM),
          // Drawing status
          if (_currentTool.isDrawing)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Dune3DTheme.spacingS,
                vertical: Dune3DTheme.spacingXS,
              ),
              decoration: BoxDecoration(
                color: Dune3DTheme.sketchPreview.withOpacity(0.2),
                borderRadius: BorderRadius.circular(Dune3DTheme.radiusSmall),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Dune3DTheme.sketchPreview,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Drawing',
                    style: Dune3DTheme.caption.copyWith(
                      color: Dune3DTheme.sketchPreview,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          // Selection count
          if (_document.hasSelection)
            Text(
              '${_document.selectedEntityIds.length} selected',
              style: Dune3DTheme.caption,
            ),
          const SizedBox(width: Dune3DTheme.spacingM),
          // Entity count
          Text(
            '${_document.entityCount} entities',
            style: Dune3DTheme.caption,
          ),
          const SizedBox(width: Dune3DTheme.spacingM),
          // Hints
          Text(
            'Long press for menu',
            style: Dune3DTheme.caption.copyWith(
              color: Dune3DTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dune3DTheme.spacingM,
        vertical: Dune3DTheme.spacingS,
      ),
      color: Dune3DTheme.surface.withOpacity(0.9),
      child: Row(
        children: [
          Text(
            'Sketch',
            style: Dune3DTheme.caption.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${_document.entityCount} entities',
            style: Dune3DTheme.caption,
          ),
        ],
      ),
    );
  }

  IconData _getToolIcon(ToolType type) {
    switch (type) {
      case ToolType.select:
        return Icons.near_me_outlined;
      case ToolType.line:
        return Icons.timeline;
      case ToolType.circle:
        return Icons.circle_outlined;
      case ToolType.rectangle:
        return Icons.crop_square_outlined;
      case ToolType.arc:
        return Icons.architecture;
      case ToolType.point:
        return Icons.fiber_manual_record_outlined;
      case ToolType.trim:
        return Icons.content_cut;
      case ToolType.delete:
        return Icons.delete_outline;
    }
  }
}

class _ViewModeTab extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewModeTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ViewModeTab> createState() => _ViewModeTabState();
}

class _ViewModeTabState extends State<_ViewModeTab> {
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
            horizontal: Dune3DTheme.spacingM,
            vertical: Dune3DTheme.spacingS,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Dune3DTheme.accent.withOpacity(0.15)
                : _isHovered
                    ? Dune3DTheme.surfaceLight
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(Dune3DTheme.radiusSmall),
            border: Border.all(
              color: widget.isSelected ? Dune3DTheme.accent : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.isSelected
                    ? Dune3DTheme.accent
                    : Dune3DTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: Dune3DTheme.bodySmall.copyWith(
                  color: widget.isSelected
                      ? Dune3DTheme.accent
                      : Dune3DTheme.textSecondary,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadialMenuFAB extends StatefulWidget {
  final VoidCallback onPressed;

  const _RadialMenuFAB({required this.onPressed});

  @override
  State<_RadialMenuFAB> createState() => _RadialMenuFABState();
}

class _RadialMenuFABState extends State<_RadialMenuFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Dune3DAnimations.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Dune3DTheme.accent, Dune3DTheme.accentDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Dune3DTheme.accent.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.apps,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
