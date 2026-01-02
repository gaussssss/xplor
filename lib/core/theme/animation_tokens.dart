import 'package:flutter/animation.dart';

// ============================================================================
// CLASSES DE CONFIGURATION (déclarées en premier pour être utilisées dans AnimationTokens)
// ============================================================================

/// Configuration pour animations de hover
class HoverAnimationConfig {
  const HoverAnimationConfig({
    required this.duration,
    required this.curve,
  });

  final Duration duration;
  final Curve curve;
}

/// Configuration pour animations de button press
class ButtonPressConfig {
  const ButtonPressConfig({
    required this.duration,
    required this.curve,
  });

  final Duration duration;
  final Curve curve;
}

/// Configuration pour animations de modal
class ModalAnimationConfig {
  const ModalAnimationConfig({
    required this.duration,
    required this.curve,
  });

  final Duration duration;
  final Curve curve;
}

/// Configuration pour animations de slide
class SlideAnimationConfig {
  const SlideAnimationConfig({
    required this.duration,
    required this.curve,
  });

  final Duration duration;
  final Curve curve;
}

/// Configuration pour animations de fade
class FadeAnimationConfig {
  const FadeAnimationConfig({
    required this.duration,
    required this.curve,
  });

  final Duration duration;
  final Curve curve;
}

/// Configuration pour animations de scale
class ScaleAnimationConfig {
  const ScaleAnimationConfig({
    required this.duration,
    required this.curve,
  });

  final Duration duration;
  final Curve curve;
}

/// Configuration pour animations de rotation
class RotationAnimationConfig {
  const RotationAnimationConfig({
    required this.duration,
    required this.curve,
  });

  final Duration duration;
  final Curve curve;
}

/// Configuration pour animations shimmer
class ShimmerAnimationConfig {
  const ShimmerAnimationConfig({
    required this.duration,
    required this.curve,
  });

  final Duration duration;
  final Curve curve;
}

// ============================================================================
// TOKENS D'ANIMATION
// ============================================================================

/// Tokens d'animation centralisés pour assurer des transitions cohérentes
/// dans toute l'application
class AnimationTokens {
  AnimationTokens._();

  // ============================================================================
  // DURÉES D'ANIMATION
  // ============================================================================

  /// Animation instantanée (très rapide) - Pour micro-interactions subtiles
  /// Exemples: ripple effects, petites scales
  static const Duration instant = Duration(milliseconds: 100);

  /// Animation rapide - Pour interactions directes
  /// Exemples: hover effects, button presses, checkbox toggles
  static const Duration fast = Duration(milliseconds: 200);

  /// Animation normale (standard) - Pour la plupart des transitions
  /// Exemples: panel slides, view mode changes, modal open/close
  static const Duration normal = Duration(milliseconds: 300);

  /// Animation lente - Pour transitions complexes
  /// Exemples: page transitions, command palette, preview panel
  static const Duration slow = Duration(milliseconds: 500);

  /// Animation très lente - Pour effets spéciaux et loading states
  /// Exemples: progress bars, skeleton loaders
  static const Duration verySlow = Duration(milliseconds: 700);

  // ============================================================================
  // COURBES D'ANIMATION (CURVES)
  // ============================================================================

  /// Courbe standard ease-out pour la plupart des animations
  /// Démarre rapidement puis décélère
  static const Curve easeOut = Curves.easeOut;

  /// Courbe ease-in pour les animations de sortie/disparition
  /// Démarre lentement puis accélère
  static const Curve easeIn = Curves.easeIn;

  /// Courbe ease-in-out pour les animations symétriques
  /// Accélération puis décélération douce
  static const Curve easeInOut = Curves.easeInOut;

  /// Courbe cubic personnalisée pour les animations fluides et naturelles
  /// Excellente pour les transitions UI
  static const Curve easeOutCubic = Cubic(0.33, 1, 0.68, 1);

  /// Courbe avec un léger bounce à la fin
  /// Parfait pour les micro-interactions ludiques
  static const Curve easeInOutBack = Cubic(0.68, -0.55, 0.265, 1.55);

  /// Courbe spring pour les animations élastiques
  /// Idéal pour les scales et bounces
  static const Curve spring = Curves.easeOutBack;

  /// Courbe fast-out-slow-in (Material Design standard)
  /// Excellente pour les transitions de navigation
  static const Curve materialStandard = Curves.fastOutSlowIn;

  /// Courbe linear pour les animations constantes
  /// Utile pour les rotations et progress indicators
  static const Curve linear = Curves.linear;

  // ============================================================================
  // ANIMATION PRESETS (COMBINAISONS DURÉE + COURBE)
  // ============================================================================

  /// Configuration pour hover effects
  static const HoverAnimationConfig hover = HoverAnimationConfig(
    duration: fast,
    curve: easeOutCubic,
  );

  /// Configuration pour button press
  static const ButtonPressConfig buttonPress = ButtonPressConfig(
    duration: instant,
    curve: easeOut,
  );

  /// Configuration pour modal/dialog
  static const ModalAnimationConfig modal = ModalAnimationConfig(
    duration: normal,
    curve: easeOutCubic,
  );

  /// Configuration pour slide in/out
  static const SlideAnimationConfig slide = SlideAnimationConfig(
    duration: normal,
    curve: easeOutCubic,
  );

  /// Configuration pour fade
  static const FadeAnimationConfig fade = FadeAnimationConfig(
    duration: fast,
    curve: linear,
  );

  /// Configuration pour scale animations
  static const ScaleAnimationConfig scale = ScaleAnimationConfig(
    duration: fast,
    curve: spring,
  );

  /// Configuration pour rotation
  static const RotationAnimationConfig rotation = RotationAnimationConfig(
    duration: normal,
    curve: easeOutCubic,
  );

  /// Configuration pour shimmer/skeleton loaders
  static const ShimmerAnimationConfig shimmer = ShimmerAnimationConfig(
    duration: verySlow,
    curve: linear,
  );

  // ============================================================================
  // VALEURS NUMÉRIQUES POUR ANIMATIONS
  // ============================================================================

  /// Scale par défaut au hover (de 1.0 vers ...)
  static const double hoverScale = 1.02;

  /// Scale au tap/press (de 1.0 vers ...)
  static const double pressScale = 0.98;

  /// Scale pour les bounces (de 1.0 vers ...)
  static const double bounceScale = 1.1;

  /// Opacité minimale pour les fades (de 1.0 vers ...)
  static const double fadeMinOpacity = 0.0;

  /// Opacité pour les éléments disabled
  static const double disabledOpacity = 0.5;

  /// Offset pour les slides (en pixels)
  static const double slideOffset = 20.0;

  /// Rotation en degrés pour les animations de rotation
  static const double rotationDegrees = 360.0;
}
