import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/theme/design_tokens.dart';

/// GlassPanel V2 - Version améliorée avec BackdropFilter pour vrai glassmorphism
///
/// Caractéristiques:
/// - Backdrop blur réel (ImageFilter.blur)
/// - Variations d'opacité selon le niveau (primary/secondary/tertiary)
/// - Gradients subtils pour depth
/// - Border et shadows adaptés à la palette
/// - Performance optimisée (RepaintBoundary)
class GlassPanelV2 extends StatelessWidget {
  const GlassPanelV2({
    super.key,
    required this.child,
    this.level = GlassPanelLevel.secondary,
    this.padding,
    this.borderRadius,
    this.accentColor,
    this.showBorder = true,
    this.showGradient = true,
    this.height,
    this.width,
    this.overrideColor,
  });

  final Widget child;
  final GlassPanelLevel level;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? accentColor;
  final bool showBorder;
  final bool showGradient;
  final double? height;
  final double? width;
  final Color? overrideColor;

  @override
  Widget build(BuildContext context) {
    // Si feature flag désactivé, fallback vers GlassPanel simple
    if (!FeatureFlags.useNewGlassmorphism) {
      return _SimpleFallback(
        padding: padding,
        borderRadius: borderRadius,
        child: child,
      );
    }

    // Opacité et blur selon le niveau
    final opacity = level.opacity;
    final blurSigma = level.blurSigma;

    // Border radius par défaut selon contexte
    final effectiveRadius = borderRadius ?? _getDefaultRadius(level);

    // Padding par défaut selon niveau
    final effectivePadding = padding ?? _getDefaultPadding(level);

    final theme = Theme.of(context);
    final baseSurface = theme.colorScheme.surface;
    final isLight = theme.brightness == Brightness.light;

    Color panelColor() {
      if (overrideColor != null) return overrideColor!;
      if (!isLight) {
        return baseSurface.withValues(alpha: opacity);
      }
      // En mode clair, voile blanc uniforme pour tous les niveaux
      return Colors.white.withValues(alpha: 0.30);
    }

    Color? borderColor() {
      if (!showBorder) return null;
      if (isLight) {
        return Colors.black.withValues(alpha: 0.06);
      }
      return Colors.white.withValues(alpha: level.borderOpacity);
    }

    return RepaintBoundary(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: effectiveRadius,
          border: borderColor() != null
              ? Border.all(color: borderColor()!, width: 1)
              : null,
        ),
        child: ClipRRect(
          borderRadius: effectiveRadius,
          clipBehavior: Clip.hardEdge,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
              tileMode: TileMode.clamp,
            ),
            child: Container(
              decoration: BoxDecoration(
                // Background ultra-simple
                color: panelColor(),

                // PAS de gradient - trop chargé
                // PAS de border - trop lourd visuellement
                // PAS de shadow - on a déjà le blur

                borderRadius: effectiveRadius,
              ),
              padding: effectivePadding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// Border radius par défaut selon le niveau
  BorderRadius _getDefaultRadius(GlassPanelLevel level) {
    switch (level) {
      case GlassPanelLevel.primary:
        return DesignTokens.borderRadiusSmall; // 8px
      case GlassPanelLevel.secondary:
        return DesignTokens.borderRadiusSmall; // 8px
      case GlassPanelLevel.tertiary:
        return DesignTokens.borderRadiusSmall; // 8px
      case GlassPanelLevel.overlay:
        return DesignTokens.borderRadiusMedium; // 12px
    }
  }

  /// Padding par défaut selon le niveau
  EdgeInsetsGeometry _getDefaultPadding(GlassPanelLevel level) {
    switch (level) {
      case GlassPanelLevel.primary:
        return const EdgeInsets.all(16);
      case GlassPanelLevel.secondary:
        return const EdgeInsets.all(12);
      case GlassPanelLevel.tertiary:
        return const EdgeInsets.all(12);
      case GlassPanelLevel.overlay:
        return const EdgeInsets.all(20);
    }
  }
}

/// Niveaux de GlassPanel avec propriétés visuelles différentes
enum GlassPanelLevel {
  /// Content area principal - Très transparent pour voir le fond
  primary(
    opacity: 0.70,
    blurSigma: 25,
    borderOpacity: 0.08,
  ),

  /// Toolbar, breadcrumb - Légèrement opaque
  secondary(
    opacity: 0.80,
    blurSigma: 20,
    borderOpacity: 0.06,
  ),

  /// Sidebar - Plus de contraste
  tertiary(
    opacity: 0.88,
    blurSigma: 15,
    borderOpacity: 0.04,
  ),

  /// Modals, overlays - Très opaque
  overlay(
    opacity: 0.95,
    blurSigma: 30,
    borderOpacity: 0.10,
  );

  const GlassPanelLevel({
    required this.opacity,
    required this.blurSigma,
    required this.borderOpacity,
  });

  final double opacity;
  final double blurSigma;
  final double borderOpacity;
}

/// Fallback simple si feature flag désactivé
class _SimpleFallback extends StatelessWidget {
  const _SimpleFallback({
    required this.child,
    this.padding,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.85),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: child,
    );
  }
}
