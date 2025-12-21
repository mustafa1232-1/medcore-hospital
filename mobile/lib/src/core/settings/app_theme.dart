import 'package:flutter/material.dart';
import 'app_settings_store.dart';

class AppTheme {
  static ThemeData build(AppSettingsStore s, Brightness brightness) {
    final seed = s.effectiveSeed;
    final isDark = brightness == Brightness.dark;

    final baseScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    // Medical-like surfaces: cleaner whites / calm dark
    final surface = isDark ? const Color(0xFF0E141B) : const Color(0xFFF7FAFC);
    final surface2 = isDark ? const Color(0xFF121B24) : const Color(0xFFFFFFFF);

    final scheme = baseScheme.copyWith(
      surface: surface,
      surfaceContainerHighest: surface2,
    );

    final compact = s.compactUi;
    final isNeon = s.themeStyle == AppThemeStyle.neon;

    final radius = BorderRadius.circular(16);

    final theme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
    );

    OutlineInputBorder outline([Color? c]) => OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: c ?? theme.dividerColor.withAlpha(60)),
    );

    return theme.copyWith(
      dividerColor: theme.dividerColor.withAlpha(isDark ? 60 : 40),

      appBarTheme: theme.appBarTheme.copyWith(
        centerTitle: false,
        elevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: theme.cardTheme.copyWith(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isNeon
                ? scheme.primary.withAlpha(isDark ? 120 : 90)
                : theme.dividerColor.withAlpha(isDark ? 70 : 45),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        isDense: compact,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withAlpha(isDark ? 120 : 200),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: compact ? 12 : 14,
        ),
        border: outline(),
        enabledBorder: outline(theme.dividerColor.withAlpha(isDark ? 80 : 55)),
        focusedBorder: outline(scheme.primary.withAlpha(160)),
        errorBorder: outline(scheme.error.withAlpha(160)),
        focusedErrorBorder: outline(scheme.error.withAlpha(200)),
      ),

      chipTheme: theme.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(
          color: isNeon
              ? scheme.primary.withAlpha(120)
              : theme.dividerColor.withAlpha(isDark ? 70 : 45),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(
            color: theme.dividerColor.withAlpha(isDark ? 90 : 60),
          ),
        ),
      ),

      navigationRailTheme: theme.navigationRailTheme.copyWith(
        backgroundColor: scheme.surface,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        selectedLabelTextStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
