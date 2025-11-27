import 'package:flutter/material.dart';

/// Dune3D Design System - Inspired by Shapr3D's clean, professional aesthetic
class Dune3DTheme {
  // Primary Colors
  static const Color background = Color(0xFF1A1A1E);
  static const Color surface = Color(0xFF242428);
  static const Color surfaceLight = Color(0xFF2E2E34);
  static const Color surfaceBright = Color(0xFF3A3A42);

  // Accent Colors
  static const Color accent = Color(0xFF4A9EFF);
  static const Color accentLight = Color(0xFF6BB3FF);
  static const Color accentDark = Color(0xFF2D7AD4);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF29B6F6);

  // CAD-specific Colors
  static const Color sketch = Color(0xFFFFFFFF);
  static const Color sketchSelected = Color(0xFF4A9EFF);
  static const Color sketchConstruction = Color(0xFFFF9800);
  static const Color sketchPreview = Color(0xFF4CAF50);
  static const Color sketchHover = Color(0xFF6BB3FF);
  static const Color constraint = Color(0xFFAB47BC);
  static const Color dimensionColor = Color(0xFF4A9EFF);

  // Grid Colors
  static const Color gridMinor = Color(0xFF2A2A30);
  static const Color gridMajor = Color(0xFF3A3A44);
  static const Color origin = Color(0xFF666666);
  static const Color axisX = Color(0xFFEF5350);
  static const Color axisY = Color(0xFF66BB6A);
  static const Color axisZ = Color(0xFF42A5F5);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF707070);
  static const Color textDisabled = Color(0xFF505050);

  // Border Colors
  static const Color border = Color(0xFF3A3A42);
  static const Color borderLight = Color(0xFF4A4A52);
  static const Color borderFocus = Color(0xFF4A9EFF);

  // Shadows
  static List<BoxShadow> elevation1 = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> elevation2 = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevation3 = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // Border Radius
  static const double radiusSmall = 4;
  static const double radiusMedium = 8;
  static const double radiusLarge = 12;
  static const double radiusXLarge = 16;

  // Spacing
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 12;
  static const double spacingL = 16;
  static const double spacingXL = 24;
  static const double spacingXXL = 32;

  // Icon Sizes
  static const double iconSmall = 16;
  static const double iconMedium = 20;
  static const double iconLarge = 24;
  static const double iconXLarge = 32;

  // Tool Button Size (for tablet touch targets)
  static const double toolButtonSize = 48;
  static const double toolButtonSizeLarge = 56;

  // Typography
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textTertiary,
    letterSpacing: 0.5,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.8,
  );

  static const TextStyle dimension = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: 'monospace',
  );

  // Material Theme Data
  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.dark(
      primary: accent,
      secondary: accentLight,
      surface: surface,
      onSurface: textPrimary,
      onPrimary: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      elevation: 0,
      titleTextStyle: heading2,
    ),
    iconTheme: const IconThemeData(
      color: textSecondary,
      size: iconMedium,
    ),
    textTheme: const TextTheme(
      headlineLarge: heading1,
      headlineMedium: heading2,
      titleMedium: heading3,
      bodyLarge: body,
      bodyMedium: bodySmall,
      labelSmall: caption,
    ),
    dividerTheme: const DividerThemeData(
      color: border,
      thickness: 1,
      space: 1,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: surfaceBright,
        borderRadius: BorderRadius.circular(radiusSmall),
        boxShadow: elevation2,
      ),
      textStyle: bodySmall,
      padding: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: accent,
      inactiveTrackColor: surfaceLight,
      thumbColor: accent,
      overlayColor: accent.withOpacity(0.2),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
    ),
  );
}

/// Custom decorations for CAD UI elements
class Dune3DDecorations {
  static BoxDecoration panel({bool elevated = false}) => BoxDecoration(
    color: Dune3DTheme.surface,
    borderRadius: BorderRadius.circular(Dune3DTheme.radiusMedium),
    border: Border.all(color: Dune3DTheme.border, width: 1),
    boxShadow: elevated ? Dune3DTheme.elevation2 : null,
  );

  static BoxDecoration toolButton({bool selected = false, bool hovered = false}) => BoxDecoration(
    color: selected
        ? Dune3DTheme.accent.withOpacity(0.2)
        : hovered
            ? Dune3DTheme.surfaceLight
            : Colors.transparent,
    borderRadius: BorderRadius.circular(Dune3DTheme.radiusSmall),
    border: Border.all(
      color: selected ? Dune3DTheme.accent : Colors.transparent,
      width: 1.5,
    ),
  );

  static BoxDecoration input({bool focused = false}) => BoxDecoration(
    color: Dune3DTheme.surfaceLight,
    borderRadius: BorderRadius.circular(Dune3DTheme.radiusSmall),
    border: Border.all(
      color: focused ? Dune3DTheme.borderFocus : Dune3DTheme.border,
      width: 1,
    ),
  );

  static BoxDecoration floatingPanel() => BoxDecoration(
    color: Dune3DTheme.surface.withOpacity(0.95),
    borderRadius: BorderRadius.circular(Dune3DTheme.radiusLarge),
    boxShadow: Dune3DTheme.elevation3,
    border: Border.all(color: Dune3DTheme.border, width: 1),
  );

  static BoxDecoration contextMenu() => BoxDecoration(
    color: Dune3DTheme.surface,
    borderRadius: BorderRadius.circular(Dune3DTheme.radiusMedium),
    boxShadow: Dune3DTheme.elevation3,
    border: Border.all(color: Dune3DTheme.border, width: 1),
  );
}

/// Animation durations
class Dune3DAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.easeOutBack;
  static const Curve sharpCurve = Curves.easeOut;
}
