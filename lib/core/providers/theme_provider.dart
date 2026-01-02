import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/feature_flags.dart';
import '../theme/color_palettes.dart';

/// Provider pour gérer le thème de l'application (palette de couleurs)
/// Utilise ChangeNotifier pour notifier les widgets des changements
/// Persiste la palette sélectionnée avec SharedPreferences
class ThemeProvider extends ChangeNotifier {
  /// Clé pour sauvegarder la palette dans SharedPreferences
  static const String _paletteKey = 'selected_color_palette';

  /// Palette actuellement active
  ColorPalette _currentPalette = ColorPalette.neonCyberpunk;

  /// Indique si le provider est en cours de chargement
  bool _isLoading = true;

  /// Constructeur qui charge automatiquement la palette sauvegardée
  ThemeProvider() {
    _loadSavedPalette();
  }

  // ==========================================================================
  // GETTERS
  // ==========================================================================

  /// Retourne la palette actuellement active
  ColorPalette get currentPalette => _currentPalette;

  /// Retourne les données de couleurs de la palette active
  ColorPaletteData get colors => ColorPalettes.getData(_currentPalette);

  /// Retourne l'intensité du glow selon la palette active
  double get glowIntensity => ColorPalettes.getGlowIntensity(_currentPalette);

  /// Retourne le blur radius des ombres selon la palette active
  double get shadowBlurRadius =>
      ColorPalettes.getShadowBlurRadius(_currentPalette);

  /// Retourne le spread radius des ombres selon la palette active
  double get shadowSpreadRadius =>
      ColorPalettes.getShadowSpreadRadius(_currentPalette);

  /// Retourne true si le provider est en cours de chargement
  bool get isLoading => _isLoading;

  /// Retourne true si la palette est Neon Cyberpunk (effets plus prononcés)
  bool get isNeonPalette => _currentPalette == ColorPalette.neonCyberpunk;

  /// Retourne true si les palettes sont activées via feature flag
  bool get isEnabled => FeatureFlags.useColorPalettes;

  // ==========================================================================
  // MÉTHODES PUBLIQUES
  // ==========================================================================

  /// Change la palette de couleurs et persiste le choix
  Future<void> setPalette(ColorPalette palette) async {
    if (_currentPalette == palette) return;

    if (FeatureFlags.debugThemeChanges) {
      debugPrint('🎨 ThemeProvider: Changing palette from '
          '${_currentPalette.displayName} to ${palette.displayName}');
    }

    _currentPalette = palette;
    notifyListeners();

    await _savePalette(palette);

    if (FeatureFlags.debugThemeChanges) {
      debugPrint('✅ ThemeProvider: Palette changed and saved successfully');
    }
  }

  /// Passe à la palette suivante (rotation cyclique)
  Future<void> nextPalette() async {
    final palettes = ColorPalette.values;
    final currentIndex = palettes.indexOf(_currentPalette);
    final nextIndex = (currentIndex + 1) % palettes.length;
    await setPalette(palettes[nextIndex]);
  }

  /// Passe à la palette précédente (rotation cyclique)
  Future<void> previousPalette() async {
    final palettes = ColorPalette.values;
    final currentIndex = palettes.indexOf(_currentPalette);
    final previousIndex = (currentIndex - 1 + palettes.length) % palettes.length;
    await setPalette(palettes[previousIndex]);
  }

  /// Réinitialise à la palette par défaut (Neon Cyberpunk)
  Future<void> resetToDefault() async {
    await setPalette(ColorPalette.neonCyberpunk);
  }

  // ==========================================================================
  // MÉTHODES PRIVÉES
  // ==========================================================================

  /// Charge la palette sauvegardée depuis SharedPreferences
  Future<void> _loadSavedPalette() async {
    try {
      _isLoading = true;

      if (FeatureFlags.debugThemeChanges) {
        debugPrint('🔄 ThemeProvider: Loading saved palette...');
      }

      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt(_paletteKey);

      if (savedIndex != null && savedIndex < ColorPalette.values.length) {
        _currentPalette = ColorPalette.values[savedIndex];
        if (FeatureFlags.debugThemeChanges) {
          debugPrint(
              '✅ ThemeProvider: Loaded palette ${_currentPalette.displayName}');
        }
      } else {
        if (FeatureFlags.debugThemeChanges) {
          debugPrint(
              'ℹ️  ThemeProvider: No saved palette, using default (Neon Cyberpunk)');
        }
      }
    } catch (e) {
      debugPrint('❌ ThemeProvider: Error loading palette: $e');
      // En cas d'erreur, garder la palette par défaut
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sauvegarde la palette dans SharedPreferences
  Future<void> _savePalette(ColorPalette palette) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_paletteKey, palette.index);

      if (FeatureFlags.debugThemeChanges) {
        debugPrint('💾 ThemeProvider: Palette saved to SharedPreferences');
      }
    } catch (e) {
      debugPrint('❌ ThemeProvider: Error saving palette: $e');
    }
  }
}
