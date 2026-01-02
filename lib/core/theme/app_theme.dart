import 'package:flutter/material.dart';

import '../config/feature_flags.dart';
import '../providers/theme_provider.dart';
import 'design_tokens.dart';

class AppTheme {
  const AppTheme._();

  // Couleurs de base (backward compatibility)
  static const _background = Color(0xFF0A0A0A);
  static const _surface = Color(0xFF111111);
  static const _primary = Color(0xFFFFFFFF);
  static const _secondary = Color(0xFF9E9E9E);

  /// Thème dark original (backward compatibility)
  /// Utilisé si le système de palettes n'est pas activé
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: _primary,
        secondary: _secondary,
        surface: _surface,
        background: _background,
      ),
      scaffoldBackgroundColor: _background,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      cardColor: _surface,
      dividerColor: Colors.white12,
      splashFactory: NoSplash.splashFactory,
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.white70,
        textColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Colors.white60),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        side: BorderSide.none,
        labelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }

  /// Nouveau thème avec système de palettes
  /// Prend en compte la palette active du ThemeProvider
  static ThemeData darkWithPalette(ThemeProvider themeProvider) {
    // Si le système de palettes n'est pas activé, retourner l'ancien thème
    if (!FeatureFlags.useColorPalettes) {
      return dark();
    }

    final base = ThemeData.dark(useMaterial3: true);
    final colors = themeProvider.colors;

    return base.copyWith(
      // ColorScheme enrichi avec les couleurs de la palette
      colorScheme: ColorScheme.dark(
        primary: colors.primary,
        secondary: colors.navigation,
        tertiary: colors.info,
        surface: DesignTokens.surface,
        background: DesignTokens.background,
        error: colors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onError: Colors.white,
        // Extensions personnalisées
        surfaceContainerHighest: DesignTokens.surface,
        onSurfaceVariant: Colors.white70,
      ),

      scaffoldBackgroundColor: DesignTokens.background,

      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),

      cardColor: DesignTokens.surface,
      dividerColor: Colors.white12,
      splashFactory: NoSplash.splashFactory,

      listTileTheme: const ListTileThemeData(
        iconColor: Colors.white70,
        textColor: Colors.white,
      ),

      // Input decoration avec design tokens
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: DesignTokens.opacityVeryLow),
        contentPadding: EdgeInsets.symmetric(
          horizontal: DesignTokens.paddingMD,
          vertical: DesignTokens.paddingSM + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusPill,
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
        ),
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),

      // Chip theme avec accent color
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colors.primary.withValues(alpha: 0.12),
        side: BorderSide.none,
        labelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.paddingMD,
          vertical: DesignTokens.paddingSM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusPill,
        ),
      ),

      // Button themes avec palette colors
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.paddingLG,
            vertical: DesignTokens.paddingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusMedium,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.paddingMD,
            vertical: DesignTokens.paddingSM,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.paddingLG,
            vertical: DesignTokens.paddingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusMedium,
          ),
        ),
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: Colors.white.withValues(alpha: DesignTokens.opacityHigh),
        size: DesignTokens.iconSizeNormal,
      ),

      // Text theme
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),

      // Extensions (custom properties via extensions)
      extensions: <ThemeExtension<dynamic>>[
        PaletteColorsExtension(
          primary: colors.primary,
          navigation: colors.navigation,
          info: colors.info,
          success: colors.success,
          warning: colors.warning,
          error: colors.error,
          folder: colors.folder,
          file: colors.file,
          application: colors.application,
        ),
      ],
    );
  }
}

/// Extension personnalisée pour accéder aux couleurs de la palette
/// Utilisable via `Theme.of(context).extension<PaletteColorsExtension>()`
class PaletteColorsExtension extends ThemeExtension<PaletteColorsExtension> {
  const PaletteColorsExtension({
    required this.primary,
    required this.navigation,
    required this.info,
    required this.success,
    required this.warning,
    required this.error,
    required this.folder,
    required this.file,
    required this.application,
  });

  final Color primary;
  final Color navigation;
  final Color info;
  final Color success;
  final Color warning;
  final Color error;
  final Color folder;
  final Color file;
  final Color application;

  @override
  PaletteColorsExtension copyWith({
    Color? primary,
    Color? navigation,
    Color? info,
    Color? success,
    Color? warning,
    Color? error,
    Color? folder,
    Color? file,
    Color? application,
  }) {
    return PaletteColorsExtension(
      primary: primary ?? this.primary,
      navigation: navigation ?? this.navigation,
      info: info ?? this.info,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      folder: folder ?? this.folder,
      file: file ?? this.file,
      application: application ?? this.application,
    );
  }

  @override
  PaletteColorsExtension lerp(
    ThemeExtension<PaletteColorsExtension>? other,
    double t,
  ) {
    if (other is! PaletteColorsExtension) {
      return this;
    }
    return PaletteColorsExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      navigation: Color.lerp(navigation, other.navigation, t)!,
      info: Color.lerp(info, other.info, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      folder: Color.lerp(folder, other.folder, t)!,
      file: Color.lerp(file, other.file, t)!,
      application: Color.lerp(application, other.application, t)!,
    );
  }
}
