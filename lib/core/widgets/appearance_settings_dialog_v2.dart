import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:macos_file_picker/macos_file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../providers/theme_provider.dart';
import '../theme/color_palettes.dart';

/// Mode de thème (clair, sombre, adaptatif)
enum ThemeMode {
  light,
  dark,
  adaptive,
}

/// Type de fond (aucun, couleur, image, dossier d'images)
enum BackgroundType {
  none,
  color,
  singleImage,
  imageFolder,
}

/// Dialog moderne et responsive pour configurer l'apparence
class AppearanceSettingsDialogV2 extends StatefulWidget {
  const AppearanceSettingsDialogV2({super.key});

  @override
  State<AppearanceSettingsDialogV2> createState() =>
      _AppearanceSettingsDialogV2State();
}

class _AppearanceSettingsDialogV2State
    extends State<AppearanceSettingsDialogV2> {
  late ThemeMode _themeMode;
  late BackgroundType _backgroundType;
  late Color _backgroundColor;
  String? _backgroundImagePath;
  String? _backgroundFolderPath;
  late bool _useGlassmorphism;
  late double _blurIntensity;
  late bool _showAnimations;
  bool _hoverChangeImage = false;

  @override
  void initState() {
    super.initState();
    final themeProvider = context.read<ThemeProvider>();

    _themeMode = themeProvider.themeModePreference;
    _backgroundType = themeProvider.backgroundType;
    _backgroundColor = themeProvider.backgroundColor;
    _backgroundImagePath = themeProvider.backgroundImagePath;
    _backgroundFolderPath = themeProvider.backgroundFolderPath;
    _useGlassmorphism = themeProvider.useGlassmorphism;
    _blurIntensity = themeProvider.blurIntensity;
    _showAnimations = themeProvider.showAnimations;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;
    final textColor = isLight ? Colors.black87 : Colors.white;
    final subtleTextColor =
        isLight ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.7);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 900,
              maxHeight: 700,
            ),
            decoration: BoxDecoration(
              color: isLight
                  ? Colors.white.withValues(alpha: 0.78)
                  : Colors.black.withValues(alpha: 0.80),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLight
                    ? Colors.black.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(isLight, textColor),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: isMobile
                            ? _buildSingleColumn(isLight, textColor, subtleTextColor)
                            : _buildTwoColumns(isLight, textColor, subtleTextColor),
                      );
                    },
                  ),
                ),
                _buildFooter(isLight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isLight, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLight
                ? Colors.black.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.palette,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paramètres d\'apparence',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Text(
                  'Personnalisez l\'interface selon vos préférences',
                  style: TextStyle(
                    fontSize: 13,
                    color: isLight
                        ? Colors.black.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.x, size: 20, color: textColor),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Fermer',
          ),
        ],
      ),
    );
  }

  Widget _buildSingleColumn(
    bool isLight,
    Color textColor,
    Color subtleTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildThemeModeSection(isLight, textColor, subtleTextColor),
        const SizedBox(height: 24),
        _buildPaletteSection(isLight, textColor),
        const SizedBox(height: 24),
        _buildBackgroundSection(isLight, textColor, subtleTextColor),
        const SizedBox(height: 24),
        _buildAdvancedSection(isLight, textColor, subtleTextColor),
      ],
    );
  }

  Widget _buildTwoColumns(
    bool isLight,
    Color textColor,
    Color subtleTextColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Colonne gauche
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThemeModeSection(isLight, textColor, subtleTextColor),
              const SizedBox(height: 24),
              _buildPaletteSection(isLight, textColor),
            ],
          ),
        ),
        const SizedBox(width: 32),
        // Colonne droite
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackgroundSection(isLight, textColor, subtleTextColor),
              const SizedBox(height: 24),
              _buildAdvancedSection(isLight, textColor, subtleTextColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeModeSection(
    bool isLight,
    Color textColor,
    Color subtleTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Mode de thème', LucideIcons.moonStar, textColor),
        const SizedBox(height: 12),
        _buildThemeModeOption(
          ThemeMode.light,
          'Mode clair',
          'Interface claire en permanence',
          LucideIcons.sun,
          isLight,
          textColor,
          subtleTextColor,
        ),
        const SizedBox(height: 8),
        _buildThemeModeOption(
          ThemeMode.dark,
          'Mode sombre',
          'Interface sombre en permanence',
          LucideIcons.moon,
          isLight,
          textColor,
          subtleTextColor,
        ),
        const SizedBox(height: 8),
        _buildThemeModeOption(
          ThemeMode.adaptive,
          'Adaptatif',
          'Suit les paramètres système',
          LucideIcons.monitorSmartphone,
          isLight,
          textColor,
          subtleTextColor,
        ),
      ],
    );
  }

  Widget _buildPaletteSection(bool isLight, Color textColor) {
    final themeProvider = context.watch<ThemeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Palette de couleurs', LucideIcons.palette, textColor),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ColorPalette.values.map((palette) {
            final isSelected = palette == themeProvider.currentPalette;
            final colors = ColorPalettes.getData(palette);

            return InkWell(
              onTap: () => themeProvider.setPalette(palette),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                      : (isLight
                          ? Colors.white.withValues(alpha: 0.7) // Fond blanc semi-opaque en mode clair
                          : Colors.white.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : (isLight
                            ? Colors.black.withValues(alpha: 0.15) // Border plus visible en mode clair
                            : Colors.white.withValues(alpha: 0.15)),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ColorDot(color: colors.primary, size: 12),
                        const SizedBox(width: 4),
                        _ColorDot(color: colors.navigation, size: 12),
                        const SizedBox(width: 4),
                        _ColorDot(color: colors.info, size: 12),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Text(
                      palette.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isLight ? Colors.black87 : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBackgroundSection(
    bool isLight,
    Color textColor,
    Color subtleTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Arrière-plan', LucideIcons.image, textColor),
        const SizedBox(height: 12),
        _buildBackgroundTypeOption(
          BackgroundType.none,
          'Aucun',
          'Fond uni sans image',
          LucideIcons.ban,
          isLight,
          textColor,
          subtleTextColor,
        ),
        const SizedBox(height: 8),
        _buildBackgroundTypeOption(
          BackgroundType.singleImage,
          'Image unique',
          'Une seule image en arrière-plan',
          LucideIcons.image,
          isLight,
          textColor,
          subtleTextColor,
        ),
        const SizedBox(height: 8),
        _buildBackgroundTypeOption(
          BackgroundType.imageFolder,
          'Dossier d\'images',
          'Images aléatoires depuis un dossier',
          LucideIcons.folderOpen,
          isLight,
          textColor,
          subtleTextColor,
        ),
        if (_backgroundType == BackgroundType.singleImage) ...[
          const SizedBox(height: 12),
          _buildImagePicker(isLight, textColor),
        ],
        if (_backgroundType == BackgroundType.imageFolder) ...[
          const SizedBox(height: 12),
          _buildFolderPicker(isLight, textColor),
        ],
      ],
    );
  }

  Widget _buildAdvancedSection(
    bool isLight,
    Color textColor,
    Color subtleTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Options avancées', LucideIcons.sliders, textColor),
        const SizedBox(height: 12),
        _buildToggleOption(
          'Glassmorphism',
          'Effets de verre et de flou',
          _useGlassmorphism,
          (value) => setState(() => _useGlassmorphism = value),
          isLight,
          textColor,
          subtleTextColor,
        ),
        if (_useGlassmorphism) ...[
          const SizedBox(height: 12),
          _buildSliderOption(
            'Intensité du flou',
            _blurIntensity,
            0.0,
            20.0,
            (value) => setState(() => _blurIntensity = value),
            isLight,
            textColor,
          ),
        ],
        const SizedBox(height: 12),
        _buildToggleOption(
          'Animations',
          'Transitions et effets animés',
          _showAnimations,
          (value) => setState(() => _showAnimations = value),
          isLight,
          textColor,
          subtleTextColor,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: textColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeModeOption(
    ThemeMode mode,
    String title,
    String description,
    IconData icon,
    bool isLight,
    Color textColor,
    Color subtleTextColor,
  ) {
    final isSelected = _themeMode == mode;

    return InkWell(
      onTap: () => setState(() => _themeMode = mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
              : (isLight
                  ? Colors.white.withValues(alpha: 0.8) // Fond blanc semi-opaque en mode clair
                  : Colors.white.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                : (isLight
                    ? Colors.black.withValues(alpha: 0.15) // Border plus visible en mode clair
                    : Colors.white.withValues(alpha: 0.12)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Theme.of(context).colorScheme.primary : textColor.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtleTextColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.check,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundTypeOption(
    BackgroundType type,
    String title,
    String description,
    IconData icon,
    bool isLight,
    Color textColor,
    Color subtleTextColor,
  ) {
    final isSelected = _backgroundType == type;

    return InkWell(
      onTap: () => setState(() => _backgroundType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
              : (isLight
                  ? Colors.white.withValues(alpha: 0.8) // Fond blanc semi-opaque en mode clair
                  : Colors.white.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                : (isLight
                    ? Colors.black.withValues(alpha: 0.15) // Border plus visible en mode clair
                    : Colors.white.withValues(alpha: 0.12)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Theme.of(context).colorScheme.primary : textColor.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: subtleTextColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.check,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(bool isLight, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_backgroundImagePath != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isLight
                  ? Colors.white.withValues(alpha: 0.7) // Fond blanc semi-opaque en mode clair
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.fileImage,
                  size: 16,
                  color: textColor.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _backgroundImagePath!.split('/').last,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    size: 14,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                  onPressed: () => setState(() => _backgroundImagePath = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        MouseRegion(
          onEnter: (_) => setState(() => _hoverChangeImage = true),
          onExit: (_) => setState(() => _hoverChangeImage = false),
          child: AnimatedScale(
            scale: _hoverChangeImage ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: ElevatedButton.icon(
              onPressed: _pickBackgroundImage,
              icon: const Icon(LucideIcons.upload, size: 16),
              label: Text(_backgroundImagePath == null
                  ? 'Choisir une image'
                  : 'Changer l\'image'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                foregroundColor: Theme.of(context).colorScheme.primary,
                overlayColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFolderPicker(bool isLight, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_backgroundFolderPath != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isLight
                  ? Colors.white.withValues(alpha: 0.7) // Fond blanc semi-opaque en mode clair
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.folder,
                  size: 16,
                  color: textColor.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _backgroundFolderPath!,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    size: 14,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                  onPressed: () => setState(() => _backgroundFolderPath = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        ElevatedButton.icon(
          onPressed: _pickBackgroundFolder,
          icon: const Icon(LucideIcons.folderOpen, size: 16),
          label: Text(_backgroundFolderPath == null
              ? 'Choisir un dossier'
              : 'Changer le dossier'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleOption(
    String title,
    String description,
    bool value,
    ValueChanged<bool> onChanged,
    bool isLight,
    Color textColor,
    Color subtleTextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.black.withValues(alpha: 0.03)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLight
              ? Colors.black.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtleTextColor,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderOption(
    String title,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    bool isLight,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.black.withValues(alpha: 0.03)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLight
              ? Colors.black.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              thumbColor: Theme.of(context).colorScheme.primary,
              overlayColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isLight) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isLight
                ? Colors.black.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: isLight ? Colors.black87 : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _applySettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickBackgroundImage() async {
    // Fallback AppleScript natif macOS (aucun plugin requis)
    if (Platform.isMacOS) {
      final path = await _pickMacOsPath(
        command: 'POSIX path of (choose file)',
      );
      if (path != null) {
        setState(() => _backgroundImagePath = path);
        return;
      } else {
        return; // cancel => ne pas chaîner les fallbacks
      }
    }

    // Essai natif macOS si dispo
    if (Platform.isMacOS) {
      try {
        final picker = MacosFilePicker();
        final result = await picker.pick(
          MacosFilePickerMode.file,
          allowsMultiple: false,
          allowedFileExtensions: ['png', 'jpg', 'jpeg', 'webp'],
        );
        if (result != null && result.isNotEmpty) {
          setState(() => _backgroundImagePath = result.first.path);
          return;
        } else {
          return; // cancel
        }
      } catch (e) {
        debugPrint('macos_file_picker image error: $e');
      }
    }

    // Essai avec file_selector (desktop natif)
    try {
      final typeGroup = const XTypeGroup(
        label: 'Images',
        extensions: ['png', 'jpg', 'jpeg', 'webp'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file != null && file.path.isNotEmpty) {
        setState(() {
          _backgroundImagePath = file.path;
        });
        return;
      } else {
        return; // cancel
      }
    } on PlatformException catch (e) {
      debugPrint('file_selector image error: $e');
    } on MissingPluginException catch (_) {
      // ignore, fallback below
    } catch (e) {
      debugPrint('Erreur file_selector image: $e');
    }

    // Fallback avec file_picker
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _backgroundImagePath = result.files.single.path!;
        });
        return;
      } else {
        return; // cancel
      }
    } catch (e) {
      debugPrint('Erreur file_picker image: $e');
    }

    _showSnack('Impossible d’ouvrir le sélecteur d’image sur cette plateforme.');
  }

  Future<void> _pickBackgroundFolder() async {
    // Fallback AppleScript natif macOS (aucun plugin requis)
    if (Platform.isMacOS) {
      final path = await _pickMacOsPath(
        command: 'POSIX path of (choose folder)',
      );
      if (path != null) {
        setState(() => _backgroundFolderPath = path);
        return;
      } else {
        return; // cancel
      }
    }

    // Essai natif macOS si dispo
    if (Platform.isMacOS) {
      try {
        final picker = MacosFilePicker();
        final result = await picker.pick(
          MacosFilePickerMode.folder,
          allowsMultiple: false,
        );
        if (result != null && result.isNotEmpty) {
          setState(() => _backgroundFolderPath = result.first.path);
          return;
        } else {
          return; // cancel
        }
      } catch (e) {
        debugPrint('macos_file_picker dir error: $e');
      }
    }

    // Essai avec file_selector
    try {
      final String? directoryPath = await getDirectoryPath();
      if (directoryPath != null && directoryPath.isNotEmpty) {
        setState(() {
          _backgroundFolderPath = directoryPath;
        });
        return;
      } else {
        return; // cancel
      }
    } on PlatformException catch (e) {
      debugPrint('file_selector dir error: $e');
    } on MissingPluginException catch (_) {
      // ignore, fallback below
    } catch (e) {
      debugPrint('Erreur file_selector dossier: $e');
    }

    // Fallback avec file_picker
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        setState(() {
          _backgroundFolderPath = result;
        });
        return;
      } else {
        return; // cancel
      }
    } catch (e) {
      debugPrint('Erreur file_picker dossier: $e');
    }

    _showSnack('Impossible d’ouvrir le sélecteur de dossier sur cette plateforme.');
  }

  Future<String?> _pickMacOsPath({required String command}) async {
    try {
      final result = await Process.run(
        'osascript',
        ['-e', command],
      );
      if (result.exitCode == 0) {
        final path = (result.stdout as String).trim();
        if (path.isNotEmpty) return path;
      }
    } catch (e) {
      debugPrint('AppleScript picker error: $e');
    }
    return null;
  }

  Future<void> _applySettings() async {
    final themeProvider = context.read<ThemeProvider>();

    await themeProvider.setThemeMode(_themeMode);
    await themeProvider.setBackgroundType(_backgroundType);

    if (_backgroundType == BackgroundType.singleImage &&
        _backgroundImagePath != null) {
      await themeProvider.setBackgroundImage(File(_backgroundImagePath!));
    } else if (_backgroundType == BackgroundType.imageFolder &&
        _backgroundFolderPath != null) {
      await themeProvider.setBackgroundFolder(_backgroundFolderPath!);
    } else if (_backgroundType == BackgroundType.none) {
      await themeProvider.clearBackgroundImage();
    }

    await themeProvider.setUseGlassmorphism(_useGlassmorphism);
    await themeProvider.setBlurIntensity(_blurIntensity);
    await themeProvider.setShowAnimations(_showAnimations);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } else {
      debugPrint('SnackBar not shown (no ScaffoldMessenger): $message');
    }
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, this.size = 10});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }
}
