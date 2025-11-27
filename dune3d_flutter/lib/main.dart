import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/core.dart';
import 'ui/editor_viewport.dart';
import 'ui/radial_menu.dart';
import 'ui/constraints_panel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);
  runApp(const Dune3DApp());
}

class Dune3DApp extends StatelessWidget {
  const Dune3DApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dune 3D',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Navigation state
  int _selectedIndex = 0;

  // Radial menu state
  Offset? _radialMenuPosition;

  // Sketch state
  late SketchDocument _document;
  late SketchTool _currentTool;
  ToolType _currentToolType = ToolType.select;

  // Viewport key for accessing state
  final GlobalKey<EditorViewportState> _viewportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _document = SketchDocument(name: 'New Sketch');
    _currentTool = ToolFactory.createTool(_currentToolType, _document);
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
      case 'line':
        _setTool(ToolType.line);
        break;
      case 'circle':
        _setTool(ToolType.circle);
        break;
      case 'rect':
        _setTool(ToolType.rectangle);
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
      case 'select':
        _setTool(ToolType.select);
        break;
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Escape - cancel current tool
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _currentTool.cancel();
        _setTool(ToolType.select);
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
      // Tool shortcuts
      else if (event.logicalKey == LogicalKeyboardKey.keyL) {
        _setTool(ToolType.line);
      } else if (event.logicalKey == LogicalKeyboardKey.keyC) {
        _setTool(ToolType.circle);
      } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
        _setTool(ToolType.rectangle);
      } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
        _setTool(ToolType.select);
      }
    }
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade800),
        ),
      ),
      child: Row(
        children: [
          // File operations
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Document',
            onPressed: () {
              _document.clear();
              setState(() {});
            },
          ),
          const SizedBox(width: 8),
          const VerticalDivider(width: 1),
          const SizedBox(width: 8),

          // Edit operations
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo (Ctrl+Z)',
            onPressed: _document.canUndo ? () => _document.undo() : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Redo (Ctrl+Shift+Z)',
            onPressed: _document.canRedo ? () => _document.redo() : null,
          ),
          const SizedBox(width: 8),
          const VerticalDivider(width: 1),
          const SizedBox(width: 8),

          // Tool buttons
          _ToolButton(
            icon: Icons.touch_app,
            label: 'Select',
            isSelected: _currentToolType == ToolType.select,
            onPressed: () => _setTool(ToolType.select),
          ),
          _ToolButton(
            icon: Icons.edit,
            label: 'Line',
            isSelected: _currentToolType == ToolType.line,
            onPressed: () => _setTool(ToolType.line),
          ),
          _ToolButton(
            icon: Icons.circle_outlined,
            label: 'Circle',
            isSelected: _currentToolType == ToolType.circle,
            onPressed: () => _setTool(ToolType.circle),
          ),
          _ToolButton(
            icon: Icons.crop_square,
            label: 'Rectangle',
            isSelected: _currentToolType == ToolType.rectangle,
            onPressed: () => _setTool(ToolType.rectangle),
          ),
          _ToolButton(
            icon: Icons.content_cut,
            label: 'Trim',
            isSelected: _currentToolType == ToolType.trim,
            onPressed: () => _setTool(ToolType.trim),
          ),
          _ToolButton(
            icon: Icons.delete_outline,
            label: 'Delete',
            isSelected: _currentToolType == ToolType.delete,
            onPressed: () => _setTool(ToolType.delete),
          ),

          const Spacer(),

          // View operations
          IconButton(
            icon: const Icon(Icons.fit_screen),
            tooltip: 'Zoom to Fit',
            onPressed: () => _viewportKey.currentState?.zoomToFit(),
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            tooltip: 'Reset View',
            onPressed: () => _viewportKey.currentState?.resetView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSketchView() {
    return Column(
      children: [
        _buildToolbar(),
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

              // Floating Action Button for touch devices
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  heroTag: 'tools',
                  onPressed: () {
                    _showRadialMenu(
                        MediaQuery.of(context).size.center(Offset.zero));
                  },
                  child: const Icon(Icons.build),
                ),
              ),

              // Status bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: const Color(0xFF2D2D2D),
                  child: Row(
                    children: [
                      Text(
                        'Tool: ${_currentToolType.name.toUpperCase()}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 16),
                      if (_currentTool.isDrawing)
                        const Text(
                          'Drawing...',
                          style: TextStyle(fontSize: 12, color: Colors.yellow),
                        ),
                      const Spacer(),
                      Text(
                        'Selected: ${_document.selectedEntityIds.length}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConstraintsView() {
    return ConstraintsPanel(document: _document);
  }

  Widget _build3DView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.view_in_ar, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '3D View',
            style: TextStyle(fontSize: 24, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Create sketch entities first, then extrude to 3D',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
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
                // Side Toolbar (Left)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: const <NavigationRailDestination>[
                    NavigationRailDestination(
                      icon: Icon(Icons.mode_edit_outline),
                      selectedIcon: Icon(Icons.mode_edit),
                      label: Text('Sketch'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.transform),
                      selectedIcon: Icon(Icons.transform),
                      label: Text('Constraints'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.view_in_ar),
                      selectedIcon: Icon(Icons.view_in_ar_outlined),
                      label: Text('3D View'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                // Main Content Area
                Expanded(
                  child: _selectedIndex == 0
                      ? _buildSketchView()
                      : _selectedIndex == 1
                          ? _buildConstraintsView()
                          : _build3DView(),
                ),
              ],
            ),
            if (_radialMenuPosition != null)
              RadialMenu(
                position: _radialMenuPosition!,
                onClose: _hideRadialMenu,
                onItemSelected: (toolId) {
                  _handleToolSelection(toolId);
                },
              ),
          ],
        ),
      ),
    );
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
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : null,
          ),
        ),
      ),
    );
  }
}
