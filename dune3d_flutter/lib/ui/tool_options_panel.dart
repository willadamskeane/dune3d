import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import '../core/tools.dart';

/// Context-sensitive tool options panel
class ToolOptionsPanel extends StatelessWidget {
  final ToolType currentTool;
  final bool isDrawing;
  final Map<String, dynamic> toolState;
  final Function(String, dynamic) onOptionChanged;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ToolOptionsPanel({
    super.key,
    required this.currentTool,
    this.isDrawing = false,
    this.toolState = const {},
    required this.onOptionChanged,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Only show when drawing or when tool has options
    if (!_hasOptions) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(Dune3DTheme.spacingM),
      decoration: Dune3DDecorations.floatingPanel(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: Dune3DTheme.spacingM),
          ..._buildOptions(),
          if (isDrawing && (onConfirm != null || onCancel != null)) ...[
            const SizedBox(height: Dune3DTheme.spacingM),
            _buildActions(),
          ],
        ],
      ),
    );
  }

  bool get _hasOptions {
    switch (currentTool) {
      case ToolType.line:
      case ToolType.circle:
      case ToolType.rectangle:
      case ToolType.arc:
        return true;
      default:
        return false;
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          _getToolIcon(),
          size: 16,
          color: Dune3DTheme.accent,
        ),
        const SizedBox(width: Dune3DTheme.spacingS),
        Text(
          _getToolName(),
          style: Dune3DTheme.heading3,
        ),
        if (isDrawing) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dune3DTheme.spacingS,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Dune3DTheme.sketchPreview.withOpacity(0.2),
              borderRadius: BorderRadius.circular(Dune3DTheme.radiusSmall),
            ),
            child: Text(
              'Drawing',
              style: Dune3DTheme.caption.copyWith(
                color: Dune3DTheme.sketchPreview,
              ),
            ),
          ),
        ],
      ],
    );
  }

  IconData _getToolIcon() {
    switch (currentTool) {
      case ToolType.line:
        return Icons.timeline;
      case ToolType.circle:
        return Icons.circle_outlined;
      case ToolType.rectangle:
        return Icons.crop_square_outlined;
      case ToolType.arc:
        return Icons.architecture;
      case ToolType.select:
        return Icons.near_me_outlined;
      default:
        return Icons.build;
    }
  }

  String _getToolName() {
    switch (currentTool) {
      case ToolType.line:
        return 'Line Tool';
      case ToolType.circle:
        return 'Circle Tool';
      case ToolType.rectangle:
        return 'Rectangle Tool';
      case ToolType.arc:
        return 'Arc Tool';
      case ToolType.select:
        return 'Select Tool';
      default:
        return currentTool.name;
    }
  }

  List<Widget> _buildOptions() {
    switch (currentTool) {
      case ToolType.line:
        return _buildLineOptions();
      case ToolType.circle:
        return _buildCircleOptions();
      case ToolType.rectangle:
        return _buildRectangleOptions();
      case ToolType.arc:
        return _buildArcOptions();
      default:
        return [];
    }
  }

  List<Widget> _buildLineOptions() {
    return [
      _OptionToggle(
        label: 'Construction',
        value: toolState['isConstruction'] ?? false,
        onChanged: (v) => onOptionChanged('isConstruction', v),
      ),
      const SizedBox(height: Dune3DTheme.spacingS),
      _OptionToggle(
        label: 'Auto-constrain H/V',
        value: toolState['autoConstrain'] ?? true,
        onChanged: (v) => onOptionChanged('autoConstrain', v),
      ),
      if (isDrawing) ...[
        const SizedBox(height: Dune3DTheme.spacingM),
        _buildLengthDisplay(),
        const SizedBox(height: Dune3DTheme.spacingS),
        _buildAngleDisplay(),
      ],
    ];
  }

  List<Widget> _buildCircleOptions() {
    return [
      _OptionToggle(
        label: 'Construction',
        value: toolState['isConstruction'] ?? false,
        onChanged: (v) => onOptionChanged('isConstruction', v),
      ),
      if (isDrawing) ...[
        const SizedBox(height: Dune3DTheme.spacingM),
        _buildRadiusDisplay(),
        const SizedBox(height: Dune3DTheme.spacingS),
        _buildDiameterDisplay(),
      ],
    ];
  }

  List<Widget> _buildRectangleOptions() {
    return [
      _OptionToggle(
        label: 'Construction',
        value: toolState['isConstruction'] ?? false,
        onChanged: (v) => onOptionChanged('isConstruction', v),
      ),
      _OptionToggle(
        label: 'Center mode',
        value: toolState['centerMode'] ?? false,
        onChanged: (v) => onOptionChanged('centerMode', v),
      ),
      if (isDrawing) ...[
        const SizedBox(height: Dune3DTheme.spacingM),
        _buildWidthDisplay(),
        const SizedBox(height: Dune3DTheme.spacingS),
        _buildHeightDisplay(),
      ],
    ];
  }

  List<Widget> _buildArcOptions() {
    final clickCount = toolState['clickCount'] ?? 0;
    String hint = 'Click to set start point';
    if (clickCount == 1) hint = 'Click to set midpoint';
    if (clickCount == 2) hint = 'Click to set end point';

    return [
      _OptionToggle(
        label: 'Construction',
        value: toolState['isConstruction'] ?? false,
        onChanged: (v) => onOptionChanged('isConstruction', v),
      ),
      const SizedBox(height: Dune3DTheme.spacingM),
      Container(
        padding: const EdgeInsets.all(Dune3DTheme.spacingS),
        decoration: BoxDecoration(
          color: Dune3DTheme.surfaceLight,
          borderRadius: BorderRadius.circular(Dune3DTheme.radiusSmall),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 14, color: Dune3DTheme.textTertiary),
            const SizedBox(width: Dune3DTheme.spacingS),
            Text(hint, style: Dune3DTheme.caption),
          ],
        ),
      ),
    ];
  }

  Widget _buildLengthDisplay() {
    final length = toolState['length'] ?? 0.0;
    return _DimensionDisplay(
      label: 'Length',
      value: length,
      unit: 'mm',
    );
  }

  Widget _buildAngleDisplay() {
    final angle = toolState['angle'] ?? 0.0;
    return _DimensionDisplay(
      label: 'Angle',
      value: angle,
      unit: '\u00B0',
    );
  }

  Widget _buildRadiusDisplay() {
    final radius = toolState['radius'] ?? 0.0;
    return _DimensionDisplay(
      label: 'Radius',
      value: radius,
      unit: 'mm',
    );
  }

  Widget _buildDiameterDisplay() {
    final radius = toolState['radius'] ?? 0.0;
    return _DimensionDisplay(
      label: 'Diameter',
      value: radius * 2,
      unit: 'mm',
    );
  }

  Widget _buildWidthDisplay() {
    final width = toolState['width'] ?? 0.0;
    return _DimensionDisplay(
      label: 'Width',
      value: width,
      unit: 'mm',
    );
  }

  Widget _buildHeightDisplay() {
    final height = toolState['height'] ?? 0.0;
    return _DimensionDisplay(
      label: 'Height',
      value: height,
      unit: 'mm',
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (onCancel != null)
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: Dune3DTheme.textSecondary,
                side: BorderSide(color: Dune3DTheme.border),
                padding: const EdgeInsets.symmetric(vertical: Dune3DTheme.spacingS),
              ),
              child: const Text('Cancel'),
            ),
          ),
        if (onCancel != null && onConfirm != null)
          const SizedBox(width: Dune3DTheme.spacingS),
        if (onConfirm != null)
          Expanded(
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Dune3DTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: Dune3DTheme.spacingS),
              ),
              child: const Text('Done'),
            ),
          ),
      ],
    );
  }
}

class _OptionToggle extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool) onChanged;

  const _OptionToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Dune3DTheme.bodySmall),
        Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

class _DimensionDisplay extends StatelessWidget {
  final String label;
  final double value;
  final String unit;

  const _DimensionDisplay({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dune3DTheme.spacingM,
        vertical: Dune3DTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: Dune3DTheme.surfaceLight,
        borderRadius: BorderRadius.circular(Dune3DTheme.radiusSmall),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Dune3DTheme.caption),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: Dune3DTheme.dimension.copyWith(color: Dune3DTheme.accent),
          ),
        ],
      ),
    );
  }
}

/// Inline dimension input overlay for direct value entry
class DimensionInputOverlay extends StatefulWidget {
  final Offset position;
  final String label;
  final double initialValue;
  final String unit;
  final Function(double) onSubmit;
  final VoidCallback onCancel;

  const DimensionInputOverlay({
    super.key,
    required this.position,
    required this.label,
    required this.initialValue,
    this.unit = 'mm',
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<DimensionInputOverlay> createState() => _DimensionInputOverlayState();
}

class _DimensionInputOverlayState extends State<DimensionInputOverlay> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toStringAsFixed(1));
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_controller.text);
    if (value != null && value > 0) {
      widget.onSubmit(value);
    } else {
      widget.onCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - 60,
      top: widget.position.dy - 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(Dune3DTheme.spacingS),
          decoration: Dune3DDecorations.floatingPanel(),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: Dune3DTheme.dimension,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Dune3DTheme.spacingS,
                      vertical: Dune3DTheme.spacingXS,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Dune3DTheme.radiusSmall),
                      borderSide: BorderSide(color: Dune3DTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Dune3DTheme.radiusSmall),
                      borderSide: BorderSide(color: Dune3DTheme.accent),
                    ),
                    suffixText: widget.unit,
                    suffixStyle: Dune3DTheme.caption,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _submit,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Dune3DTheme.accent,
                    borderRadius: BorderRadius.circular(Dune3DTheme.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Constraint quick-add buttons that appear when drawing
class ConstraintQuickPanel extends StatelessWidget {
  final List<String> availableConstraints;
  final Function(String) onConstraintSelected;

  const ConstraintQuickPanel({
    super.key,
    required this.availableConstraints,
    required this.onConstraintSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (availableConstraints.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(Dune3DTheme.spacingS),
      decoration: Dune3DDecorations.floatingPanel(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: availableConstraints.map((constraint) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _ConstraintButton(
              constraint: constraint,
              onTap: () => onConstraintSelected(constraint),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ConstraintButton extends StatefulWidget {
  final String constraint;
  final VoidCallback onTap;

  const _ConstraintButton({
    required this.constraint,
    required this.onTap,
  });

  @override
  State<_ConstraintButton> createState() => _ConstraintButtonState();
}

class _ConstraintButtonState extends State<_ConstraintButton> {
  bool _isHovered = false;

  IconData _getIcon() {
    switch (widget.constraint) {
      case 'horizontal':
        return Icons.horizontal_rule;
      case 'vertical':
        return Icons.vertical_align_center;
      case 'perpendicular':
        return Icons.square_foot;
      case 'parallel':
        return Icons.view_stream;
      case 'tangent':
        return Icons.radio_button_unchecked;
      case 'equal':
        return Icons.drag_handle;
      case 'coincident':
        return Icons.fiber_manual_record;
      default:
        return Icons.lock_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.constraint.toUpperCase(),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: Dune3DAnimations.fast,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _isHovered ? Dune3DTheme.accent : Dune3DTheme.surfaceLight,
              borderRadius: BorderRadius.circular(Dune3DTheme.radiusSmall),
            ),
            child: Icon(
              _getIcon(),
              size: 16,
              color: _isHovered ? Colors.white : Dune3DTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
