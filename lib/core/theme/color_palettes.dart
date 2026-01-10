import 'package:flutter/material.dart';

/// Les 4 palettes de couleurs disponibles dans l'application
enum ColorPalette {
  /// Palette moderne et professionnelle (bleu/purple équilibré)
  modernTech,

  /// Palette néon futuriste et énergique (défaut) ⚡
  neonCyberpunk,

  /// Palette chaleureuse et créative (coral/peach)
  warmSunset,

  /// Palette sophistiquée et premium (ocean blue/indigo) 🌊
  deepOcean,

  /// Palette nature brumeuse (verts doux, brume, pierre)
  forestMist,

  /// Palette sable / soleil (beige doré, ambre, terracotta)
  desertDawn,
}

/// Extension pour obtenir les métadonnées d'une palette
extension ColorPaletteExtension on ColorPalette {
  String get displayName {
    switch (this) {
      case ColorPalette.modernTech:
        return 'Modern Tech';
      case ColorPalette.neonCyberpunk:
        return 'Neon Cyberpunk';
      case ColorPalette.warmSunset:
        return 'Warm Sunset';
      case ColorPalette.deepOcean:
        return 'Deep Ocean';
      case ColorPalette.forestMist:
        return 'Forest Mist';
      case ColorPalette.desertDawn:
        return 'Desert Dawn';
    }
  }

  String get description {
    switch (this) {
      case ColorPalette.modernTech:
        return 'Professionnel, moderne, propre';
      case ColorPalette.neonCyberpunk:
        return 'Futuriste, énergique, électrique';
      case ColorPalette.warmSunset:
        return 'Chaleureux, accueillant, créatif';
      case ColorPalette.deepOcean:
        return 'Sophistiqué, élégant, premium';
      case ColorPalette.forestMist:
        return 'Nature, apaisant, organique';
      case ColorPalette.desertDawn:
        return 'Sable chaud, lumière dorée, minimal';
    }
  }

  String get emoji {
    switch (this) {
      case ColorPalette.modernTech:
        return '💼';
      case ColorPalette.neonCyberpunk:
        return '⚡';
      case ColorPalette.warmSunset:
        return '🌅';
      case ColorPalette.deepOcean:
        return '🌊';
      case ColorPalette.forestMist:
        return '🌿';
      case ColorPalette.desertDawn:
        return '🏜️';
    }
  }
}

/// Données d'une palette de couleurs avec sémantique claire
class ColorPaletteData {
  const ColorPaletteData({
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

  /// Couleur principale pour actions primaires et boutons
  final Color primary;

  /// Couleur pour navigation, sidebar et éléments de navigation
  final Color navigation;

  /// Couleur pour informations, status et tooltips
  final Color info;

  /// Couleur pour opérations réussies (copie, création)
  final Color success;

  /// Couleur pour avertissements (permissions, espace disque)
  final Color warning;

  /// Couleur pour erreurs et suppressions
  final Color error;

  /// Couleur spécifique pour les dossiers
  final Color folder;

  /// Couleur spécifique pour les fichiers génériques
  final Color file;

  /// Couleur spécifique pour les applications
  final Color application;
}

/// Classe statique contenant toutes les palettes de couleurs
class ColorPalettes {
  ColorPalettes._();

  /// Palette Modern Tech - Professionnel et équilibré
  static const modernTech = ColorPaletteData(
    primary: Color(0xFF60A5FA), // Blue moderne
    navigation: Color(0xFFA78BFA), // Purple doux
    info: Color(0xFF22D3EE), // Cyan vif
    success: Color(0xFF34D399), // Green positif
    warning: Color(0xFFFB923C), // Orange chaud
    error: Color(0xFFF87171), // Red doux
    folder: Color(0xFFFBBF24), // Yellow ambre
    file: Color(0xFF60A5FA), // Blue (même que primary)
    application: Color(0xFF34D399), // Green (même que success)
  );

  /// Palette Neon Cyberpunk - Futuriste et énergique ⚡ (DÉFAUT)
  static const neonCyberpunk = ColorPaletteData(
    primary: Color(0xFF00D4FF), // Blue néon électrique
    navigation: Color(0xFFB24BF3), // Purple néon vibrant
    info: Color(0xFF00FFC8), // Teal néon lumineux
    success: Color(0xFF39FF14), // Green néon intense
    warning: Color(0xFFFF6B35), // Orange néon explosif
    error: Color(0xFFFF007F), // Pink néon flashy
    folder: Color(0xFFFBBF24), // Yellow ambre (conservé pour lisibilité)
    file: Color(0xFF00D4FF), // Blue néon
    application: Color(0xFF39FF14), // Green néon
  );

  /// Palette Warm Sunset - Chaleureux et créatif 🌅
  static const warmSunset = ColorPaletteData(
    primary: Color(0xFFFF6B6B), // Coral chaleureux
    navigation: Color(0xFFFFB366), // Peach doux
    info: Color(0xFFC69EEB), // Lavender subtil
    success: Color(0xFF6BCF7F), // Mint frais
    warning: Color(0xFFFFD93D), // Gold lumineux
    error: Color(0xFFE63946), // Crimson profond
    folder: Color(0xFFFFD93D), // Gold (même que warning)
    file: Color(0xFFFF6B6B), // Coral
    application: Color(0xFF6BCF7F), // Mint
  );

  /// Palette Deep Ocean - Sophistiqué et premium 🌊
  static const deepOcean = ColorPaletteData(
    primary: Color(0xFF0EA5E9), // Ocean blue profond
    navigation: Color(0xFF6366F1), // Indigo riche
    info: Color(0xFF14B8A6), // Turquoise aqua
    success: Color(0xFF10B981), // Emerald précieux
    warning: Color(0xFFF59E0B), // Amber chaud
    error: Color(0xFFF43F5E), // Rose intense
    folder: Color(0xFFF59E0B), // Amber (même que warning)
    file: Color(0xFF0EA5E9), // Ocean blue
    application: Color(0xFF10B981), // Emerald
  );

  /// Palette Forest Mist - Nature douce et brume
  static const forestMist = ColorPaletteData(
    primary: Color(0xFF5BAA8F), // Sauge profonde
    navigation: Color(0xFF3F6F63), // Sapin doux
    info: Color(0xFF8AC6B4), // Menthe brumeuse
    success: Color(0xFF58B368), // Vert mousse
    warning: Color(0xFFC7A85A), // Ocre doux
    error: Color(0xFFD06D6D), // Terre cuite rosée
    folder: Color(0xFFC9E3D5), // Vert pastel
    file: Color(0xFF5BAA8F), // Aligné sur primary
    application: Color(0xFF3F6F63), // Navigation pour les apps
  );

  /// Palette Desert Dawn - Sable chaud et ambre
  static const desertDawn = ColorPaletteData(
    primary: Color(0xFFE0A060), // Ambre doux
    navigation: Color(0xFFB86B4B), // Terracotta
    info: Color(0xFFF1C27D), // Sable clair
    success: Color(0xFF8FBF7F), // Olive pâle
    warning: Color(0xFFF6B352), // Gold chaud
    error: Color(0xFFD96B6B), // Corail terre
    folder: Color(0xFFF1D7B0), // Beige sable
    file: Color(0xFFE0A060), // Ambre
    application: Color(0xFF8FBF7F), // Olive
  );

  /// Récupère les données d'une palette spécifique
  static ColorPaletteData getData(ColorPalette palette) {
    switch (palette) {
      case ColorPalette.modernTech:
        return modernTech;
      case ColorPalette.neonCyberpunk:
        return neonCyberpunk;
      case ColorPalette.warmSunset:
        return warmSunset;
      case ColorPalette.deepOcean:
        return deepOcean;
      case ColorPalette.forestMist:
        return forestMist;
      case ColorPalette.desertDawn:
        return desertDawn;
    }
  }

  /// Retourne le paramètre de glow (intensité) selon la palette
  /// Néon Cyberpunk a besoin de glows plus prononcés
  static double getGlowIntensity(ColorPalette palette) {
    switch (palette) {
      case ColorPalette.neonCyberpunk:
        return 0.6; // Glow intense pour effet néon
      case ColorPalette.modernTech:
      case ColorPalette.warmSunset:
      case ColorPalette.deepOcean:
      case ColorPalette.forestMist:
      case ColorPalette.desertDawn:
        return 0.3; // Glow subtil
    }
  }

  /// Retourne le blur radius pour les ombres selon la palette
  static double getShadowBlurRadius(ColorPalette palette) {
    switch (palette) {
      case ColorPalette.neonCyberpunk:
        return 20.0; // Ombres plus diffuses pour effet néon
      case ColorPalette.modernTech:
      case ColorPalette.warmSunset:
      case ColorPalette.deepOcean:
      case ColorPalette.forestMist:
      case ColorPalette.desertDawn:
        return 14.0; // Légèrement plus doux pour effet glass
    }
  }

  /// Retourne le spread radius pour les ombres selon la palette
  static double getShadowSpreadRadius(ColorPalette palette) {
    switch (palette) {
      case ColorPalette.neonCyberpunk:
        return 2.0; // Spread plus large pour effet de halo néon
      case ColorPalette.modernTech:
      case ColorPalette.warmSunset:
      case ColorPalette.deepOcean:
      case ColorPalette.forestMist:
      case ColorPalette.desertDawn:
        return 0.7; // Légèrement plus large pour glass
    }
  }

  /// Retourne une couleur adaptée pour le mode clair ou sombre
  /// En mode clair, les couleurs sont assombries et saturées pour meilleure visibilité
  /// En mode sombre, les couleurs restent vives
  static Color getAdaptiveColor(Color color, bool isLight) {
    if (!isLight) {
      return color; // Mode sombre: couleurs vives originales
    }

    // Mode clair: assombrir et saturer la couleur
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness * 0.45).clamp(0.0, 1.0)) // Assombrir (55% plus sombre)
        .withSaturation((hsl.saturation * 1.2).clamp(0.0, 1.0)) // Saturer (20% plus saturé)
        .toColor();
  }

  /// Récupère les couleurs adaptées au mode actuel (clair/sombre)
  static ColorPaletteData getAdaptiveData(ColorPalette palette, bool isLight) {
    final data = getData(palette);

    if (!isLight) {
      return data; // Mode sombre: couleurs originales
    }

    // Mode clair: adapter toutes les couleurs
    return ColorPaletteData(
      primary: getAdaptiveColor(data.primary, isLight),
      navigation: getAdaptiveColor(data.navigation, isLight),
      info: getAdaptiveColor(data.info, isLight),
      success: getAdaptiveColor(data.success, isLight),
      warning: getAdaptiveColor(data.warning, isLight),
      error: getAdaptiveColor(data.error, isLight),
      folder: getAdaptiveColor(data.folder, isLight),
      file: getAdaptiveColor(data.file, isLight),
      application: getAdaptiveColor(data.application, isLight),
    );
  }
}
