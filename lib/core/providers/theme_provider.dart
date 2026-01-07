import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/widgets/appearance_settings_dialog_v2.dart' as settings;
import '../config/feature_flags.dart';
import '../theme/color_palettes.dart';
import '../theme/design_tokens.dart';

/// Période de rotation automatique du fond
enum BackgroundRefreshPeriod {
  none,
  tenMinutes,
  oneHour,
  oneDay,
  oneWeek,
  oneMonth,
}

/// Provider pour gérer le thème de l'application (palette de couleurs)
/// Utilise ChangeNotifier pour notifier les widgets des changements
/// Persiste la palette sélectionnée avec SharedPreferences
class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  /// Clés pour sauvegarder les paramètres dans SharedPreferences
  static const String _paletteKey = 'selected_color_palette';
  static const String _backgroundColorKey = 'selected_background_color';
  static const String _backgroundImageKey = 'selected_background_image';
  static const String _backgroundFolderKey = 'selected_background_folder';
  static const String _backgroundTypeKey = 'background_type';
  static const String _backgroundRefreshPeriodKey = 'background_refresh_period';
  static const String _lastBackgroundChangeKey = 'last_background_change';
  static const String _themeModeKey = 'theme_mode';
  static const String _lightModeKey = 'use_light_theme';
  static const String _useGlassmorphismKey = 'use_glassmorphism';
  static const String _blurIntensityKey = 'blur_intensity';
  static const String _showAnimationsKey = 'show_animations';
  static const String _mockBackgroundFolder = '/Volumes/Datas/Backgrounds';

  /// Palette actuellement active
  ColorPalette _currentPalette = ColorPalette.warmSunset;
  Color _backgroundColor = DesignTokens.background;
  String? _backgroundImagePath;
  String? _backgroundFolderPath;
  bool _isLight = false;
  BackgroundRefreshPeriod _backgroundRefreshPeriod =
      BackgroundRefreshPeriod.none;
  DateTime? _lastBackgroundChange;

  /// Nouveaux paramètres d'apparence
  settings.ThemeMode _themeModePreference = settings.ThemeMode.adaptive;
  settings.BackgroundType _backgroundType = settings.BackgroundType.none;
  bool _useGlassmorphism = true;
  double _blurIntensity = 10.0;
  bool _showAnimations = true;

  /// Indique si le provider est en cours de chargement
  bool _isLoading = true;

  /// Constructeur qui charge automatiquement la palette sauvegardée
  ThemeProvider() {
    WidgetsBinding.instance.addObserver(this);
    _loadSavedPalette();
  }

  // ==========================================================================
  // GETTERS
  // ==========================================================================

  /// Retourne la palette actuellement active
  ColorPalette get currentPalette => _currentPalette;

  /// Retourne les données de couleurs de la palette active (adaptées au mode clair/sombre)
  ColorPaletteData get colors =>
      ColorPalettes.getAdaptiveData(_currentPalette, _isLight);

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

  /// Nouveaux getters pour les paramètres d'apparence
  settings.ThemeMode get themeModePreference => _themeModePreference;
  settings.BackgroundType get backgroundType => _backgroundType;
  String? get backgroundFolderPath => _backgroundFolderPath;
  bool get useGlassmorphism => _useGlassmorphism;
  double get blurIntensity => _blurIntensity;
  bool get showAnimations => _showAnimations;
  BackgroundRefreshPeriod get backgroundRefreshPeriod =>
      _backgroundRefreshPeriod;
  DateTime? get lastBackgroundChange => _lastBackgroundChange;

  // ==========================================================================
  // MÉTHODES PUBLIQUES
  // ==========================================================================

  /// Change la palette de couleurs et persiste le choix
  Future<void> setPalette(ColorPalette palette) async {
    if (_currentPalette == palette) return;

    if (FeatureFlags.debugThemeChanges) {
      debugPrint(
        '🎨 ThemeProvider: Changing palette from '
        '${_currentPalette.displayName} to ${palette.displayName}',
      );
    }

    _currentPalette = palette;
    _backgroundColor = _isLight
        ? _backgroundForLight(palette)
        : _backgroundFor(palette);
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
    final previousIndex =
        (currentIndex - 1 + palettes.length) % palettes.length;
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
      final name = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : 'bg';
      final dest = File(
        '${bgDir.path}/bg_${DateTime.now().millisecondsSinceEpoch}_$name',
      );
      await file.copy(dest.path);
      _backgroundImagePath = dest.path;
      _lastBackgroundChange = DateTime.now();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backgroundImageKey, dest.path);
      await _saveLastBackgroundChange();
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
    _backgroundColor = value
        ? _backgroundForLight(_currentPalette)
        : _backgroundFor(_currentPalette);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lightModeKey, value);
    await prefs.setInt(_backgroundColorKey, _backgroundColor.value);
  }

  /// Nouvelles méthodes pour les paramètres d'apparence
  Future<void> setThemeMode(settings.ThemeMode mode) async {
    if (_themeModePreference == mode) return;
    _themeModePreference = mode;

    // Appliquer le mode immédiatement
    if (mode == settings.ThemeMode.light) {
      await setLightMode(true);
    } else if (mode == settings.ThemeMode.dark) {
      await setLightMode(false);
    } else {
      // Adaptive: déterminer selon le système
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      await setLightMode(brightness == Brightness.light);
    }

    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  @override
  void didChangePlatformBrightness() {
    if (_themeModePreference != settings.ThemeMode.adaptive) return;
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    setLightMode(brightness == Brightness.light);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> setBackgroundType(settings.BackgroundType type) async {
    if (_backgroundType == type) return;
    _backgroundType = type;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_backgroundTypeKey, type.index);
  }

  Future<void> setBackgroundFolder(String folderPath) async {
    _backgroundFolderPath = folderPath;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundFolderKey, folderPath);

    // Charger une image aléatoire depuis le dossier
    await _applyRandomBackgroundFromFolder(folderPath);
  }

  /// Force un nouvel arrière-plan aléatoire.
  /// - Si un dossier est configuré, on pioche dedans.
  /// - Sinon on tente le dossier mock si présent.
  Future<void> refreshRandomBackground() async {
    if (_backgroundFolderPath != null) {
      await _applyRandomBackgroundFromFolder(_backgroundFolderPath!);
      _lastBackgroundChange = DateTime.now();
      await _saveLastBackgroundChange();
    } else {
      await _applyRandomMockBackgroundIfPresent();
    }
  }

  Future<void> setUseGlassmorphism(bool value) async {
    if (_useGlassmorphism == value) return;
    _useGlassmorphism = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useGlassmorphismKey, value);
  }

  Future<void> setBlurIntensity(double value) async {
    if (_blurIntensity == value) return;
    _blurIntensity = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_blurIntensityKey, value);
  }

  Future<void> setShowAnimations(bool value) async {
    if (_showAnimations == value) return;
    _showAnimations = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showAnimationsKey, value);
  }

  Future<void> setBackgroundRefreshPeriod(
    BackgroundRefreshPeriod period,
  ) async {
    if (_backgroundRefreshPeriod == period) return;
    _backgroundRefreshPeriod = period;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_backgroundRefreshPeriodKey, period.index);
    await checkAndRefreshBackgroundIfDue();
  }

  /// Vérifie si la période est dépassée et relance un fond aléatoire si besoin.
  Future<void> checkAndRefreshBackgroundIfDue() async {
    if (_backgroundType != settings.BackgroundType.imageFolder ||
        _backgroundFolderPath == null)
      return;
    if (_backgroundRefreshPeriod == BackgroundRefreshPeriod.none) return;

    final now = DateTime.now();
    final last = _lastBackgroundChange;
    final duration = _periodToDuration(_backgroundRefreshPeriod);

    if (last == null || now.difference(last) >= duration) {
      await refreshRandomBackground();
    }
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
        _backgroundColor = _isLight
            ? _backgroundForLight(_currentPalette)
            : _backgroundFor(_currentPalette);
        if (FeatureFlags.debugThemeChanges) {
          debugPrint(
            '✅ ThemeProvider: Loaded palette ${_currentPalette.displayName}',
          );
        }
      } else {
        if (FeatureFlags.debugThemeChanges) {
          debugPrint(
            'ℹ️  ThemeProvider: No saved palette, using default (Neon Cyberpunk)',
          );
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

      // Charger les nouveaux paramètres d'apparence
      final savedThemeMode = prefs.getInt(_themeModeKey);
      if (savedThemeMode != null &&
          savedThemeMode < settings.ThemeMode.values.length) {
        _themeModePreference = settings.ThemeMode.values[savedThemeMode];
      }

      final savedBackgroundType = prefs.getInt(_backgroundTypeKey);
      if (savedBackgroundType != null &&
          savedBackgroundType < settings.BackgroundType.values.length) {
        _backgroundType = settings.BackgroundType.values[savedBackgroundType];
      }

      final savedBackgroundFolder = prefs.getString(_backgroundFolderKey);
      if (savedBackgroundFolder != null && savedBackgroundFolder.isNotEmpty) {
        _backgroundFolderPath = savedBackgroundFolder;
      }

      final savedRefreshPeriod = prefs.getInt(_backgroundRefreshPeriodKey);
      if (savedRefreshPeriod != null &&
          savedRefreshPeriod < BackgroundRefreshPeriod.values.length) {
        _backgroundRefreshPeriod =
            BackgroundRefreshPeriod.values[savedRefreshPeriod];
      }

      final savedLastChange = prefs.getInt(_lastBackgroundChangeKey);
      if (savedLastChange != null) {
        _lastBackgroundChange = DateTime.fromMillisecondsSinceEpoch(
          savedLastChange,
          isUtc: false,
        );
      }

      final savedGlassmorphism = prefs.getBool(_useGlassmorphismKey);
      if (savedGlassmorphism != null) {
        _useGlassmorphism = savedGlassmorphism;
      }

      final savedBlurIntensity = prefs.getDouble(_blurIntensityKey);
      if (savedBlurIntensity != null) {
        _blurIntensity = savedBlurIntensity;
      }

      final savedAnimations = prefs.getBool(_showAnimationsKey);
      if (savedAnimations != null) {
        _showAnimations = savedAnimations;
      }

      // En mode adaptatif, suivre le thème du système
      if (_themeModePreference == settings.ThemeMode.adaptive) {
        final systemBrightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        _isLight = systemBrightness == Brightness.light;
        _backgroundColor = _isLight
            ? _backgroundForLight(_currentPalette)
            : _backgroundFor(_currentPalette);
      }

      // Appliquer le fond selon le type configuré
      if (_backgroundType == settings.BackgroundType.imageFolder &&
          _backgroundFolderPath != null) {
        await _applyRandomBackgroundFromFolder(_backgroundFolderPath!);
        _lastBackgroundChange ??= DateTime.now();
        await _saveLastBackgroundChange();
        await checkAndRefreshBackgroundIfDue();
      } else if (_backgroundType == settings.BackgroundType.none ||
          _backgroundImagePath == null) {
        // Si aucun fond configuré et aucune image, tenter le dossier mock (pour tests)
        if (_backgroundType == settings.BackgroundType.none) {
          await _applyRandomMockBackgroundIfPresent();
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

  /// Charge aléatoirement une image depuis le dossier mock s'il existe
  Future<void> _applyRandomMockBackgroundIfPresent() async {
    try {
      final dir = Directory(_mockBackgroundFolder);
      if (!dir.existsSync()) return;
      final images = dir.listSync().whereType<File>().where((f) {
        final lower = f.path.toLowerCase();
        return lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.webp');
      }).toList();
      if (images.isEmpty) return;
      final file = images[Random().nextInt(images.length)];
      await setBackgroundImage(file);
      if (FeatureFlags.debugThemeChanges) {
        debugPrint(
          '🖼️ ThemeProvider: mock background applied from ${file.path}',
        );
      }
    } catch (e) {
      debugPrint('❌ ThemeProvider: Error applying mock background: $e');
    }
  }

  /// Charge aléatoirement une image depuis un dossier personnalisé
  Future<void> _applyRandomBackgroundFromFolder(String folderPath) async {
    try {
      final dir = Directory(folderPath);
      if (!dir.existsSync()) {
        debugPrint('❌ ThemeProvider: Folder does not exist: $folderPath');
        return;
      }

      final images = dir.listSync().whereType<File>().where((f) {
        final lower = f.path.toLowerCase();
        return lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.webp') ||
            lower.endsWith('.gif');
      }).toList();

      if (images.isEmpty) {
        debugPrint('❌ ThemeProvider: No images found in folder: $folderPath');
        return;
      }

      final file = images[Random().nextInt(images.length)];
      await setBackgroundImage(file);

      if (FeatureFlags.debugThemeChanges) {
        debugPrint(
          '🖼️ ThemeProvider: Random background from folder: ${file.path}',
        );
      }
    } catch (e) {
      debugPrint('❌ ThemeProvider: Error applying random background: $e');
    }
  }

  Future<void> _saveLastBackgroundChange() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = _lastBackgroundChange?.millisecondsSinceEpoch;
    if (timestamp != null) {
      await prefs.setInt(_lastBackgroundChangeKey, timestamp);
    }
  }

  Duration _periodToDuration(BackgroundRefreshPeriod period) {
    switch (period) {
      case BackgroundRefreshPeriod.tenMinutes:
        return const Duration(minutes: 10);
      case BackgroundRefreshPeriod.oneHour:
        return const Duration(hours: 1);
      case BackgroundRefreshPeriod.oneDay:
        return const Duration(days: 1);
      case BackgroundRefreshPeriod.oneWeek:
        return const Duration(days: 7);
      case BackgroundRefreshPeriod.oneMonth:
        return const Duration(days: 30);
      case BackgroundRefreshPeriod.none:
      default:
        return Duration.zero;
    }
  }
}
