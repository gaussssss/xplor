import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/feature_flags.dart';
import '../theme/color_palettes.dart';
import '../theme/design_tokens.dart';

/// Provider pour gérer le thème de l'application (palette de couleurs)
/// Utilise ChangeNotifier pour notifier les widgets des changements
/// Persiste la palette sélectionnée avec SharedPreferences
class ThemeProvider extends ChangeNotifier {
  /// Clé pour sauvegarder la palette dans SharedPreferences
  static const String _paletteKey = 'selected_color_palette';
  static const String _backgroundColorKey = 'selected_background_color';
  static const String _backgroundImageKey = 'selected_background_image';
  static const String _lightModeKey = 'use_light_theme';
  static const String _mockBackgroundFolder = '/Volumes/Datas/Backgrounds';

  /// Palette actuellement active
  ColorPalette _currentPalette = ColorPalette.warmSunset;
  Color _backgroundColor = DesignTokens.background;
  String? _backgroundImagePath;
  bool _isLight = false;

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

  /// Couleur de fond courante
  Color get backgroundColor => _backgroundColor;

  /// Image de fond locale copiée dans l'app (si présente)
  String? get backgroundImagePath => _backgroundImagePath;

  /// Mode clair ou non
  bool get isLight => _isLight;

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
    _backgroundColor =
        _isLight ? _backgroundForLight(palette) : _backgroundFor(palette);
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
    await setBackgroundColor(
      _isLight
          ? _backgroundForLight(ColorPalette.neonCyberpunk)
          : _backgroundFor(ColorPalette.neonCyberpunk),
    );
    await clearBackgroundImage();
  }

  Future<void> setBackgroundColor(Color color) async {
    _backgroundColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_backgroundColorKey, color.value);
  }

  Future<void> setBackgroundImage(File file) async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      final bgDir = Directory('${supportDir.path}/backgrounds');
      if (!bgDir.existsSync()) {
        bgDir.createSync(recursive: true);
      }
      final name =
          file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'bg';
      final dest = File(
        '${bgDir.path}/bg_${DateTime.now().millisecondsSinceEpoch}_$name',
      );
      await file.copy(dest.path);
      _backgroundImagePath = dest.path;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backgroundImageKey, dest.path);
    } catch (e) {
      debugPrint('❌ ThemeProvider: error copying background image: $e');
    }
  }

  Future<void> clearBackgroundImage() async {
    _backgroundImagePath = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backgroundImageKey);
  }

  Future<void> setLightMode(bool value) async {
    _isLight = value;
    _backgroundColor =
        value ? _backgroundForLight(_currentPalette) : _backgroundFor(_currentPalette);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lightModeKey, value);
    await prefs.setInt(_backgroundColorKey, _backgroundColor.value);
  }

  Color _backgroundFor(ColorPalette palette) {
    switch (palette) {
      case ColorPalette.neonCyberpunk:
        return const Color(0xFF05060A);
      case ColorPalette.modernTech:
        return const Color(0xFF0B1220);
      case ColorPalette.glassIos26:
        return const Color(0xFF0C0E12); // Fond froid et neutre pour le verre
      case ColorPalette.warmSunset:
        return const Color(0xFF0F0A0A);
      case ColorPalette.deepOcean:
        return const Color(0xFF050910);
    }
  }

  Color _backgroundForLight(ColorPalette palette) {
    switch (palette) {
      case ColorPalette.neonCyberpunk:
        return const Color(0xFFF5FBFF);
      case ColorPalette.modernTech:
        return const Color(0xFFF1F4FA);
      case ColorPalette.glassIos26:
        return const Color(0xFFF6F9FF);
      case ColorPalette.warmSunset:
        return const Color(0xFFFFF8F4);
      case ColorPalette.deepOcean:
        return const Color(0xFFF1F6FB);
    }
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
        _backgroundColor =
            _isLight ? _backgroundForLight(_currentPalette) : _backgroundFor(_currentPalette);
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
      final savedBg = prefs.getInt(_backgroundColorKey);
      if (savedBg != null) {
        _backgroundColor = Color(savedBg);
      }
      final savedImage = prefs.getString(_backgroundImageKey);
      if (savedImage != null && savedImage.isNotEmpty) {
        _backgroundImagePath = savedImage;
      }
      final savedLight = prefs.getBool(_lightModeKey);
      if (savedLight != null) {
        _isLight = savedLight;
        // Si aucune couleur personnalisée n'était sauvegardée, recalculer le fond par défaut
        _backgroundColor = savedBg != null
            ? Color(savedBg)
            : (_isLight
                ? _backgroundForLight(_currentPalette)
                : _backgroundFor(_currentPalette));
      }
      // Si aucune image n'est définie, tenter un fond mock aléatoire (pour tests)
      if (_backgroundImagePath == null) {
        await _applyRandomMockBackgroundIfPresent();
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

  /// Charge aléatoirement une image depuis le dossier mock s'il existe
  Future<void> _applyRandomMockBackgroundIfPresent() async {
    try {
      final dir = Directory(_mockBackgroundFolder);
      if (!dir.existsSync()) return;
      final images = dir
          .listSync()
          .whereType<File>()
          .where((f) {
            final lower = f.path.toLowerCase();
            return lower.endsWith('.jpg') ||
                lower.endsWith('.jpeg') ||
                lower.endsWith('.png') ||
                lower.endsWith('.webp');
          })
          .toList();
      if (images.isEmpty) return;
      final file = images[Random().nextInt(images.length)];
      await setBackgroundImage(file);
      if (FeatureFlags.debugThemeChanges) {
        debugPrint('🖼️ ThemeProvider: mock background applied from ${file.path}');
      }
    } catch (e) {
      debugPrint('❌ ThemeProvider: Error applying mock background: $e');
    }
  }
}
