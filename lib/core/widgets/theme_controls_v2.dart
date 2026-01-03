import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/explorer/presentation/widgets/glass_panel_v2.dart';
import '../theme/animation_tokens.dart';
import '../theme/color_palettes.dart';
import 'appearance_settings_dialog_v2.dart';

/// Widget de contrôle du thème (light/dark + palette) - Version 2
/// Design élégant avec toggle moon/sun et sélecteur de palette amélioré
class ThemeControlsV2 extends StatelessWidget {
  const ThemeControlsV2({
    super.key,
    required this.isLight,
    required this.currentPalette,
    required this.onToggleLight,
    required this.onPaletteSelected,
    this.onSettingsChanged,
  });

  final bool isLight;
  final ColorPalette currentPalette;
  final Future<void> Function(bool) onToggleLight;
  final Future<void> Function(ColorPalette) onPaletteSelected;
  final VoidCallback? onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
          fontSize: 10,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: isLight ? 0.7 : 0.4),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('APPARENCE', style: titleStyle),
            const Spacer(),
            // Bouton pour ouvrir les paramètres avancés
            IconButton(
              icon: Icon(
                LucideIcons.settings2,
                size: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: isLight ? 0.6 : 0.7),
              ),
              tooltip: 'Paramètres d\'apparence',
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => const AppearanceSettingsDialogV2(),
                );
                // Appeler le callback après la fermeture du dialogue
                onSettingsChanged?.call();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Toggle élégant moon/sun
        _LightDarkToggle(
          isLight: isLight,
          onToggle: onToggleLight,
        ),
        const SizedBox(height: 12),
        // Sélecteur de palette amélioré
        _PaletteSelector(
          currentPalette: currentPalette,
          isLight: isLight,
          onPaletteSelected: onPaletteSelected,
        ),
      ],
    );
  }
}

/// Toggle élégant entre mode clair et mode sombre avec icônes moon/sun
class _LightDarkToggle extends StatelessWidget {
  const _LightDarkToggle({
    required this.isLight,
    required this.onToggle,
  });

  final bool isLight;
  final Future<void> Function(bool) onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.primary;
    final inactiveColor =
        colorScheme.onSurface.withValues(alpha: isLight ? 0.25 : 0.3);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isLight
            ? Colors.black.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              colorScheme.onSurface.withValues(alpha: isLight ? 0.08 : 0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Bouton Soleil (mode clair)
          Expanded(
            child: _ToggleOption(
              icon: LucideIcons.sun,
              label: 'Clair',
              isActive: isLight,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              onTap: () => onToggle(true),
            ),
          ),
          // Séparateur vertical
          Container(
            width: 1,
            height: 24,
            color:
                colorScheme.onSurface.withValues(alpha: isLight ? 0.1 : 0.15),
          ),
          // Bouton Lune (mode sombre)
          Expanded(
            child: _ToggleOption(
              icon: LucideIcons.moon,
              label: 'Sombre',
              isActive: !isLight,
              activeColor: activeColor,
              inactiveColor: inactiveColor,
              onTap: () => onToggle(false),
            ),
          ),
        ],
      ),
    );
  }
}

/// Option individuelle du toggle (soleil ou lune)
class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? activeColor : inactiveColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sélecteur de palette amélioré avec preview des couleurs
class _PaletteSelector extends StatelessWidget {
  const _PaletteSelector({
    required this.currentPalette,
    required this.isLight,
    required this.onPaletteSelected,
  });

  final ColorPalette currentPalette;
  final bool isLight;
  final Future<void> Function(ColorPalette) onPaletteSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => _showPaletteDialog(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.black.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                colorScheme.onSurface.withValues(alpha: isLight ? 0.08 : 0.12),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Preview de la palette actuelle (3 dots colorés)
            _PalettePreview(palette: currentPalette),
            const SizedBox(width: 10),
            // Nom de la palette
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Palette',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface
                          .withValues(alpha: isLight ? 0.5 : 0.4),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentPalette.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface
                          .withValues(alpha: isLight ? 0.85 : 0.9),
                    ),
                  ),
                ],
              ),
            ),
            // Icône pour indiquer qu'on peut cliquer
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color:
                  colorScheme.onSurface.withValues(alpha: isLight ? 0.4 : 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPaletteDialog(BuildContext context) async {
    final result = await showDialog<ColorPalette>(
      context: context,
      builder: (ctx) => _PaletteSelectionDialog(
        currentPalette: currentPalette,
        isLight: isLight,
      ),
    );

    if (result != null) {
      await onPaletteSelected(result);
    }
  }
}

/// Preview compact de la palette (3 dots colorés)
class _PalettePreview extends StatelessWidget {
  const _PalettePreview({required this.palette});

  final ColorPalette palette;

  @override
  Widget build(BuildContext context) {
    final colors = ColorPalettes.getData(palette);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ColorDot(color: colors.primary),
        const SizedBox(width: 4),
        _ColorDot(color: colors.navigation),
        const SizedBox(width: 4),
        _ColorDot(color: colors.info),
      ],
    );
  }
}

/// Dot de couleur pour le preview
class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
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

/// Dialog glassmorphism pour sélectionner la palette
class _PaletteSelectionDialog extends StatelessWidget {
  const _PaletteSelectionDialog({
    required this.currentPalette,
    required this.isLight,
  });

  final ColorPalette currentPalette;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GlassPanelV2(
          level: GlassPanelLevel.primary,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      LucideIcons.palette,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Choisir une palette',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: isLight ? 0.9 : 0.95),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Liste des palettes
                ...ColorPalette.values.map(
                  (palette) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PaletteCard(
                      palette: palette,
                      isSelected: palette == currentPalette,
                      isLight: isLight,
                      onTap: () => Navigator.of(context).pop(palette),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Bouton fermer
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Annuler',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: isLight ? 0.6 : 0.7),
                      ),
                    ),
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

/// Card pour une palette dans le dialog
class _PaletteCard extends StatefulWidget {
  const _PaletteCard({
    required this.palette,
    required this.isSelected,
    required this.isLight,
    required this.onTap,
  });

  final ColorPalette palette;
  final bool isSelected;
  final bool isLight;
  final VoidCallback onTap;

  @override
  State<_PaletteCard> createState() => _PaletteCardState();
}

class _PaletteCardState extends State<_PaletteCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = ColorPalettes.getData(widget.palette);
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: AnimationTokens.fast,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : (_isHovered
                      ? (widget.isLight
                          ? Colors.black.withValues(alpha: 0.03)
                          : Colors.white.withValues(alpha: 0.04))
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isSelected
                    ? colorScheme.primary.withValues(alpha: 0.5)
                    : (_isHovered
                        ? colorScheme.onSurface
                            .withValues(alpha: widget.isLight ? 0.15 : 0.2)
                        : colorScheme.onSurface
                            .withValues(alpha: widget.isLight ? 0.08 : 0.12)),
                width: widget.isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // 6 color dots (preview complet)
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    _ColorDot(color: colors.primary),
                    _ColorDot(color: colors.navigation),
                    _ColorDot(color: colors.info),
                    _ColorDot(color: colors.success),
                    _ColorDot(color: colors.warning),
                    _ColorDot(color: colors.error),
                  ],
                ),
                const SizedBox(width: 14),
                // Nom et description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.palette.emoji,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.palette.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: widget.isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: colorScheme.onSurface.withValues(
                                alpha: widget.isLight ? 0.9 : 0.95,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.palette.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(
                            alpha: widget.isLight ? 0.55 : 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Check icon si sélectionné
                if (widget.isSelected)
                  Icon(
                    LucideIcons.check,
                    size: 20,
                    color: colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Version compacte pour la sidebar collapsed (rail)
class ThemeRailControlsV2 extends StatelessWidget {
  const ThemeRailControlsV2({
    super.key,
    required this.isLight,
    required this.currentPalette,
    required this.onToggleLight,
    required this.onPaletteSelected,
  });

  final bool isLight;
  final ColorPalette currentPalette;
  final Future<void> Function(bool) onToggleLight;
  final Future<void> Function(ColorPalette) onPaletteSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RailThemeButton(
          icon: isLight ? LucideIcons.sun : LucideIcons.moon,
          tooltip: isLight ? 'Passer en mode sombre' : 'Passer en mode clair',
          onTap: () => onToggleLight(!isLight),
        ),
        const SizedBox(height: 6),
        _RailThemeButton(
          icon: LucideIcons.palette,
          tooltip: 'Palette: ${currentPalette.displayName}',
          onTap: () => _showPaletteDialog(context),
        ),
      ],
    );
  }

  Future<void> _showPaletteDialog(BuildContext context) async {
    final brightness = Theme.of(context).brightness;
    final result = await showDialog<ColorPalette>(
      context: context,
      builder: (ctx) => _PaletteSelectionDialog(
        currentPalette: currentPalette,
        isLight: brightness == Brightness.light,
      ),
    );

    if (result != null) {
      await onPaletteSelected(result);
    }
  }
}

/// Bouton pour le rail (sidebar collapsed)
class _RailThemeButton extends StatefulWidget {
  const _RailThemeButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_RailThemeButton> createState() => _RailThemeButtonState();
}

class _RailThemeButtonState extends State<_RailThemeButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: AnimationTokens.fast,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isHovered
                    ? colorScheme.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: _isHovered
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
