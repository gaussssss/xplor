part of 'explorer_page.dart';

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
  final List<_VolumeInfo> volumes;
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
                      // Favoris (3 premiers)
                      ...favoriteItems
                          .take(3)
                          .map(
                            (item) => _RailButton(
                              icon: item.icon,
                              tooltip: item.label,
                              onTap: () => onNavigate(item.path),
                            ),
                          ),
                      const SizedBox(height: 6),
                      // Divider subtil
                      Container(
                        width: 32,
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 6),
                      // Emplacements système
                      ...systemItems
                          .map(
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
                        ...volumes.take(2).map(
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
                              onTap: () => _showAllDisksDialog(
                                context,
                                volumes,
                                onNavigate,
                              ),
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
                                      const AppearanceSettingsDialogV2(),
                                );
                                await onSettingsClosed?.call();
                              },
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (onToggleCollapse != null)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
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
                                          color: Colors.white
                                              .withValues(alpha: 0.1),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Icon(
                                        lucide.LucideIcons.chevronsRight,
                                        size: 18,
                                        color: Colors.white
                                            .withValues(alpha: 0.7),
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
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            const SizedBox(height: 8),

            // Favoris
            SidebarSection(
              title: 'Favoris',
              items: favoriteItems
                  .map(
                    (item) => SidebarItem(
                      label: item.label,
                      icon: item.icon,
                      onTap: () => onNavigate(item.path),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 4),

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
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: Theme.of(context).brightness == Brightness.light ? 0.7 : 0.4),
                            ),
                      ),
                    ),
                    ...volumes.take(2).map(
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
                          onPressed: () => _showAllDisksDialog(
                            context,
                            volumes,
                            onNavigate,
                          ),
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: Theme.of(context).brightness == Brightness.light ? 0.7 : 0.4),
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
                onSettingsChanged: () {
                  onSettingsClosed?.call();
                },
              ),
            ),

            const SizedBox(height: 12),

            // Section Aide
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AIDE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: Theme.of(context).brightness == Brightness.light ? 0.7 : 0.4),
                        ),
                  ),
                  const SizedBox(height: 8),
                  _HelpMenuItem(
                    icon: lucide.LucideIcons.info,
                    label: 'À propos',
                    isLight: isLight,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  _HelpMenuItem(
                    icon: lucide.LucideIcons.fileText,
                    label: 'CGU',
                    isLight: isLight,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsOfServicePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Boutons d'action en bas (Réglages + Replier)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Bouton Réglages
                  _BottomActionButton(
                    icon: lucide.LucideIcons.settings,
                    label: 'Réglages',
                    isLight: isLight,
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => const AppearanceSettingsDialogV2(),
                      );
                      await onSettingsClosed?.call();
                    },
                  ),

                  // Bouton Replier
                  if (onToggleCollapse != null)
                    _BottomActionButton(
                      icon: lucide.LucideIcons.chevronsLeft,
                      label: 'Replier',
                      isLight: isLight,
                      onTap: onToggleCollapse!,
                    ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// Widget pour les boutons d'action en bas du menu (icône + label)
class _BottomActionButton extends StatelessWidget {
  const _BottomActionButton({
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
    final iconColor = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: isLight ? 0.6 : 0.65);
    final labelColor = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: isLight ? 0.55 : 0.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
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

// Widget pour les items de menu d'aide
class _HelpMenuItem extends StatelessWidget {
  const _HelpMenuItem({
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: (isLight ? Colors.black : Colors.white).withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                lucide.LucideIcons.chevronRight,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
            color: active ? onSurface.withValues(alpha: 0.8) : onSurface.withValues(alpha: 0.2),
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
                      alpha: Theme.of(context).brightness == Brightness.light ? 0.08 : 0.04,
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
                          ? Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.9)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.65),
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

  final _VolumeInfo volume;
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
                        backgroundColor:
                            colorScheme.onSurface.withValues(alpha: 0.12),
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
                      color: colorScheme.onSurface.withValues(alpha: isLight ? 0.7 : 0.75),
                      fontSize: 10,
                    ),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: isLight ? 0.9 : 0.85),
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
        border: Border.all(
          color: onSurface.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmit,
        style: TextStyle(fontSize: 14, color: textColor),
        decoration: InputDecoration(
          hintText: 'Chemin du dossier',
          hintStyle: TextStyle(color: hintColor, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

class _VolumeInfo {
  const _VolumeInfo({
    required this.label,
    required this.path,
    required this.usage,
    required this.totalBytes,
  });

  final String label;
  final String path;
  final double usage;
  final int totalBytes;
}



/// Affiche une dialog avec tous les disques
void _showAllDisksDialog(
  BuildContext context,
  List<_VolumeInfo> volumes,
  void Function(String) onNavigate,
) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      alignment: Alignment.center,
      insetPadding: EdgeInsets.symmetric(
        horizontal: Platform.isMacOS ? 80 : 40,
        vertical: 40,
      ),
      child: _AllDisksDialogContent(
        volumes: volumes,
        onNavigate: onNavigate,
      ),
    ),
  );
}

class _AllDisksDialogContent extends StatelessWidget {
  const _AllDisksDialogContent({
    required this.volumes,
    required this.onNavigate,
  });

  final List<_VolumeInfo> volumes;
  final void Function(String) onNavigate;
  static final Map<String, Future<bool>> _assetPresenceCache = {};

  Widget _buildVolumeIcon(_VolumeInfo volume, Color primary, Color onSurface) {
    final logo = _cloudLogoFor(volume);
    final bg = logo != null
        ? onSurface.withValues(alpha: 0.06)
        : primary.withValues(alpha: 0.1);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: logo != null
          ? FutureBuilder<bool>(
              future: _assetAvailable(logo),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Icon(
                    lucide.LucideIcons.hardDrive,
                    color: primary,
                    size: 18,
                  );
                }
                if (snapshot.data == true) {
                  return Image.asset(
                    logo,
                    width: 20,
                    height: 20,
                  );
                }
                return Icon(
                  lucide.LucideIcons.hardDrive,
                  color: primary,
                  size: 18,
                );
              },
            )
          : Icon(
              lucide.LucideIcons.hardDrive,
              color: primary,
              size: 18,
            ),
    );
  }

  String? _cloudLogoFor(_VolumeInfo volume) {
    final label = volume.label.toLowerCase();
    final path = volume.path.toLowerCase();

    bool match(List<String> needles) {
      for (final needle in needles) {
        final n = needle.toLowerCase();
        if (label.contains(n) || path.contains(n)) return true;
      }
      return false;
    }

    if (match([
      'icloud',
      'clouddocs',
      'mobile documents',
      'cloudstorage/icloud',
    ])) {
      debugPrint('[Disks] Matched iCloud logo for "${volume.label}" (${volume.path})');
      return AppAssets.iCloud_logo;
    }

    if (match([
      'google drive',
      'googledrive',
      'cloudstorage/googledrive',
      'drivefs',
    ])) {
      debugPrint('[Disks] Matched Google Drive logo for "${volume.label}" (${volume.path})');
      return AppAssets.google_Drive_logo;
    }

    if (match([
      'onedrive',
      'cloudstorage/onedrive',
    ])) {
      debugPrint('[Disks] Matched OneDrive logo for "${volume.label}" (${volume.path})');
      return AppAssets.oneDrive_logo;
    }

    debugPrint('[Disks] No cloud logo match for "${volume.label}" (${volume.path})');
    return null;
  }

  Future<bool> _assetAvailable(String asset) {
    debugPrint('[Disks] Checking asset presence: $asset');
    return _assetPresenceCache.putIfAbsent(asset, () async {
      try {
        await rootBundle.load(asset);
        debugPrint('[Disks] Asset present: $asset');
        return true;
      } catch (e) {
        debugPrint('[Disks] Asset NOT found: $asset -> $e');
        return false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final onSurface = theme.colorScheme.onSurface;
    final bgColor =
        isLight ? Colors.white.withOpacity(0.74) : Colors.black.withOpacity(0.8);
    final borderColor =
        isLight ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.1);
    final headerText = onSurface.withValues(alpha: isLight ? 0.88 : 0.94);
    final subtitleText = onSurface.withValues(alpha: isLight ? 0.58 : 0.68);
    final tileBg =
        isLight ? onSurface.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.05);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 520),
          decoration: BoxDecoration(
            color: bgColor,
            gradient: LinearGradient(
              colors: [
                bgColor,
                bgColor.withOpacity(isLight ? 0.68 : 0.72),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      lucide.LucideIcons.hardDrive,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Tous les disques',
                      style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: headerText,
                            fontSize: 18,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(lucide.LucideIcons.x),
                      onPressed: () => Navigator.of(context).pop(),
                      color: onSurface.withValues(alpha: 0.45),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3.3,
                  ),
                  itemCount: volumes.length,
                  itemBuilder: (context, index) {
                    final volume = volumes[index];
                    final percent = (volume.usage * 100).clamp(0, 100).round();
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          onNavigate(volume.path);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: tileBg,
                          ),
                          child: Row(
                            children: [
                              _buildVolumeIcon(
                                volume,
                                theme.colorScheme.primary,
                                onSurface,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      volume.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                            color: headerText,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      volume.path,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                            color: subtitleText,
                                            fontSize: 10.5,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: volume.usage.clamp(0, 1),
                                        minHeight: 3,
                                        backgroundColor:
                                            onSurface.withValues(alpha: 0.08),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$percent%',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                          color: headerText,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _formatBytes(volume.totalBytes),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                          color: subtitleText,
                                          fontSize: 10.5,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget de dialogue pour gérer les doublons avec options avancées
