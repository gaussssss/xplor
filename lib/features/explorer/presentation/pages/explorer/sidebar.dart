part of '../explorer_page.dart';

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.favoriteItems,
    required this.systemItems,
    required this.onNavigate,
    required this.quickItems,
    required this.tags,
    required this.volumes,
    this.recentPaths = const [],
    this.selectedTags = const <String>{},
    this.selectedTypes = const <String>{},
    this.onTagToggle,
    this.onTypeToggle,
    this.onToggleCollapse,
    this.onSettingsClosed,
    required this.isLight,
    required this.currentPalette,
    required this.onToggleLight,
    required this.onPaletteSelected,
    this.collapsed = false,
  });

  final List<_NavItem> favoriteItems;
  final List<_NavItem> systemItems;
  final List<_NavItem> quickItems;
  final List<_TagItem> tags;
  final List<VolumeInfo> volumes;
  final List<String> recentPaths;
  final Set<String> selectedTags;
  final Set<String> selectedTypes;
  final void Function(String path) onNavigate;
  final void Function(String tag)? onTagToggle;
  final void Function(String type)? onTypeToggle;
  final VoidCallback? onToggleCollapse;
  final Future<void> Function()? onSettingsClosed;
  final bool collapsed;
  final bool isLight;
  final ColorPalette currentPalette;
  final Future<void> Function(bool) onToggleLight;
  final Future<void> Function(ColorPalette) onPaletteSelected;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final themeMode = themeProvider.themeModePreference;
    if (collapsed) {
      return SizedBox(
        height: double.infinity,
        child: GlassPanelV2(
          level: GlassPanelLevel.tertiary,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Pas de header avec doublon du toggle - juste les icônes
                      const SizedBox(height: 8),
                      // Emplacements système
                      ...systemItems.map(
                        (item) => _RailButton(
                          icon: item.icon,
                          tooltip: item.label,
                          onTap: () => onNavigate(item.path),
                        ),
                      ),
                      if (volumes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        // Divider subtil
                        Container(
                          width: 32,
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        const SizedBox(height: 6),
                        ...volumes
                            .take(2)
                            .map(
                              (volume) => _RailButton(
                                icon: lucide.LucideIcons.hardDrive,
                                tooltip: volume.label,
                                onTap: () => onNavigate(volume.path),
                              ),
                            ),
                        if (volumes.length > 2)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _RailButton(
                              icon: lucide.LucideIcons.chevronRight,
                              tooltip: 'Tous les disques',
                              onTap: () =>
                                  onNavigate(SpecialLocations.disks),
                            ),
                          ),
                      ],
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: tags
                              .map(
                                (tag) => _TagDot(
                                  color: tag.color,
                                  active: selectedTags.contains(tag.label),
                                  onTap: onTagToggle == null
                                      ? null
                                      : () => onTagToggle!(tag.label),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Zone de contrôles en bas (rail)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _RailButton(
                              icon: lucide.LucideIcons.settings,
                              tooltip: 'Réglages',
                              onTap: () async {
                                await showDialog(
                                  context: context,
                                  builder: (context) =>
                                      const settings.AppearanceSettingsDialogV2(),
                                );
                                await onSettingsClosed?.call();
                              },
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (onToggleCollapse != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Tooltip(
                                message: 'Étendre le menu',
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  child: InkWell(
                                    onTap: onToggleCollapse,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 48,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(
                                                alpha: isLight ? 0.12 : 0.18,
                                              ),
                                          width: 0.5,
                                        ),
                                        color: isLight
                                            ? Colors.black.withValues(
                                                alpha: 0.04,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.06,
                                              ),
                                      ),
                                      child: Icon(
                                        lucide.LucideIcons.chevronsRight,
                                        size: 18,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(
                                              alpha: isLight ? 0.7 : 0.75,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          ThemeRailControlsV2(
                            isLight: isLight,
                            currentPalette: currentPalette,
                            onToggleLight: onToggleLight,
                            onPaletteSelected: onPaletteSelected,
                            showPalette: false,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return GlassPanelV2(
      level: GlassPanelLevel.tertiary,
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // Emplacements (incluant Fichiers récents)
                  SidebarSection(
                    title: 'Emplacements',
                    items: [
                      // Fichiers récents en premier si disponibles
                      if (recentPaths.isNotEmpty)
                        SidebarItem(
                          label: 'Fichiers récents',
                          icon: lucide.LucideIcons.clock,
                          onTap: () => onNavigate(SpecialLocations.recentFiles),
                        ),
                      // Puis les emplacements système
                      ...systemItems.map(
                        (item) => SidebarItem(
                          label: item.label,
                          icon: item.icon,
                          onTap: () => onNavigate(item.path),
                        ),
                      ),
                    ],
                  ),

                  // Disques (maximum 2 affichés)
                  if (volumes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 4),
                            child: Text(
                              'DISQUES',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(
                                          alpha:
                                              Theme.of(context).brightness ==
                                                  Brightness.light
                                              ? 0.7
                                              : 0.4,
                                        ),
                                  ),
                            ),
                          ),
                          ...volumes
                              .take(2)
                              .map(
                                (volume) => _VolumeItem(
                                  volume: volume,
                                  onTap: () => onNavigate(volume.path),
                                ),
                              ),
                          if (volumes.length > 2)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: const Size(0, 32),
                                ),
                                onPressed: () =>
                                    onNavigate(SpecialLocations.disks),
                                icon: const Icon(
                                  lucide.LucideIcons.chevronRight,
                                  size: 14,
                                ),
                                label: Text(
                                  'Voir tous (${volumes.length})',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  // Tags simplifiés
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TAGS',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(
                                        alpha:
                                            Theme.of(context).brightness ==
                                                Brightness.light
                                            ? 0.7
                                            : 0.4,
                                      ),
                                ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: tags
                                .map(
                                  (tag) => _TagChipSimple(
                                    tag: tag,
                                    isActive: selectedTags.contains(tag.label),
                                    onTap: onTagToggle == null
                                        ? null
                                        : () => onTagToggle!(tag.label),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Contrôles de thème
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: ThemeControlsV2(
                      isLight: isLight,
                      currentPalette: currentPalette,
                      onToggleLight: onToggleLight,
                      onPaletteSelected: onPaletteSelected,
                      showPalette: false,
                      showLightDarkToggle: false,
                      showSettings: false,
                      onSettingsChanged: () {
                        onSettingsClosed?.call();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: _ThemeModeSelector(
                      isLight: isLight,
                      mode: themeMode,
                      onModeSelected: themeProvider.setThemeMode,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _SidebarFooter(
            isLight: isLight,
            onToggleCollapse: onToggleCollapse,
            onSettingsClosed: onSettingsClosed,
          ),
        ],
      ),
    );
  }
}

class _FooterSectionLabel extends StatelessWidget {
  const _FooterSectionLabel({required this.label, required this.isLight});

  final String label;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: theme.colorScheme.onSurface.withValues(
          alpha: isLight ? 0.45 : 0.6,
        ),
      ),
    );
  }
}

class _FooterLinkButton extends StatelessWidget {
  const _FooterLinkButton({
    required this.icon,
    required this.label,
    required this.isLight,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isLight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurface.withValues(
      alpha: isLight ? 0.55 : 0.6,
    );
    final textColor = theme.colorScheme.onSurface.withValues(
      alpha: isLight ? 0.65 : 0.7,
    );
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: textColor,
      ),
      icon: Icon(icon, size: 14, color: iconColor),
      label: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _FooterLinkSeparator extends StatelessWidget {
  const _FooterLinkSeparator();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final color = Theme.of(context).colorScheme.onSurface.withValues(
          alpha: isLight ? 0.28 : 0.35,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(lucide.LucideIcons.dot, size: 10, color: color),
    );
  }
}

class _FooterList extends StatelessWidget {
  const _FooterList({required this.isLight, required this.children});

  final bool isLight;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.onSurface.withValues(
          alpha: isLight ? 0.08 : 0.12,
        );
    return Container(
      decoration: BoxDecoration(
        color: isLight
            ? Colors.black.withValues(alpha: 0.02)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 0.6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 0.6, color: borderColor),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _FooterListItem extends StatelessWidget {
  const _FooterListItem({
    required this.icon,
    required this.label,
    required this.isLight,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isLight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurface.withValues(
      alpha: isLight ? 0.6 : 0.7,
    );
    final textColor = theme.colorScheme.onSurface.withValues(
      alpha: isLight ? 0.7 : 0.75,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Icon(
                lucide.LucideIcons.chevronRight,
                size: 12,
                color: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterMiniButton extends StatelessWidget {
  const _FooterMiniButton({
    required this.icon,
    required this.label,
    required this.isLight,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isLight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface.withValues(
      alpha: isLight ? 0.7 : 0.65,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isLight
                ? Colors.black.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(
                alpha: isLight ? 0.1 : 0.12,
              ),
              width: 0.6,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({
    required this.isLight,
    required this.mode,
    required this.onModeSelected,
  });

  final bool isLight;
  final settings.ThemeMode mode;
  final Future<void> Function(settings.ThemeMode) onModeSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isLight
        ? Colors.black.withValues(alpha: 0.03)
        : Colors.white.withValues(alpha: 0.04);
    final borderColor = colorScheme.onSurface.withValues(
      alpha: isLight ? 0.06 : 0.08,
    );
    final activeColor = colorScheme.onSurface.withValues(
      alpha: isLight ? 0.85 : 0.9,
    );
    final inactiveColor = colorScheme.onSurface.withValues(
      alpha: isLight ? 0.4 : 0.45,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'APPARENCE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            fontSize: 10,
            color: colorScheme.onSurface.withValues(alpha: isLight ? 0.7 : 0.4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 34,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          padding: const EdgeInsets.all(2.5),
          child: Row(
            children: [
              Expanded(
                child: _ThemeModeOption(
                  label: 'Clair',
                  icon: lucide.LucideIcons.sun,
                  isActive: mode == settings.ThemeMode.light,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () => onModeSelected(settings.ThemeMode.light),
                ),
              ),
              const SizedBox(width: 2.5),
              Expanded(
                child: _ThemeModeOption(
                  label: 'Sombre',
                  icon: lucide.LucideIcons.moon,
                  isActive: mode == settings.ThemeMode.dark,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () => onModeSelected(settings.ThemeMode.dark),
                ),
              ),
              const SizedBox(width: 2.5),
              Expanded(
                child: _ThemeModeOption(
                  label: 'Auto',
                  icon: lucide.LucideIcons.monitorSmartphone,
                  isActive: mode == settings.ThemeMode.adaptive,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  onTap: () => onModeSelected(settings.ThemeMode.adaptive),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isActive ? activeColor : inactiveColor,
                ),
                const SizedBox(width: 2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    letterSpacing: 0.2,
                    color: isActive ? activeColor : inactiveColor,
                    fontWeight: FontWeight.w600,
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

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({
    required this.isLight,
    required this.onToggleCollapse,
    required this.onSettingsClosed,
  });

  final bool isLight;
  final VoidCallback? onToggleCollapse;
  final Future<void> Function()? onSettingsClosed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final borderColor = onSurface.withValues(alpha: isLight ? 0.08 : 0.14);
    final bgColor = isLight
        ? Colors.black.withValues(alpha: 0.03)
        : Colors.white.withValues(alpha: 0.04);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.6)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [_FooterSectionLabel(label: 'Système', isLight: isLight)],
          ),
          const SizedBox(height: 6),
          _FooterList(
            isLight: isLight,
            children: [
              _FooterListItem(
                icon: lucide.LucideIcons.settings,
                label: 'Réglages',
                isLight: isLight,
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (context) =>
                        const settings.AppearanceSettingsDialogV2(),
                  );
                  await onSettingsClosed?.call();
                },
              ),
              if (onToggleCollapse != null)
                _FooterListItem(
                  icon: lucide.LucideIcons.chevronsLeft,
                  label: 'Replier',
                  isLight: isLight,
                  onTap: onToggleCollapse!,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _FooterSectionLabel(label: 'Support', isLight: isLight),
              const Spacer(),
              const _BuildChip(),
            ],
          ),
          const SizedBox(height: 6),
          _FooterList(
            isLight: isLight,
            children: [
              _FooterListItem(
                icon: lucide.LucideIcons.helpCircle,
                label: 'Aide',
                isLight: isLight,
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(_noTransitionRoute(const HelpCenterPage()));
                },
              ),
              _FooterListItem(
                icon: lucide.LucideIcons.fileText,
                label: 'Conditions d\'utilisation',
                isLight: isLight,
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(_noTransitionRoute(const TermsOfServicePage()));
                },
              ),
              _FooterListItem(
                icon: lucide.LucideIcons.info,
                label: 'À propos',
                isLight: isLight,
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(_noTransitionRoute(const AboutPage()));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuildChip extends StatefulWidget {
  const _BuildChip();

  @override
  State<_BuildChip> createState() => _BuildChipState();
}

class _BuildChipState extends State<_BuildChip> {
  String? _label;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      final version = info.version;
      final build = info.buildNumber;
      final normalized = build == version ? version : '$version+$build';
      setState(() {
        _label = normalized;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _label = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final onSurface = theme.colorScheme.onSurface;
    final bg = isLight
        ? Colors.black.withValues(alpha: 0.03)
        : Colors.white.withValues(alpha: 0.05);
    final border = onSurface.withValues(
      alpha: isLight ? 0.08 : 0.1,
    );
    final textColor = onSurface.withValues(
      alpha: isLight ? 0.55 : 0.7,
    );
    final label = _label ?? '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 0.6),
      ),
      child: Text(
        'Version $label',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: textColor,
        ),
      ),
    );
  }
}

PageRouteBuilder<T> _noTransitionRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        child,
  );
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Icon(icon, size: 20),
          ),
        ),
      ),
    );
  }
}

class _TagDot extends StatelessWidget {
  const _TagDot({required this.color, required this.active, this.onTap});

  final Color color;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              color.withOpacity(active ? 0.9 : 0.6),
              color.withOpacity(active ? 0.5 : 0.25),
            ],
          ),
          border: Border.all(
            color: active
                ? onSurface.withValues(alpha: 0.8)
                : onSurface.withValues(alpha: 0.2),
            width: active ? 1.4 : 1,
          ),
        ),
      ),
    );
  }
}

/// Tag chip simplifié et compact
class _TagChipSimple extends StatelessWidget {
  const _TagChipSimple({
    required this.tag,
    required this.isActive,
    required this.onTap,
  });

  final _TagItem tag;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: isActive
                ? tag.color.withValues(alpha: 0.2)
                : Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: Theme.of(context).brightness == Brightness.light
                        ? 0.08
                        : 0.04,
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Petit point de couleur
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: tag.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                tag.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.9)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VolumeItem extends StatelessWidget {
  const _VolumeItem({required this.volume, required this.onTap});

  final VolumeInfo volume;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final percent = (volume.usage * 100).clamp(0, 100).round();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: isLight
                ? Colors.black.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                lucide.LucideIcons.hardDrive,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.75),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      volume.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: volume.usage.clamp(0, 1),
                        minHeight: 3,
                        backgroundColor: colorScheme.onSurface.withValues(
                          alpha: 0.12,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percent%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsFooter extends StatelessWidget {
  const _StatsFooter({required this.state});

  final ExplorerViewState state;

  @override
  Widget build(BuildContext context) {
    final selected = state.entries
        .where((e) => state.selectedPaths.contains(e.path))
        .toList();
    final selectionCount = selected.length;
    final folderCount = state.entries.where((e) => e.isDirectory).length;
    final fileCount = state.entries.where((e) => !e.isDirectory).length;
    final totalSize = selected.fold<int>(0, (sum, e) => sum + (e.size ?? 0));
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatChip(
            label: 'Selectionnés',
            value: '$selectionCount',
            colorScheme: colorScheme,
            isLight: isLight,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Dossiers',
            value: '$folderCount',
            colorScheme: colorScheme,
            isLight: isLight,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Fichiers',
            value: '$fileCount',
            colorScheme: colorScheme,
            isLight: isLight,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Taille',
            value: _formatBytes(totalSize),
            colorScheme: colorScheme,
            isLight: isLight,
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '—';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    final precision = value >= 10 ? 0 : 1;
    return '${value.toStringAsFixed(precision)} ${units[unitIndex]}';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.isLight,
  });

  final String label;
  final String value;
  final ColorScheme colorScheme;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isLight
                ? Colors.white.withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.4,
                  color: colorScheme.onSurface.withValues(
                    alpha: isLight ? 0.7 : 0.75,
                  ),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(
                    alpha: isLight ? 0.9 : 0.85,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PathInput extends StatelessWidget {
  const _PathInput({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final void Function(String value) onSubmit;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final textColor = onSurface.withValues(alpha: isLight ? 0.9 : 0.95);
    final hintColor = onSurface.withValues(alpha: isLight ? 0.5 : 0.6);
    final iconColor = onSurface.withValues(alpha: isLight ? 0.75 : 0.8);
    final bgColor = isLight
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.4);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: onSurface.withValues(alpha: 0.15), width: 1),
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmit,
        style: TextStyle(fontSize: 14, color: textColor),
        decoration: InputDecoration(
          hintText: 'Chemin du dossier',
          hintStyle: TextStyle(color: hintColor, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          prefixIcon: Icon(
            lucide.LucideIcons.folderOpen,
            color: iconColor,
            size: 18,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              lucide.LucideIcons.arrowRight,
              size: 16,
              color: iconColor,
            ),
            onPressed: () => onSubmit(controller.text),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon, required this.path});

  final String label;
  final IconData icon;
  final String path;
}

class _TagItem {
  const _TagItem({required this.label, required this.color});

  final String label;
  final Color color;
}

// Widget de dialogue pour gérer les doublons avec options avancées
