/// Tokens d'espacement pour les modes normal et compact
/// Permet de basculer facilement entre une vue dense et une vue spacieuse
class SpacingTokens {
  SpacingTokens._();

  // ============================================================================
  // MODE NORMAL (Vue standard avec espacement confortable)
  // ============================================================================

  /// Padding petit en mode normal
  static const double normalPaddingSmall = 8.0;

  /// Padding moyen en mode normal (le plus utilisé)
  static const double normalPaddingMedium = 12.0;

  /// Padding large en mode normal
  static const double normalPaddingLarge = 16.0;

  /// Padding extra large en mode normal (pour les sections)
  static const double normalPaddingXL = 24.0;

  /// Taille d'icône en mode normal
  static const double normalIconSize = 20.0;

  /// Taille d'icône moyenne en mode normal
  static const double normalIconSizeMedium = 24.0;

  /// Taille d'icône large en mode normal
  static const double normalIconSizeLarge = 32.0;

  /// Hauteur des tiles de fichiers en mode liste normal
  static const double normalTileHeight = 56.0;

  /// Hauteur des boutons en mode normal
  static const double normalButtonHeight = 48.0;

  /// Taille de police standard en mode normal
  static const double normalFontSize = 14.0;

  /// Taille de police titre en mode normal
  static const double normalTitleFontSize = 16.0;

  /// Taille de police small en mode normal
  static const double normalSmallFontSize = 12.0;

  /// Espacement entre éléments en mode normal
  static const double normalSpacing = 12.0;

  /// Espacement entre sections en mode normal
  static const double normalSectionSpacing = 16.0;

  // ============================================================================
  // MODE COMPACT (Vue dense pour afficher plus d'éléments)
  // ============================================================================

  /// Padding petit en mode compact (0.5x du normal)
  static const double compactPaddingSmall = 4.0;

  /// Padding moyen en mode compact (0.5x du normal)
  static const double compactPaddingMedium = 6.0;

  /// Padding large en mode compact (0.5x du normal)
  static const double compactPaddingLarge = 8.0;

  /// Padding extra large en mode compact
  static const double compactPaddingXL = 12.0;

  /// Taille d'icône en mode compact (0.8x du normal)
  static const double compactIconSize = 16.0;

  /// Taille d'icône moyenne en mode compact (0.8x du normal)
  static const double compactIconSizeMedium = 19.0;

  /// Taille d'icône large en mode compact (0.8x du normal)
  static const double compactIconSizeLarge = 26.0;

  /// Hauteur des tiles de fichiers en mode liste compact (0.71x du normal)
  static const double compactTileHeight = 40.0;

  /// Hauteur des boutons en mode compact
  static const double compactButtonHeight = 36.0;

  /// Taille de police standard en mode compact (0.9x du normal)
  static const double compactFontSize = 12.6;

  /// Taille de police titre en mode compact (0.9x du normal)
  static const double compactTitleFontSize = 14.4;

  /// Taille de police small en mode compact (0.9x du normal)
  static const double compactSmallFontSize = 10.8;

  /// Espacement entre éléments en mode compact
  static const double compactSpacing = 6.0;

  /// Espacement entre sections en mode compact
  static const double compactSectionSpacing = 8.0;

  // ============================================================================
  // GETTERS DYNAMIQUES (selon le mode actif)
  // ============================================================================

  /// Retourne le padding small selon le mode
  static double paddingSmall(bool isCompact) =>
      isCompact ? compactPaddingSmall : normalPaddingSmall;

  /// Retourne le padding medium selon le mode
  static double paddingMedium(bool isCompact) =>
      isCompact ? compactPaddingMedium : normalPaddingMedium;

  /// Retourne le padding large selon le mode
  static double paddingLarge(bool isCompact) =>
      isCompact ? compactPaddingLarge : normalPaddingLarge;

  /// Retourne le padding XL selon le mode
  static double paddingXL(bool isCompact) =>
      isCompact ? compactPaddingXL : normalPaddingXL;

  /// Retourne la taille d'icône selon le mode
  static double iconSize(bool isCompact) =>
      isCompact ? compactIconSize : normalIconSize;

  /// Retourne la taille d'icône moyenne selon le mode
  static double iconSizeMedium(bool isCompact) =>
      isCompact ? compactIconSizeMedium : normalIconSizeMedium;

  /// Retourne la taille d'icône large selon le mode
  static double iconSizeLarge(bool isCompact) =>
      isCompact ? compactIconSizeLarge : normalIconSizeLarge;

  /// Retourne la hauteur des tiles selon le mode
  static double tileHeight(bool isCompact) =>
      isCompact ? compactTileHeight : normalTileHeight;

  /// Retourne la hauteur des boutons selon le mode
  static double buttonHeight(bool isCompact) =>
      isCompact ? compactButtonHeight : normalButtonHeight;

  /// Retourne la taille de police selon le mode
  static double fontSize(bool isCompact) =>
      isCompact ? compactFontSize : normalFontSize;

  /// Retourne la taille de police titre selon le mode
  static double titleFontSize(bool isCompact) =>
      isCompact ? compactTitleFontSize : normalTitleFontSize;

  /// Retourne la taille de police small selon le mode
  static double smallFontSize(bool isCompact) =>
      isCompact ? compactSmallFontSize : normalSmallFontSize;

  /// Retourne l'espacement entre éléments selon le mode
  static double spacing(bool isCompact) =>
      isCompact ? compactSpacing : normalSpacing;

  /// Retourne l'espacement entre sections selon le mode
  static double sectionSpacing(bool isCompact) =>
      isCompact ? compactSectionSpacing : normalSectionSpacing;

  // ============================================================================
  // RATIOS (pour référence et calculs personnalisés)
  // ============================================================================

  /// Ratio de spacing en mode compact par rapport au normal (0.5)
  static const double spacingRatio = 0.5;

  /// Ratio d'icônes en mode compact par rapport au normal (0.8)
  static const double iconRatio = 0.8;

  /// Ratio de fonts en mode compact par rapport au normal (0.9)
  static const double fontRatio = 0.9;

  /// Ratio de tile height en mode compact par rapport au normal (0.71)
  static const double tileHeightRatio = 0.714;
}
