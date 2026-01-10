import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const String _backgroundThemeKey = 'background_theme_id';
  static const String _backgroundImageIndexKey = 'background_image_index';
  static const String _backgroundRefreshPeriodKey = 'background_refresh_period';
  static const String _lastBackgroundChangeKey = 'last_background_change';
  static const String _themeModeKey = 'theme_mode';
  static const String _lightModeKey = 'use_light_theme';
  static const String _useGlassmorphismKey = 'use_glassmorphism';
  static const String _blurIntensityKey = 'blur_intensity';
  static const String _showAnimationsKey = 'show_animations';
  static const String _defaultThemeId = 'green';
  static const String _backgroundThemesAsset =
      'assets/themes/background_themes.json';

  /// Palette actuellement active
  ColorPalette _currentPalette = ColorPalette.warmSunset;
  Color _backgroundColor = DesignTokens.background;
  String? _backgroundImagePath;
  String? _backgroundImageAttribution;
  List<BackgroundTheme> _backgroundThemes = [];
  String? _backgroundThemeId;
  int _backgroundImageIndex = 0;
  bool _isLight = false;
  BackgroundRefreshPeriod _backgroundRefreshPeriod =
      BackgroundRefreshPeriod.none;
  DateTime? _lastBackgroundChange;
  Timer? _backgroundRefreshTimer;

  /// Nouveaux paramètres d'apparence
  settings.ThemeMode _themeModePreference = settings.ThemeMode.adaptive;
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
  String? get backgroundImageAttribution => _backgroundImageAttribution;

  bool get hasBackgroundImage =>
      _backgroundImagePath != null &&
      (_backgroundImagePath!.startsWith('assets/') ||
          File(_backgroundImagePath!).existsSync());

  ImageProvider? get backgroundImageProvider {
    final path = _backgroundImagePath;
    if (path == null) return null;
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }
    final file = File(path);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return null;
  }

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
  List<BackgroundTheme> get backgroundThemes => _backgroundThemes;
  String? get backgroundThemeId => _backgroundThemeId;
  int get backgroundImageIndex => _backgroundImageIndex;
  BackgroundTheme? get selectedBackgroundTheme {
    for (final theme in _backgroundThemes) {
      if (theme.id == _backgroundThemeId) return theme;
    }
    return null;
  }

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

  Future<void> clearBackgroundImage() async {
    _backgroundImagePath = null;
    _backgroundImageAttribution = null;
    _backgroundThemeId = null;
    _backgroundImageIndex = 0;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backgroundImageKey);
    await prefs.remove(_backgroundThemeKey);
    await prefs.remove(_backgroundImageIndexKey);
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
    _backgroundRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> setBackgroundTheme(String? themeId) async {
    if (_backgroundThemeId == themeId) return;
    _backgroundThemeId = themeId;
    _backgroundImageIndex = 0;
    _applyThemeImage();
    _lastBackgroundChange = DateTime.now();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (themeId == null) {
      await prefs.remove(_backgroundThemeKey);
      await prefs.remove(_backgroundImageIndexKey);
    } else {
      await prefs.setString(_backgroundThemeKey, themeId);
      await prefs.setInt(_backgroundImageIndexKey, _backgroundImageIndex);
    }
    await _saveLastBackgroundChange();
    _scheduleBackgroundRefreshTimer();
  }

  Future<void> setBackgroundImageIndex(int index) async {
    final theme = selectedBackgroundTheme;
    if (theme == null) return;
    final nextIndex = index.clamp(0, theme.images.length - 1);
    if (_backgroundImageIndex == nextIndex) return;
    _backgroundImageIndex = nextIndex;
    _applyThemeImage();
    _lastBackgroundChange = DateTime.now();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_backgroundImageIndexKey, _backgroundImageIndex);
    await _saveLastBackgroundChange();
    _scheduleBackgroundRefreshTimer();
  }

  Future<void> applyRandomThemeImage(String themeId, {int? limitToFirst}) async {
    final theme = _findThemeById(themeId);
    if (theme == null || theme.images.isEmpty) return;
    final maxCount = (limitToFirst == null)
        ? theme.images.length
        : theme.images.length < limitToFirst
            ? theme.images.length
            : limitToFirst;
    _backgroundThemeId = themeId;
    _backgroundImageIndex = Random().nextInt(maxCount);
    _applyThemeImage();
    _lastBackgroundChange = DateTime.now();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundThemeKey, themeId);
    await prefs.setInt(_backgroundImageIndexKey, _backgroundImageIndex);
    await _saveLastBackgroundChange();
    _scheduleBackgroundRefreshTimer();
  }

  /// Force un nouvel arrière-plan aléatoire.
  /// - Si un dossier est configuré, on pioche dedans.
  /// - Sinon on tente le dossier mock si présent.
  Future<void> refreshRandomBackground() async {
    final theme = selectedBackgroundTheme;
    if (theme == null || theme.images.isEmpty) return;
    final randomIndex = Random().nextInt(theme.images.length);
    await setBackgroundImageIndex(randomIndex);
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
    _scheduleBackgroundRefreshTimer();
  }

  /// Vérifie si la période est dépassée et relance un fond aléatoire si besoin.
  Future<void> checkAndRefreshBackgroundIfDue() async {
    final theme = selectedBackgroundTheme;
    if (theme == null || theme.images.isEmpty) return;
    if (_backgroundRefreshPeriod == BackgroundRefreshPeriod.none) return;

    final now = DateTime.now();
    final last = _lastBackgroundChange;
    final duration = _periodToDuration(_backgroundRefreshPeriod);

    if (last == null || now.difference(last) >= duration) {
      final nextIndex = (_backgroundImageIndex + 1) % theme.images.length;
      await setBackgroundImageIndex(nextIndex);
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

      await _loadBackgroundThemes();
      final savedThemeId = prefs.getString(_backgroundThemeKey);
      if (savedThemeId != null &&
          _backgroundThemes.any((theme) => theme.id == savedThemeId)) {
        _backgroundThemeId = savedThemeId;
      } else if (_backgroundThemes.any(
        (theme) => theme.id == _defaultThemeId,
      )) {
        _backgroundThemeId = _defaultThemeId;
      } else if (_backgroundThemes.isNotEmpty) {
        _backgroundThemeId = _backgroundThemes.first.id;
      }

      final savedImageIndex = prefs.getInt(_backgroundImageIndexKey);
      if (savedImageIndex != null) {
        _backgroundImageIndex = savedImageIndex;
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

      _applyThemeImage();
      _lastBackgroundChange ??= DateTime.now();
      await _saveLastBackgroundChange();
      await checkAndRefreshBackgroundIfDue();
      _scheduleBackgroundRefreshTimer();
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

  Future<void> _loadBackgroundThemes() async {
    try {
      final raw = await rootBundle.loadString(_backgroundThemesAsset);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final themesJson = decoded['themes'] as List<dynamic>? ?? const [];
      _backgroundThemes = themesJson
          .map((item) => BackgroundTheme.fromJson(item as Map<String, dynamic>))
          .where((theme) => theme.images.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('❌ ThemeProvider: Error loading background themes: $e');
      _backgroundThemes = [];
    }
  }

  void _applyThemeImage() {
    final theme = selectedBackgroundTheme;
    if (theme == null || theme.images.isEmpty) {
      _backgroundImagePath = null;
      _backgroundImageAttribution = null;
      return;
    }
    final index = _backgroundImageIndex.clamp(0, theme.images.length - 1);
    final image = theme.images[index];
    _backgroundImagePath = image.path;
    _backgroundImageAttribution = image.attribution;
  }

  void _scheduleBackgroundRefreshTimer() {
    _backgroundRefreshTimer?.cancel();
    if (_backgroundRefreshPeriod == BackgroundRefreshPeriod.none) return;
    final theme = selectedBackgroundTheme;
    if (theme == null || theme.images.isEmpty) return;

    final duration = _periodToDuration(_backgroundRefreshPeriod);
    if (duration == Duration.zero) return;

    final last = _lastBackgroundChange ?? DateTime.now();
    var delay = duration - DateTime.now().difference(last);
    if (delay.isNegative) {
      delay = Duration.zero;
    }

    _backgroundRefreshTimer = Timer(delay, () async {
      await checkAndRefreshBackgroundIfDue();
      _scheduleBackgroundRefreshTimer();
    });
  }

  BackgroundTheme? _findThemeById(String themeId) {
    for (final theme in _backgroundThemes) {
      if (theme.id == themeId) return theme;
    }
    return null;
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

class BackgroundThemeImage {
  const BackgroundThemeImage({required this.path, required this.attribution});

  final String path;
  final String attribution;

  factory BackgroundThemeImage.fromJson(Map<String, dynamic> json) {
    return BackgroundThemeImage(
      path: json['path'] as String? ?? '',
      attribution: json['attribution'] as String? ?? '',
    );
  }
}

class BackgroundTheme {
  const BackgroundTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
  });

  final String id;
  final String name;
  final String description;
  final List<BackgroundThemeImage> images;

  factory BackgroundTheme.fromJson(Map<String, dynamic> json) {
    final imagesJson = json['images'] as List<dynamic>? ?? const [];
    return BackgroundTheme(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      images: imagesJson
          .map(
            (item) =>
                BackgroundThemeImage.fromJson(item as Map<String, dynamic>),
          )
          .where((image) => image.path.isNotEmpty)
          .toList(),
    );
  }
}
