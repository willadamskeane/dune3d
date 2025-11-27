import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Application settings state.
class AppSettings {
  final ThemeMode themeMode;
  final int msaaSamples;
  final double tessellationDeflection;
  final bool stylusOnlyMode;
  final bool showGrid;
  final bool snapToGrid;
  final double gridSize;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.msaaSamples = 4,
    this.tessellationDeflection = 0.1,
    this.stylusOnlyMode = false,
    this.showGrid = true,
    this.snapToGrid = true,
    this.gridSize = 10.0,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? msaaSamples,
    double? tessellationDeflection,
    bool? stylusOnlyMode,
    bool? showGrid,
    bool? snapToGrid,
    double? gridSize,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      msaaSamples: msaaSamples ?? this.msaaSamples,
      tessellationDeflection:
          tessellationDeflection ?? this.tessellationDeflection,
      stylusOnlyMode: stylusOnlyMode ?? this.stylusOnlyMode,
      showGrid: showGrid ?? this.showGrid,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      gridSize: gridSize ?? this.gridSize,
    );
  }
}

/// Provider for application settings.
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier();
});

/// Notifier for app settings management.
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings());

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setMsaaSamples(int samples) {
    state = state.copyWith(msaaSamples: samples);
  }

  void setTessellationDeflection(double deflection) {
    state = state.copyWith(tessellationDeflection: deflection);
  }

  void setStylusOnlyMode(bool enabled) {
    state = state.copyWith(stylusOnlyMode: enabled);
  }

  void setShowGrid(bool show) {
    state = state.copyWith(showGrid: show);
  }

  void setSnapToGrid(bool snap) {
    state = state.copyWith(snapToGrid: snap);
  }

  void setGridSize(double size) {
    state = state.copyWith(gridSize: size);
  }

  void resetToDefaults() {
    state = const AppSettings();
  }
}

/// Settings screen for configuring app behavior.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            subtitle: Text(_themeModeLabel(settings.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, ref, settings.themeMode),
          ),
          _buildSectionHeader('Rendering'),
          ListTile(
            leading: const Icon(Icons.blur_on),
            title: const Text('Anti-aliasing (MSAA)'),
            subtitle: Text('${settings.msaaSamples}x'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showMsaaDialog(context, ref, settings.msaaSamples),
          ),
          ListTile(
            leading: const Icon(Icons.grain),
            title: const Text('Tessellation Quality'),
            subtitle: Text(_tessellationLabel(settings.tessellationDeflection)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: settings.tessellationDeflection,
              min: 0.01,
              max: 1.0,
              divisions: 10,
              label: settings.tessellationDeflection.toStringAsFixed(2),
              onChanged: (value) {
                ref
                    .read(appSettingsProvider.notifier)
                    .setTessellationDeflection(value);
              },
            ),
          ),
          _buildSectionHeader('Input'),
          SwitchListTile(
            secondary: const Icon(Icons.draw),
            title: const Text('Stylus Only Mode'),
            subtitle: const Text('Ignore touch input, only respond to stylus'),
            value: settings.stylusOnlyMode,
            onChanged: (value) {
              ref.read(appSettingsProvider.notifier).setStylusOnlyMode(value);
            },
          ),
          _buildSectionHeader('Grid'),
          SwitchListTile(
            secondary: const Icon(Icons.grid_on),
            title: const Text('Show Grid'),
            value: settings.showGrid,
            onChanged: (value) {
              ref.read(appSettingsProvider.notifier).setShowGrid(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.grid_4x4),
            title: const Text('Snap to Grid'),
            value: settings.snapToGrid,
            onChanged: settings.showGrid
                ? (value) {
                    ref.read(appSettingsProvider.notifier).setSnapToGrid(value);
                  }
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.space_bar),
            title: const Text('Grid Size'),
            subtitle: Text('${settings.gridSize.toStringAsFixed(1)} mm'),
            enabled: settings.showGrid,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: settings.gridSize,
              min: 1.0,
              max: 50.0,
              divisions: 49,
              label: '${settings.gridSize.toStringAsFixed(1)} mm',
              onChanged: settings.showGrid
                  ? (value) {
                      ref.read(appSettingsProvider.notifier).setGridSize(value);
                    }
                  : null,
            ),
          ),
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: const Text('0.1.0 (Development)'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Licenses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showLicensePage(context: context);
            },
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(appSettingsProvider.notifier).resetToDefaults();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings reset to defaults')),
                );
              },
              icon: const Icon(Icons.restore),
              label: const Text('Reset to Defaults'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
  }

  String _tessellationLabel(double deflection) {
    if (deflection <= 0.05) return 'Very High';
    if (deflection <= 0.1) return 'High';
    if (deflection <= 0.3) return 'Medium';
    if (deflection <= 0.6) return 'Low';
    return 'Very Low';
  }

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(_themeModeLabel(mode)),
              value: mode,
              groupValue: current,
              onChanged: (value) {
                if (value != null) {
                  ref.read(appSettingsProvider.notifier).setThemeMode(value);
                }
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showMsaaDialog(BuildContext context, WidgetRef ref, int current) {
    final options = [0, 2, 4, 8];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anti-aliasing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((samples) {
            return RadioListTile<int>(
              title: Text(samples == 0 ? 'Off' : '${samples}x MSAA'),
              value: samples,
              groupValue: current,
              onChanged: (value) {
                if (value != null) {
                  ref.read(appSettingsProvider.notifier).setMsaaSamples(value);
                }
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
