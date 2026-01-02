import 'package:flutter/material.dart';

/// Tokens de design centralisés pour l'application
/// Ces tokens définissent les valeurs réutilisables pour assurer la cohérence visuelle
class DesignTokens {
  DesignTokens._();

  // ============================================================================
  // COULEURS DE BASE (indépendantes des palettes)
  // ============================================================================

  /// Couleur de fond principale de l'application
  static const background = Color(0xFF0A0A0A);

  /// Couleur de surface pour les panneaux et cartes
  static const surface = Color(0xFF111111);

  /// Couleur primaire (blanc) pour le texte et les icônes
  static const primary = Color(0xFFFFFFFF);

  /// Couleur secondaire (gris) pour les éléments moins importants
  static const secondary = Color(0xFF9E9E9E);

  // ============================================================================
  // INTENSITÉS GLASSMORPHISM
  // ============================================================================

  /// Opacité élevée pour les panneaux principaux (toolbar, content area, modals)
  static const double glassIntensityHigh = 0.95;

  /// Opacité moyenne pour les panneaux secondaires (sidebar, action bar, breadcrumb)
  static const double glassIntensityMedium = 0.85;

  /// Opacité basse pour les panneaux tertiaires (footer, tooltips, hover overlays)
  static const double glassIntensityLow = 0.75;

  // ============================================================================
  // BORDURES & OMBRES
  // ============================================================================

  /// Opacité des bordures pour les glass panels
  static const double borderOpacity = 0.12;

  /// Opacité des ombres
  static const double shadowOpacity = 0.25;

  /// Couleur de bordure par défaut pour les glass panels
  static Color get borderColor => Colors.white.withValues(alpha: borderOpacity);

  // ============================================================================
  // BORDER RADIUS (Redesign - Plus subtils et raffinés)
  // ============================================================================

  /// Border radius minimal pour éléments très subtils
  static final borderRadiusXS = BorderRadius.circular(4);

  /// Border radius petit pour boutons et tiles (6px - Windows 11 style)
  static final borderRadiusSmall = BorderRadius.circular(6);

  /// Border radius moyen pour panels (8px - moderne et raffiné)
  static final borderRadiusMedium = BorderRadius.circular(8);

  /// Border radius large pour modals (12px)
  static final borderRadiusLarge = BorderRadius.circular(12);

  /// Border radius pill pour inputs et pills (18px - vraiment pill-shaped)
  static final borderRadiusPill = BorderRadius.circular(18);

  // ============================================================================
  // OPACITÉS
  // ============================================================================

  /// Opacité élevée pour les éléments actifs
  static const double opacityHigh = 0.9;

  /// Opacité moyenne pour les éléments normaux
  static const double opacityMedium = 0.7;

  /// Opacité basse pour les éléments désactivés ou en arrière-plan
  static const double opacityLow = 0.4;

  /// Opacité très basse pour les overlays subtils
  static const double opacityVeryLow = 0.08;

  // ============================================================================
  // OMBRES (BOX SHADOWS)
  // ============================================================================

  /// Ombre légère pour les éléments survol
  static List<BoxShadow> get elevationLow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.16),
          blurRadius: 14,
          offset: const Offset(0, 10),
        ),
      ];

  /// Ombre moyenne pour les cards et panneaux
  static List<BoxShadow> get elevationMedium => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.22),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  /// Ombre élevée pour les modals et overlays
  static List<BoxShadow> get elevationHigh => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  // ============================================================================
  // BLUR
  // ============================================================================

  /// Blur léger pour les glassmorphism subtils
  static const double blurRadiusLight = 5.0;

  /// Blur moyen pour les glass panels standards
  static const double blurRadiusMedium = 10.0;

  /// Blur fort pour les overlays et modals
  static const double blurRadiusStrong = 15.0;

  // ============================================================================
  // GRADIENTS
  // ============================================================================

  /// Crée un gradient radial subtil pour les fonds de glass panel
  static RadialGradient createGlassGradient({
    required Color accentColor,
    double opacity = 0.24,
  }) {
    return RadialGradient(
      colors: [
        accentColor.withValues(alpha: opacity),
        Colors.transparent,
      ],
    );
  }

  /// Crée un gradient linéaire pour les éléments interactifs
  static LinearGradient createInteractiveGradient({
    required Color accentColor,
    double startOpacity = 0.24,
    double endOpacity = 0.08,
  }) {
    return LinearGradient(
      colors: [
        accentColor.withValues(alpha: startOpacity),
        accentColor.withValues(alpha: endOpacity),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Gradient pour les glass panels de base
  static const LinearGradient glassBaseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.fromRGBO(255, 255, 255, 0.05),
      Color.fromRGBO(255, 255, 255, 0.02),
    ],
  );

  // ============================================================================
  // CONSTANTES NUMÉRIQUES
  // ============================================================================

  /// Épaisseur standard des bordures
  static const double borderWidth = 1.0;

  /// Épaisseur des bordures actives/sélectionnées
  static const double borderWidthActive = 1.5;

  // ============================================================================
  // SPACING SYSTEM (Base 4px - Redesign compact)
  // ============================================================================

  /// Spacing minimal (2px - ultra compact)
  static const double spacingXXS = 2.0;

  /// Spacing très petit (4px - tight)
  static const double spacingXS = 4.0;

  /// Spacing petit (6px - compact buttons spacing)
  static const double spacingSM = 6.0;

  /// Spacing moyen (8px - default component spacing)
  static const double spacingMD = 8.0;

  /// Spacing large (12px - section spacing)
  static const double spacingLG = 12.0;

  /// Spacing extra large (16px - page margins)
  static const double spacingXL = 16.0;

  /// Spacing extra extra large (24px - large gaps)
  static const double spacingXXL = 24.0;

  /// Padding ultra minimal (4px)
  static const double paddingXS = 4.0;

  /// Padding petit (6px - compact)
  static const double paddingSM = 6.0;

  /// Padding moyen (8px - buttons)
  static const double paddingMD = 8.0;

  /// Padding large (12px - panels)
  static const double paddingLG = 12.0;

  /// Padding extra large (16px - content areas)
  static const double paddingXL = 16.0;

  // ============================================================================
  // TAILLES D'ICÔNES (Redesign - Plus compactes)
  // ============================================================================

  /// Taille d'icône très petite (14px - dense UI)
  static const double iconSizeXS = 14.0;

  /// Taille d'icône petite (16px - compact buttons)
  static const double iconSizeSmall = 16.0;

  /// Taille d'icône standard (18px - toolbar buttons)
  static const double iconSizeNormal = 18.0;

  /// Taille d'icône moyenne (20px - list items)
  static const double iconSizeMedium = 20.0;

  /// Taille d'icône grande (24px - headers)
  static const double iconSizeLarge = 24.0;

  /// Taille d'icône extra large (32px - grid items)
  static const double iconSizeXLarge = 32.0;

  // ============================================================================
  // HAUTEURS DE COMPOSANTS (Redesign - Compact et raffiné)
  // ============================================================================

  /// Hauteur de la toolbar principale (40px - Windows 11 style)
  static const double toolbarHeight = 40.0;

  /// Hauteur des boutons de toolbar (36px - compact)
  static const double toolbarButtonSize = 36.0;

  /// Hauteur des tiles de fichier en mode liste (32px - compact)
  static const double fileEntryTileHeight = 32.0;

  /// Hauteur minimale des inputs (32px)
  static const double inputHeight = 32.0;

  /// Hauteur de la breadcrumb bar (32px - compact)
  static const double breadcrumbHeight = 32.0;

  /// Hauteur des boutons standards (32px)
  static const double buttonHeightSmall = 32.0;

  /// Hauteur des boutons medium (36px)
  static const double buttonHeightMedium = 36.0;

  /// Hauteur des sidebar tiles (32px - compact)
  static const double sidebarTileHeight = 32.0;

  // ============================================================================
  // TRANSITIONS & INTERACTIONS
  // ============================================================================

  /// Scale au hover pour les boutons (1.0 -> 1.02)
  static const double hoverScale = 1.02;

  /// Scale au tap/press pour les boutons (1.0 -> 0.98)
  static const double pressScale = 0.98;

  // ============================================================================
  // Z-INDEX / LAYERS
  // ============================================================================

  /// Z-index pour les glass panels de base
  static const int layerBase = 0;

  /// Z-index pour les éléments interactifs (hover states)
  static const int layerInteractive = 10;

  /// Z-index pour les overlays (tooltips, menus)
  static const int layerOverlay = 100;

  /// Z-index pour les modals et dialogs
  static const int layerModal = 1000;

  /// Z-index pour les toasts et notifications
  static const int layerNotification = 10000;
}
