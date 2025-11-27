import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cad_app/src/features/settings/presentation/settings_screen.dart';

void main() {
  group('AppSettings', () {
    test('default values are correct', () {
      const settings = AppSettings();

      expect(settings.themeMode, ThemeMode.system);
      expect(settings.msaaSamples, 4);
      expect(settings.tessellationDeflection, 0.1);
      expect(settings.stylusOnlyMode, false);
      expect(settings.showGrid, true);
      expect(settings.snapToGrid, true);
      expect(settings.gridSize, 10.0);
    });

    test('copyWith updates themeMode', () {
      const settings = AppSettings();
      final updated = settings.copyWith(themeMode: ThemeMode.dark);

      expect(updated.themeMode, ThemeMode.dark);
      expect(updated.msaaSamples, settings.msaaSamples);
    });

    test('copyWith updates msaaSamples', () {
      const settings = AppSettings();
      final updated = settings.copyWith(msaaSamples: 8);

      expect(updated.msaaSamples, 8);
    });

    test('copyWith updates tessellationDeflection', () {
      const settings = AppSettings();
      final updated = settings.copyWith(tessellationDeflection: 0.05);

      expect(updated.tessellationDeflection, 0.05);
    });

    test('copyWith updates stylusOnlyMode', () {
      const settings = AppSettings();
      final updated = settings.copyWith(stylusOnlyMode: true);

      expect(updated.stylusOnlyMode, true);
    });

    test('copyWith updates showGrid', () {
      const settings = AppSettings();
      final updated = settings.copyWith(showGrid: false);

      expect(updated.showGrid, false);
    });

    test('copyWith updates snapToGrid', () {
      const settings = AppSettings();
      final updated = settings.copyWith(snapToGrid: false);

      expect(updated.snapToGrid, false);
    });

    test('copyWith updates gridSize', () {
      const settings = AppSettings();
      final updated = settings.copyWith(gridSize: 25.0);

      expect(updated.gridSize, 25.0);
    });
  });

  group('AppSettingsNotifier', () {
    late ProviderContainer container;
    late AppSettingsNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(appSettingsProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has default values', () {
      final state = container.read(appSettingsProvider);

      expect(state.themeMode, ThemeMode.system);
    });

    test('setThemeMode updates state', () {
      notifier.setThemeMode(ThemeMode.dark);

      final state = container.read(appSettingsProvider);
      expect(state.themeMode, ThemeMode.dark);
    });

    test('setMsaaSamples updates state', () {
      notifier.setMsaaSamples(8);

      final state = container.read(appSettingsProvider);
      expect(state.msaaSamples, 8);
    });

    test('setTessellationDeflection updates state', () {
      notifier.setTessellationDeflection(0.5);

      final state = container.read(appSettingsProvider);
      expect(state.tessellationDeflection, 0.5);
    });

    test('setStylusOnlyMode updates state', () {
      notifier.setStylusOnlyMode(true);

      final state = container.read(appSettingsProvider);
      expect(state.stylusOnlyMode, true);
    });

    test('setShowGrid updates state', () {
      notifier.setShowGrid(false);

      final state = container.read(appSettingsProvider);
      expect(state.showGrid, false);
    });

    test('setSnapToGrid updates state', () {
      notifier.setSnapToGrid(false);

      final state = container.read(appSettingsProvider);
      expect(state.snapToGrid, false);
    });

    test('setGridSize updates state', () {
      notifier.setGridSize(50.0);

      final state = container.read(appSettingsProvider);
      expect(state.gridSize, 50.0);
    });

    test('resetToDefaults restores default values', () {
      notifier.setThemeMode(ThemeMode.dark);
      notifier.setMsaaSamples(8);
      notifier.setStylusOnlyMode(true);

      notifier.resetToDefaults();

      final state = container.read(appSettingsProvider);
      expect(state.themeMode, ThemeMode.system);
      expect(state.msaaSamples, 4);
      expect(state.stylusOnlyMode, false);
    });
  });
}
