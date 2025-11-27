import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import '../core/model_3d.dart';

/// Interactive extrude operation panel (Shapr3D style)
class ExtrudePanel extends StatefulWidget {
  final double initialDistance;
  final ExtrudeMode initialMode;
  final Function(double distance, ExtrudeMode mode, double? secondDistance) onUpdate;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ExtrudePanel({
    super.key,
    this.initialDistance = 50.0,
    this.initialMode = ExtrudeMode.single,
    required this.onUpdate,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<ExtrudePanel> createState() => _ExtrudePanelState();
}

class _ExtrudePanelState extends State<ExtrudePanel> with SingleTickerProviderStateMixin {
  late double _distance;
  late double _secondDistance;
  late ExtrudeMode _mode;
  late TextEditingController _distanceController;
  late TextEditingController _secondDistanceController;
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _distance = widget.initialDistance;
    _secondDistance = widget.initialDistance;
    _mode = widget.initialMode;
    _distanceController = TextEditingController(text: _distance.toStringAsFixed(1));
    _secondDistanceController = TextEditingController(text: _secondDistance.toStringAsFixed(1));

    _animController = AnimationController(
      vsync: this,
      duration: Dune3DAnimations.normal,
    );
    _slideAnimation = CurvedAnimation(
      parent: _animController,
      curve: Dune3DAnimations.defaultCurve,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _secondDistanceController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _updateDistance(double value) {
    setState(() {
      _distance = value.clamp(0.1, 500.0);
      _distanceController.text = _distance.toStringAsFixed(1);
    });
    _notifyUpdate();
  }

  void _updateSecondDistance(double value) {
    setState(() {
      _secondDistance = value.clamp(0.1, 500.0);
      _secondDistanceController.text = _secondDistance.toStringAsFixed(1);
    });
    _notifyUpdate();
  }

  void _updateMode(ExtrudeMode mode) {
    setState(() {
      _mode = mode;
    });
    _notifyUpdate();
  }

  void _notifyUpdate() {
    widget.onUpdate(
      _distance,
      _mode,
      _mode == ExtrudeMode.twoSided ? _secondDistance : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Container(
        width: 320,
        decoration: Dune3DDecorations.panel(elevated: true),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const Divider(height: 1, color: Dune3DTheme.border),
            Padding(
              padding: const EdgeInsets.all(Dune3DTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModeSelector(),
                  const SizedBox(height: Dune3DTheme.spacingL),
                  _buildDistanceInput(),
                  if (_mode == ExtrudeMode.twoSided) ...[
                    const SizedBox(height: Dune3DTheme.spacingM),
                    _buildSecondDistanceInput(),
                  ],
                  const SizedBox(height: Dune3DTheme.spacingL),
                  _buildDistanceSlider(),
                ],
              ),
            ),
            const Divider(height: 1, color: Dune3DTheme.border),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(Dune3DTheme.spacingM),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Dune3DTheme.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(Dune3DTheme.radiusSmall),
            ),
            child: Icon(
              Icons.open_in_full,
              size: 18,
              color: Dune3DTheme.accent,
            ),
          ),
          const SizedBox(width: Dune3DTheme.spacingM),
          Text('Extrude', style: Dune3DTheme.heading3),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: widget.onCancel,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Direction', style: Dune3DTheme.label),
        const SizedBox(height: Dune3DTheme.spacingS),
        Row(
          children: [
            Expanded(
              child: _ModeButton(
                icon: Icons.arrow_upward,
                label: 'Single',
                isSelected: _mode == ExtrudeMode.single,
                onTap: () => _updateMode(ExtrudeMode.single),
              ),
            ),
            const SizedBox(width: Dune3DTheme.spacingS),
            Expanded(
              child: _ModeButton(
                icon: Icons.unfold_more,
                label: 'Symmetric',
                isSelected: _mode == ExtrudeMode.symmetric,
                onTap: () => _updateMode(ExtrudeMode.symmetric),
              ),
            ),
            const SizedBox(width: Dune3DTheme.spacingS),
            Expanded(
              child: _ModeButton(
                icon: Icons.swap_vert,
                label: 'Two-Sided',
                isSelected: _mode == ExtrudeMode.twoSided,
                onTap: () => _updateMode(ExtrudeMode.twoSided),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistanceInput() {
    final label = _mode == ExtrudeMode.twoSided ? 'Distance (Up)' : 'Distance';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Dune3DTheme.label),
        const SizedBox(height: Dune3DTheme.spacingS),
        _DimensionInput(
          controller: _distanceController,
          suffix: 'mm',
          onChanged: (value) {
            final parsed = double.tryParse(value);
            if (parsed != null) {
              _updateDistance(parsed);
            }
          },
          onIncrement: () => _updateDistance(_distance + 1),
          onDecrement: () => _updateDistance(_distance - 1),
        ),
      ],
    );
  }

  Widget _buildSecondDistanceInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Distance (Down)', style: Dune3DTheme.label),
        const SizedBox(height: Dune3DTheme.spacingS),
        _DimensionInput(
          controller: _secondDistanceController,
          suffix: 'mm',
          onChanged: (value) {
            final parsed = double.tryParse(value);
            if (parsed != null) {
              _updateSecondDistance(parsed);
            }
          },
          onIncrement: () => _updateSecondDistance(_secondDistance + 1),
          onDecrement: () => _updateSecondDistance(_secondDistance - 1),
        ),
      ],
    );
  }

  Widget _buildDistanceSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Quick Adjust', style: Dune3DTheme.caption),
            Text(
              '${_distance.toStringAsFixed(1)} mm',
              style: Dune3DTheme.dimension.copyWith(color: Dune3DTheme.accent),
            ),
          ],
        ),
        const SizedBox(height: Dune3DTheme.spacingS),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          ),
          child: Slider(
            value: _distance,
            min: 0.1,
            max: 200,
            onChanged: _updateDistance,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0.1', style: Dune3DTheme.caption),
            Text('200', style: Dune3DTheme.caption),
          ],
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(Dune3DTheme.spacingM),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: Dune3DTheme.textSecondary,
                side: BorderSide(color: Dune3DTheme.border),
                padding: const EdgeInsets.symmetric(vertical: Dune3DTheme.spacingM),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: Dune3DTheme.spacingM),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: widget.onConfirm,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Apply'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Dune3DTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: Dune3DTheme.spacingM),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ModeButton> createState() => _ModeButtonState();
}

class _ModeButtonState extends State<_ModeButton> {
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
            vertical: Dune3DTheme.spacingM,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Dune3DTheme.accent.withOpacity(0.2)
                : _isHovered
                    ? Dune3DTheme.surfaceLight
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(Dune3DTheme.radiusSmall),
            border: Border.all(
              color: widget.isSelected ? Dune3DTheme.accent : Dune3DTheme.border,
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.isSelected ? Dune3DTheme.accent : Dune3DTheme.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 10,
                  color: widget.isSelected ? Dune3DTheme.accent : Dune3DTheme.textSecondary,
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

class _DimensionInput extends StatefulWidget {
  final TextEditingController controller;
  final String suffix;
  final Function(String) onChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _DimensionInput({
    required this.controller,
    required this.suffix,
    required this.onChanged,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  State<_DimensionInput> createState() => _DimensionInputState();
}

class _DimensionInputState extends State<_DimensionInput> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: Dune3DDecorations.input(focused: _isFocused),
      child: Row(
        children: [
          // Decrement button
          _StepButton(
            icon: Icons.remove,
            onTap: widget.onDecrement,
          ),
          // Input field
          Expanded(
            child: Focus(
              onFocusChange: (focused) => setState(() => _isFocused = focused),
              child: TextField(
                controller: widget.controller,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                style: Dune3DTheme.dimension,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  suffixText: widget.suffix,
                  suffixStyle: Dune3DTheme.caption,
                  isDense: true,
                ),
                onChanged: widget.onChanged,
              ),
            ),
          ),
          // Increment button
          _StepButton(
            icon: Icons.add,
            onTap: widget.onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: Container(
        width: 40,
        height: double.infinity,
        color: _isPressed ? Dune3DTheme.surfaceLight : Colors.transparent,
        child: Icon(
          widget.icon,
          size: 18,
          color: Dune3DTheme.textSecondary,
        ),
      ),
    );
  }
}

/// Quick extrude handle that appears near the sketch
class ExtrudeHandle extends StatefulWidget {
  final Offset position;
  final double distance;
  final Function(double) onDistanceChanged;
  final VoidCallback onTap;

  const ExtrudeHandle({
    super.key,
    required this.position,
    required this.distance,
    required this.onDistanceChanged,
    required this.onTap,
  });

  @override
  State<ExtrudeHandle> createState() => _ExtrudeHandleState();
}

class _ExtrudeHandleState extends State<ExtrudeHandle> {
  bool _isDragging = false;
  double _dragStartDistance = 0;
  Offset _dragStartPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - 24,
      top: widget.position.dy - 24,
      child: GestureDetector(
        onTap: widget.onTap,
        onVerticalDragStart: (details) {
          setState(() {
            _isDragging = true;
            _dragStartDistance = widget.distance;
            _dragStartPosition = details.globalPosition;
          });
        },
        onVerticalDragUpdate: (details) {
          if (_isDragging) {
            final delta = _dragStartPosition.dy - details.globalPosition.dy;
            final newDistance = (_dragStartDistance + delta * 0.5).clamp(0.1, 500.0);
            widget.onDistanceChanged(newDistance);
          }
        },
        onVerticalDragEnd: (_) {
          setState(() => _isDragging = false);
        },
        child: AnimatedContainer(
          duration: Dune3DAnimations.fast,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _isDragging ? Dune3DTheme.accent : Dune3DTheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: Dune3DTheme.accent,
              width: 2,
            ),
            boxShadow: Dune3DTheme.elevation2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.unfold_more,
                size: 20,
                color: _isDragging ? Colors.white : Dune3DTheme.accent,
              ),
              Text(
                '${widget.distance.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: _isDragging ? Colors.white : Dune3DTheme.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
