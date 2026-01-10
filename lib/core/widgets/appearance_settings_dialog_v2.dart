import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/theme_provider.dart';
import '../theme/color_palettes.dart';

/// Mode de thème (clair, sombre, adaptatif)
enum ThemeMode { light, dark, adaptive }

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
  String? _selectedThemeId;
  late bool _useGlassmorphism;
  late double _blurIntensity;
  late bool _showAnimations;
  late BackgroundRefreshPeriod _backgroundRefreshPeriod;
  bool _isMultiSelectionMode = false;
  final PageController _previewController = PageController(
    viewportFraction: 0.85,
  );
  Timer? _previewTimer;
  int _previewIndex = 0;
  String? _previewThemeId;
  int _previewLength = 0;

  @override
  void initState() {
    super.initState();
    final themeProvider = context.read<ThemeProvider>();

    _themeMode = themeProvider.themeModePreference;
    _selectedThemeId = themeProvider.backgroundThemeId;
    _useGlassmorphism = themeProvider.useGlassmorphism;
    _blurIntensity = themeProvider.blurIntensity;
    _showAnimations = themeProvider.showAnimations;
    _backgroundRefreshPeriod = themeProvider.backgroundRefreshPeriod;

    // Charger le mode de sélection depuis SharedPreferences
    _loadSelectionMode();
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _previewController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectionMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isMultiSelectionMode = prefs.getBool('multi_selection_mode') ?? false;
      });
    } catch (_) {
      _isMultiSelectionMode = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;
    final textColor = isLight ? Colors.black87 : Colors.white;
    final subtleTextColor = isLight
        ? Colors.black.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.7);

    return Dialog(
      backgroundColor: Colors.transparent,
      alignment: Alignment.center,
      insetPadding: EdgeInsets.symmetric(
        horizontal: Platform.isMacOS ? 80 : 40,
        vertical: 40,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
            decoration: BoxDecoration(
              color: isLight
                  ? Colors.white.withValues(alpha: 0.72)
                  : Colors.black.withValues(alpha: 0.75),
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
                            ? _buildSingleColumn(
                                isLight,
                                textColor,
                                subtleTextColor,
                              )
                            : _buildTwoColumns(
                                isLight,
                                textColor,
                                subtleTextColor,
                              ),
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
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0),
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
        // Colonne gauche - Apparence générale
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThemeModeSection(isLight, textColor, subtleTextColor),
              const SizedBox(height: 24),
              _buildAdvancedSection(isLight, textColor, subtleTextColor),
            ],
          ),
        ),
        const SizedBox(width: 32),
        // Colonne droite - Personnalisation visuelle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPaletteSection(isLight, textColor),
              const SizedBox(height: 24),
              _buildBackgroundSection(isLight, textColor, subtleTextColor),
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
        _buildSectionTitle(
          'Palette de couleurs',
          LucideIcons.palette,
          textColor,
        ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15)
                      : (isLight
                            ? Colors.white.withValues(
                                alpha: 0.7,
                              ) // Fond blanc semi-opaque en mode clair
                            : Colors.white.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : (isLight
                              ? Colors.black.withValues(
                                  alpha: 0.15,
                                ) // Border plus visible en mode clair
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
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
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
    final themeProvider = context.watch<ThemeProvider>();
    final themes = themeProvider.backgroundThemes;
    final hasThemes = themes.isNotEmpty;
    final selectedTheme = themes.firstWhere(
      (theme) => theme.id == _selectedThemeId,
      orElse: () => themes.isNotEmpty
          ? themes.first
          : const BackgroundTheme(
              id: '',
              name: '',
              description: '',
              images: [],
            ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Arrière-plan', LucideIcons.image, textColor),
        const SizedBox(height: 12),
        _buildThemePicker(
          themes: themes,
          selectedTheme: _selectedThemeId,
          isLight: isLight,
          textColor: textColor,
          subtleTextColor: subtleTextColor,
        ),
        if (hasThemes && _selectedThemeId != null) ...[
          const SizedBox(height: 12),
          _buildThemePreview(
            theme: selectedTheme,
            isLight: isLight,
            textColor: textColor,
            subtleTextColor: subtleTextColor,
          ),
          const SizedBox(height: 12),
          _buildRefreshPeriodPicker(isLight, textColor, subtleTextColor),
        ],
      ],
    );
  }

  Widget _buildThemePicker({
    required List<BackgroundTheme> themes,
    required String? selectedTheme,
    required bool isLight,
    required Color textColor,
    required Color subtleTextColor,
  }) {
    final selection = themes.firstWhere(
      (theme) => theme.id == selectedTheme,
      orElse: () => const BackgroundTheme(
        id: '',
        name: 'Aucun',
        description: 'Fond uni sans image',
        images: [],
      ),
    );
    return InkWell(
      onTap: () => _openThemePickerDialog(
        themes: themes,
        isLight: isLight,
        textColor: textColor,
        subtleTextColor: subtleTextColor,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.white.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLight
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.image,
              size: 18,
              color: textColor.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selection.name.isEmpty ? 'Aucun' : selection.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    selection.name.isEmpty
                        ? 'Fond uni sans image'
                        : selection.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: subtleTextColor),
                  ),
                ],
              ),
            ),
            Text(
              selectedTheme == null ? 'Aucun' : 'Thème',
              style: TextStyle(fontSize: 11, color: subtleTextColor),
            ),
            const SizedBox(width: 6),
            Icon(
              LucideIcons.chevronDown,
              size: 16,
              color: textColor.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openThemePickerDialog({
    required List<BackgroundTheme> themes,
    required bool isLight,
    required Color textColor,
    required Color subtleTextColor,
  }) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return _ThemePickerDialog(
          themes: themes,
          selectedTheme: _selectedThemeId,
          isLight: isLight,
          textColor: textColor,
          subtleTextColor: subtleTextColor,
        );
      },
    );

    if (selected == null) return;
    setState(() => _selectedThemeId = selected.isEmpty ? null : selected);
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
        Text(
          'Les réglages visuels avancés sont désactivés pour le moment.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: subtleTextColor,
              ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle(
          'Comportement',
          LucideIcons.mousePointer2,
          textColor,
        ),
        const SizedBox(height: 12),
        _buildToggleOption(
          'Mode sélection multiple',
          'Activer les checkboxes et la sélection multiple',
          _isMultiSelectionMode,
          (value) => setState(() => _isMultiSelectionMode = value),
          isLight,
          textColor,
          subtleTextColor,
        ),
      ],
    );
  }

  Widget _buildRefreshPeriodPicker(
    bool isLight,
    Color textColor,
    Color subtleTextColor,
  ) {
    final options = <BackgroundRefreshPeriod, String>{
      BackgroundRefreshPeriod.none: 'Ne pas changer automatiquement',
      BackgroundRefreshPeriod.tenMinutes: 'Toutes les 10 minutes',
      BackgroundRefreshPeriod.oneHour: 'Chaque heure',
      BackgroundRefreshPeriod.oneDay: 'Chaque jour',
      BackgroundRefreshPeriod.oneWeek: 'Chaque semaine',
      BackgroundRefreshPeriod.oneMonth: 'Chaque mois',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rotation automatique',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<BackgroundRefreshPeriod>(
          value: _backgroundRefreshPeriod,
          onChanged: (value) {
            if (value == null) return;
            setState(() => _backgroundRefreshPeriod = value);
          },
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          items: options.entries
              .map(
                (e) => DropdownMenuItem<BackgroundRefreshPeriod>(
                  value: e.key,
                  child: Text(
                    e.value,
                    style: TextStyle(color: subtleTextColor, fontSize: 13),
                  ),
                ),
              )
              .toList(),
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
                    ? Colors.white.withValues(
                        alpha: 0.8,
                      ) // Fond blanc semi-opaque en mode clair
                    : Colors.white.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                : (isLight
                      ? Colors.black.withValues(
                          alpha: 0.15,
                        ) // Border plus visible en mode clair
                      : Colors.white.withValues(alpha: 0.12)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : textColor.withValues(alpha: 0.7),
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
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: subtleTextColor),
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

  Widget _buildThemeOption({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isLight,
    required Color textColor,
    required Color subtleTextColor,
    String? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
              : (isLight
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                : (isLight
                      ? Colors.black.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.12)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : textColor.withValues(alpha: 0.7),
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
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 11, color: subtleTextColor),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Text(
                trailing,
                style: TextStyle(fontSize: 11, color: subtleTextColor),
              ),
            ],
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  LucideIcons.check,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePreview({
    required BackgroundTheme theme,
    required bool isLight,
    required Color textColor,
    required Color subtleTextColor,
  }) {
    final previewImages = theme.images.take(3).toList();
    if (previewImages.isEmpty) {
      return Text(
        'Aucune image de prévisualisation disponible.',
        style: TextStyle(fontSize: 12, color: subtleTextColor),
      );
    }

    if (_previewThemeId != theme.id) {
      _previewThemeId = theme.id;
      _previewIndex = 0;
      if (_previewController.hasClients) {
        _previewController.jumpToPage(0);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_previewController.hasClients) {
            _previewController.jumpToPage(0);
          }
        });
      }
    }
    _ensurePreviewTimer(previewImages.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aperçu du thème',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 86,
          child: PageView.builder(
            itemCount: previewImages.length,
            controller: _previewController,
            onPageChanged: (index) => setState(() => _previewIndex = index),
            itemBuilder: (context, index) {
              final image = previewImages[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(image.path, fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.15),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.35),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        bottom: 8,
                        child: Text(
                          theme.name,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(previewImages.length, (index) {
            final isActive = index == _previewIndex;
            return InkWell(
              onTap: () => _previewController.animateToPage(
                index,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: isActive ? 16 : 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  void _ensurePreviewTimer(int length) {
    if (_previewLength == length && _previewTimer != null) return;
    _previewTimer?.cancel();
    _previewLength = length;
    if (length <= 1) return;
    _previewTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_previewController.hasClients) return;
      final next = (_previewIndex + 1) % length;
      _previewController.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
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
                  style: TextStyle(fontSize: 12, color: subtleTextColor),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.15),
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
              inactiveTrackColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
              thumbColor: Theme.of(context).colorScheme.primary,
              overlayColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
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
              style: TextStyle(color: isLight ? Colors.black87 : Colors.white),
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

  Future<void> _applySettings() async {
    final themeProvider = context.read<ThemeProvider>();

    await themeProvider.setThemeMode(_themeMode);
    await themeProvider.setBackgroundTheme(_selectedThemeId);
    await themeProvider.setBackgroundRefreshPeriod(_backgroundRefreshPeriod);
    if (_selectedThemeId == null) {
      await themeProvider.clearBackgroundImage();
    }

    await themeProvider.setUseGlassmorphism(_useGlassmorphism);
    await themeProvider.setBlurIntensity(_blurIntensity);
    await themeProvider.setShowAnimations(_showAnimations);

    // Sauvegarder le mode de sélection
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('multi_selection_mode', _isMultiSelectionMode);
    } catch (_) {
      // Ignorer les erreurs de sauvegarde
    }

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

class _ThemePickerDialog extends StatefulWidget {
  const _ThemePickerDialog({
    required this.themes,
    required this.selectedTheme,
    required this.isLight,
    required this.textColor,
    required this.subtleTextColor,
  });

  final List<BackgroundTheme> themes;
  final String? selectedTheme;
  final bool isLight;
  final Color textColor;
  final Color subtleTextColor;

  @override
  State<_ThemePickerDialog> createState() => _ThemePickerDialogState();
}

class _ThemePickerDialogState extends State<_ThemePickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = widget.themes.where((item) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return item.name.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q);
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: 420,
            constraints: const BoxConstraints(maxHeight: 520),
            decoration: BoxDecoration(
              color: widget.isLight
                  ? Colors.white.withValues(alpha: 0.96)
                  : Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isLight
                    ? Colors.black.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choisir un thème',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: widget.textColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        onChanged: (value) =>
                            setState(() => _query = value.trim()),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Rechercher un thème',
                          prefixIcon: const Icon(LucideIcons.search, size: 16),
                          filled: true,
                          fillColor: widget.isLight
                              ? Colors.black.withValues(alpha: 0.04)
                              : Colors.white.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: widget.isLight
                                  ? Colors.black.withValues(alpha: 0.1)
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    children: [
                      _ThemePickerTile(
                        title: 'Aucun',
                        description: 'Fond uni sans image',
                        isSelected: widget.selectedTheme == null,
                        onTap: () => Navigator.of(context).pop(''),
                        textColor: widget.textColor,
                        subtleTextColor: widget.subtleTextColor,
                      ),
                      const SizedBox(height: 6),
                      ...filtered.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ThemePickerTile(
                            title: item.name,
                            description: item.description,
                            trailing: '${item.images.length} images',
                            isSelected: widget.selectedTheme == item.id,
                            onTap: () => Navigator.of(context).pop(item.id),
                            textColor: widget.textColor,
                            subtleTextColor: widget.subtleTextColor,
                          ),
                        ),
                      ),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Aucun thème ne correspond à votre recherche.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.subtleTextColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Fermer',
                          style: TextStyle(color: widget.textColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemePickerTile extends StatelessWidget {
  const _ThemePickerTile({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    required this.textColor,
    required this.subtleTextColor,
    this.trailing,
  });

  final String title;
  final String description;
  final String? trailing;
  final bool isSelected;
  final VoidCallback onTap;
  final Color textColor;
  final Color subtleTextColor;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.image,
              size: 16,
              color: isSelected ? accent : textColor.withValues(alpha: 0.7),
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
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: subtleTextColor),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: TextStyle(fontSize: 11, color: subtleTextColor),
              ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(LucideIcons.check, size: 16, color: accent),
              ),
          ],
        ),
      ),
    );
  }
}
