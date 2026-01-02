import 'dart:io';
import 'dart:ui';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/special_locations.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/color_palettes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../explorer/data/datasources/local_file_system_data_source.dart';
import '../../../explorer/data/repositories/file_system_repository_impl.dart';
import '../../../explorer/domain/entities/file_entry.dart';
import '../../../explorer/domain/usecases/create_directory.dart';
import '../../../explorer/domain/usecases/delete_entries.dart';
import '../../../explorer/domain/usecases/duplicate_entries.dart';
import '../../../explorer/domain/usecases/list_directory_entries.dart';
import '../../../explorer/domain/usecases/move_entries.dart';
import '../../../explorer/domain/usecases/rename_entry.dart';
import '../../../explorer/domain/usecases/copy_entries.dart';
import '../viewmodels/explorer_view_model.dart';
import '../widgets/breadcrumb_bar.dart';
import '../widgets/file_entry_tile.dart';
import '../widgets/glass_panel_v2.dart';
import '../widgets/list_view_table.dart';
import '../widgets/sidebar_section.dart';
import '../widgets/toolbar_button.dart';
import '../../../../core/widgets/theme_controls_v2.dart';

class ExplorerPage extends StatefulWidget {
  const ExplorerPage({super.key});

  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

class _ExplorerPageState extends State<ExplorerPage> {
  late final ExplorerViewModel _viewModel;
  late final TextEditingController _pathController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final List<_NavItem> _favoriteItems;
  late final List<_NavItem> _systemItems;
  late final List<_NavItem> _quickItems;
  late final List<_TagItem> _tagItems;
  late final List<_VolumeInfo> _volumes;
  String? _lastStatusMessage;
  bool _contextMenuOpen = false;
  bool _isSearchExpanded = false;
  bool _isToastShowing = false;
  bool _isSidebarCollapsed = false;
  double _sidebarWidth = 240.0; // Largeur du sidebar (redimensionnable)

  @override
  void initState() {
    super.initState();
    // Utiliser le vrai HOME de l'utilisateur au lieu du chemin sandbox
    final initialPath = Platform.environment['HOME'] ?? SpecialLocations.desktop;
    final repository = FileSystemRepositoryImpl(LocalFileSystemDataSource());
    _viewModel = ExplorerViewModel(
      listDirectoryEntries: ListDirectoryEntries(repository),
      createDirectory: CreateDirectory(repository),
      deleteEntries: DeleteEntries(repository),
      moveEntries: MoveEntries(repository),
      copyEntries: CopyEntries(repository),
      duplicateEntries: DuplicateEntries(repository),
      renameEntry: RenameEntry(repository),
      initialPath: initialPath,
    );
    _pathController = TextEditingController(text: initialPath);
    _searchController = TextEditingController(text: '');
    _searchFocusNode = FocusNode();
    _favoriteItems = _buildFavoriteItems();
    _systemItems = _buildSystemItems(initialPath);
    _quickItems = _buildQuickItems();
    _tagItems = _buildTags();
    _volumes = _readVolumes();
    _viewModel.loadDirectory(initialPath, pushHistory: false);
    _viewModel.bootstrap();
    _loadSidebarWidth();
  }

  /// Charge la largeur du sidebar depuis SharedPreferences
  Future<void> _loadSidebarWidth() async {
    final prefs = await SharedPreferences.getInstance();
    final savedWidth = prefs.getDouble('sidebar_width');
    if (savedWidth != null && mounted) {
      setState(() {
        _sidebarWidth = savedWidth.clamp(180.0, 400.0);
      });
    }
  }

  /// Sauvegarde la largeur du sidebar dans SharedPreferences
  Future<void> _saveSidebarWidth(double width) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sidebar_width', width);
  }

  Widget _buildSearchToggle() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: _isSearchExpanded ? 260 : 48,
      child: _isSearchExpanded
          ? TextField(
              focusNode: _searchFocusNode,
              controller: _searchController,
              onChanged: _viewModel.updateSearch,
              onSubmitted: _viewModel.updateSearch,
              decoration: InputDecoration(
                prefixIcon: const Icon(lucide.LucideIcons.search),
                hintText: 'Recherche',
                suffixIcon: IconButton(
                  icon: const Icon(lucide.LucideIcons.x),
                  onPressed: () {
                    setState(() => _isSearchExpanded = false);
                    _searchFocusNode.unfocus();
                  },
                  tooltip: 'Fermer la recherche',
                ),
              ),
            )
          : ToolbarButton(
              icon: lucide.LucideIcons.search,
              tooltip: 'Rechercher',
              onPressed: () {
                setState(() => _isSearchExpanded = true);
                Future.microtask(() => _searchFocusNode.requestFocus());
              },
              isActive: false,
            ),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _pathController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final themeProvider = context.watch<ThemeProvider>();
        final bgImagePath = themeProvider.backgroundImagePath;
        final hasBgImage =
            bgImagePath != null && File(bgImagePath).existsSync();
        final isLight = themeProvider.isLight;
        final theme = Theme.of(context);
        final bgColor = hasBgImage
            ? (isLight
                ? Colors.white.withOpacity(0.7)
                : Colors.black.withOpacity(0.5))
            : theme.colorScheme.background;
        final adjustedSurface = hasBgImage
            ? (isLight
                ? Colors.white.withOpacity(0.98)
                : Colors.black.withOpacity(0.75))
            : theme.colorScheme.surface;
        final adjustedOnSurface = hasBgImage && isLight
            ? Colors.black
            : (hasBgImage ? Colors.white : theme.colorScheme.onSurface);
        final overlayLight = hasBgImage && isLight
            ? Colors.white.withOpacity(0.55)
            : null;
        final overlayPrimary = hasBgImage && isLight
            ? Colors.white.withOpacity(0.6)
            : null;
        final themed = theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            surface: adjustedSurface,
            onSurface: adjustedOnSurface,
            onPrimary: hasBgImage && isLight
                ? Colors.black
                : (hasBgImage ? Colors.white : theme.colorScheme.onPrimary),
            onSecondary: hasBgImage && isLight
                ? Colors.black
                : (hasBgImage ? Colors.white : theme.colorScheme.onSecondary),
            onTertiary: hasBgImage && isLight
                ? Colors.black
                : (hasBgImage ? Colors.white : theme.colorScheme.onTertiary),
          ),
        );

        final state = _viewModel.state;
        if (_pathController.text != state.currentPath) {
          _pathController.text = state.currentPath;
        }
        if (_searchController.text != state.searchQuery) {
          _searchController.text = state.searchQuery;
        }

        final entries = _viewModel.visibleEntries;
        if (state.statusMessage != null &&
            state.statusMessage != _lastStatusMessage) {
          _lastStatusMessage = state.statusMessage;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showToast(state.statusMessage!);
            _viewModel.clearStatus();
          });
        } else if (state.statusMessage == null && _lastStatusMessage != null) {
          _lastStatusMessage = null;
        }

        return Theme(
          data: themed,
          child: Scaffold(
            body: Stack(
              children: [
                // Background image
                if (hasBgImage)
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(File(bgImagePath)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                // Overlay layer (dark in dark mode, light in light mode)
                if (hasBgImage)
                  Container(
                    color: isLight
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.4),
                  ),
                // Main content
                Container(
                  color: hasBgImage ? Colors.transparent : bgColor,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          // Toolbar
                          _buildToolbar(state),
                          const SizedBox(height: 8),
                          // Main content area
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                      // Sidebar avec resize handle
                      Row(
                        children: [
                          SizedBox(
                            width: _isSidebarCollapsed ? 70 : _sidebarWidth,
                            child: _Sidebar(
                              favoriteItems: _favoriteItems,
                              systemItems: _systemItems,
                              quickItems: _quickItems,
                              tags: _tagItems,
                              volumes: _volumes,
                              recentPaths: state.recentPaths,
                              selectedTags: _viewModel.selectedTags,
                              selectedTypes: _viewModel.selectedTypes,
                              onNavigate: _viewModel.loadDirectory,
                              onTagToggle: _viewModel.toggleTag,
                              onTypeToggle: _viewModel.toggleType,
                              onToggleCollapse: () {
                                setState(
                                    () => _isSidebarCollapsed = !_isSidebarCollapsed);
                              },
                              isLight: themeProvider.isLight,
                              currentPalette: themeProvider.currentPalette,
                              onToggleLight: themeProvider.setLightMode,
                              onPaletteSelected: themeProvider.setPalette,
                              collapsed: _isSidebarCollapsed,
                            ),
                          ),
                          // Resize handle - seulement visible quand sidebar n'est pas collapsed
                          if (!_isSidebarCollapsed)
                           MouseRegion(
                              cursor: SystemMouseCursors.resizeColumn,
                              child: GestureDetector(
                                onPanUpdate: (details) {
                                  setState(() {
                                    _sidebarWidth = (_sidebarWidth + details.delta.dx)
                                        .clamp(180.0, 400.0); // Min 180px, Max 400px
                                  });
                                },
                                onPanEnd: (_) {
                                  // Sauvegarder la largeur quand l'utilisateur termine le redimensionnement
                                   _saveSidebarWidth(_sidebarWidth);
                                 },
                                 child: Container(
                                   width: 8,
                                   color: Colors.transparent,
                                   child: Center(
                                     child: Container(
                                       width: 2,
                                       color: Colors.white.withValues(alpha: 0.1),
                                     ),
                                   ),
                                 ),
                             ),
                           )
                         else
                            const SizedBox(width: 8),
                       ],
                     ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GlassPanelV2(
                              level: GlassPanelLevel.secondary,
                              child: _buildToolbar(state),
                            ),
                            const SizedBox(height: 8),
                            GlassPanelV2(
                              level: GlassPanelLevel.secondary,
                              child: _buildActionBar(state),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: GlassPanelV2(
                                level: GlassPanelLevel.primary,
                                padding: const EdgeInsets.all(0),
                                child: _buildContent(state, entries),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _StatsFooter(state: state),
                          ),
                          const SizedBox(height: 8),
                          GlassPanelV2(
                            level: GlassPanelLevel.tertiary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                BreadcrumbBar(
                                  path: state.currentPath,
                                  onNavigate: (path) =>
                                      _viewModel.loadDirectory(path),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ), // Row (sidebar + content)
              ), // Expanded (wraps Row)
            ], // Column children
          ), // Column
        ), // Padding
      ), // SafeArea
    ), // Container
              ], // Stack children
            ), // Stack
          ), // Scaffold body
        );
      },
    );
  }

  Widget _buildToolbar(ExplorerViewState state) {
    return Row(
      children: [
        // Groupe 1: Navigation historique (back/forward)
        ToolbarButton(
          icon: lucide.LucideIcons.arrowLeft,
          tooltip: 'Précédent',
          onPressed: state.isLoading || !_viewModel.canGoBack
              ? null
              : _viewModel.goBack,
        ),
        const SizedBox(width: 4),
        ToolbarButton(
          icon: lucide.LucideIcons.arrowRight,
          tooltip: 'Suivant',
          onPressed: state.isLoading || !_viewModel.canGoForward
              ? null
              : _viewModel.goForward,
        ),
        const SizedBox(width: 4),
        ToolbarButton(
          icon: lucide.LucideIcons.arrowUp,
          tooltip: 'Dossier parent',
          onPressed: state.currentPath == '/' || state.currentPath.isEmpty
              ? null
              : _viewModel.goToParent,
        ),

        const SizedBox(width: 12),
        // Séparateur vertical
        Container(
          width: 1,
          height: 24,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        const SizedBox(width: 12),

        // Groupe 2: Actions (refresh/history)
        ToolbarButton(
          icon: lucide.LucideIcons.refreshCw,
          tooltip: 'Rafraîchir',
          onPressed: state.isLoading ? null : _viewModel.refresh,
        ),
        const SizedBox(width: 4),
        ToolbarButton(
          icon: lucide.LucideIcons.history,
          tooltip: 'Dernier emplacement',
          onPressed: state.isLoading || state.recentPaths.length < 2
              ? null
              : _viewModel.goToLastVisited,
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _PathInput(
            controller: _pathController,
            onSubmit: (value) => _viewModel.loadDirectory(value),
          ),
        ),
        const SizedBox(width: 12),
        _buildSearchToggle(),
        const SizedBox(width: 12),
        ToolbarButton(
          icon: lucide.LucideIcons.list,
          tooltip: 'Vue liste',
          isActive: state.viewMode == ExplorerViewMode.list,
          onPressed: () => _viewModel.setViewMode(ExplorerViewMode.list),
        ),
        const SizedBox(width: 8),
        ToolbarButton(
          icon: lucide.LucideIcons.grid,
          tooltip: 'Vue grille',
          isActive: state.viewMode == ExplorerViewMode.grid,
          onPressed: () => _viewModel.setViewMode(ExplorerViewMode.grid),
        ),
      ],
    );
  }

  Widget _buildContent(ExplorerViewState state, List<FileEntry> entries) {
    if (state.isLoading && entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Chargement du dossier...'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(lucide.LucideIcons.alertCircle, size: 48),
              const SizedBox(height: 12),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _viewModel.loadDirectory(state.currentPath),
                child: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final selectionMode = state.selectedPaths.isNotEmpty;
    final content = entries.isEmpty
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 80),
              Center(child: Icon(lucide.LucideIcons.folderX, size: 56)),
              SizedBox(height: 8),
              Center(
                child: Text('Aucun element dans ce dossier (ou acces limite)'),
              ),
              SizedBox(height: 40),
            ],
          )
        : state.viewMode == ExplorerViewMode.list
        ? _buildList(entries, selectionMode)
        : _buildGrid(entries, selectionMode);

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onSecondaryTapDown: (details) =>
          _showContextMenu(null, details.globalPosition),
      child: Stack(
        children: [
          RefreshIndicator(onRefresh: _viewModel.refresh, child: content),
          if (state.isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildActionBar(ExplorerViewState state) {
    final selectionCount = state.selectedPaths.length;

    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            // Groupe 1: Création
            ToolbarButton(
              icon: lucide.LucideIcons.folderPlus,
              tooltip: 'Nouveau dossier',
              isActive: !state.isLoading,
              onPressed: state.isLoading ? null : _promptCreateFolder,
            ),
            const SizedBox(width: 12),

            // Séparateur
            Container(
              width: 1,
              height: 24,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(width: 12),

            // Groupe 2: Presse-papier
            ToolbarButton(
              icon: lucide.LucideIcons.copy,
              tooltip: 'Copier',
              isActive: !state.isLoading && selectionCount > 0,
              onPressed: state.isLoading || selectionCount == 0
                  ? null
                  : _viewModel.copySelectionToClipboard,
            ),
            const SizedBox(width: 4),
            ToolbarButton(
              icon: lucide.LucideIcons.scissors,
              tooltip: 'Couper',
              isActive: !state.isLoading && selectionCount > 0,
              onPressed: state.isLoading || selectionCount == 0
                  ? null
                  : _viewModel.cutSelectionToClipboard,
            ),
            const SizedBox(width: 4),
            ToolbarButton(
              icon: lucide.LucideIcons.clipboard,
              tooltip: 'Coller',
              isActive: !state.isLoading && _viewModel.canPaste,
              onPressed: state.isLoading || !_viewModel.canPaste
                  ? null
                  : _viewModel.pasteClipboard,
            ),
            const SizedBox(width: 12),

            // Séparateur
            Container(
              width: 1,
              height: 24,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(width: 12),

            // Groupe 3: Actions sur fichiers
            ToolbarButton(
              icon: lucide.LucideIcons.edit3,
              tooltip: 'Renommer',
              isActive: !state.isLoading && selectionCount == 1,
              onPressed: state.isLoading || selectionCount != 1
                  ? null
                  : _promptRename,
            ),
            const SizedBox(width: 4),
            ToolbarButton(
              icon: lucide.LucideIcons.move,
              tooltip: 'Déplacer',
              isActive: !state.isLoading && selectionCount > 0,
              onPressed: state.isLoading || selectionCount == 0
                  ? null
                  : _promptMove,
            ),
            const SizedBox(width: 4),
            ToolbarButton(
              icon: lucide.LucideIcons.trash2,
              tooltip: 'Supprimer',
              isActive: !state.isLoading && selectionCount > 0,
              onPressed: state.isLoading || selectionCount == 0
                  ? null
                  : _confirmDeletion,
            ),

            const SizedBox(width: 16),
            if (selectionCount > 0) ...[
              Text(
                '$selectionCount sélectionné(s)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: state.isLoading ? null : _viewModel.clearSelection,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      lucide.LucideIcons.x,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleEntryTap(FileEntry entry) {
    if (entry.isApplication) {
      _viewModel.launchApplication(entry);
    } else {
      _viewModel.open(entry);
    }
  }

  Future<void> _promptCreateFolder() async {
    final name = await _showTextDialog(
      title: 'Nouveau dossier',
      label: 'Nom du dossier',
      initial: 'Nouveau dossier',
    );
    if (name == null || name.trim().isEmpty) return;
    await _viewModel.createFolder(name.trim());
  }

  Future<void> _promptRename() async {
    final selected = _viewModel.state.selectedPaths;
    if (selected.length != 1) return;
    final entry = _viewModel.state.entries.firstWhere(
      (element) => selected.contains(element.path),
    );
    final newName = await _showTextDialog(
      title: 'Renommer',
      label: 'Nouveau nom',
      initial: entry.name,
    );
    if (newName == null || newName.trim().isEmpty) return;
    await _viewModel.renameSelected(newName.trim());
  }

  Future<void> _promptMove() async {
    final destination = await _showTextDialog(
      title: 'Deplacer vers...',
      label: 'Chemin de destination',
      initial: _viewModel.state.currentPath,
    );
    if (destination == null || destination.trim().isEmpty) return;
    await _viewModel.moveSelected(destination.trim());
  }

  Future<void> _confirmDeletion() async {
    final count = _viewModel.state.selectedPaths.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer'),
          content: Text(
            'Supprimer $count element(s) ? Cette action est definitive.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent.shade200,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _viewModel.deleteSelected();
    }
  }

  Future<void> _showContextMenu(FileEntry? entry, Offset globalPosition) async {
    if (_contextMenuOpen) return;
    _contextMenuOpen = true;

    if (entry != null && !_viewModel.state.selectedPaths.contains(entry.path)) {
      _viewModel.selectSingle(entry);
    }

    final items = <_MenuItem>[];
    if (entry != null) {
      items.add(const _MenuItem('open', 'Ouvrir'));
      if (entry.isApplication) {
        items.addAll(const [
          _MenuItem('launchApp', 'Lancer l application'),
          _MenuItem('openPackage', 'Ouvrir comme dossier'),
        ]);
      }
      items.addAll(const [
        _MenuItem('reveal', 'Afficher dans Finder'),
        _MenuItem('copy', 'Copier'),
        _MenuItem('cut', 'Couper'),
        _MenuItem('copyPath', 'Copier le chemin'),
        _MenuItem('openTerminal', 'Ouvrir le terminal ici'),
      ]);
    }

    final pasteDestination = entry != null && entry.isDirectory
        ? entry.path
        : null;
    if (_viewModel.canPaste) {
      items.add(
        _MenuItem(
          'paste',
          pasteDestination != null ? 'Coller dans ce dossier' : 'Coller ici',
        ),
      );
    }

    if (entry != null) {
      items.addAll(const [
        _MenuItem('duplicate', 'Dupliquer'),
        _MenuItem('move', 'Deplacer vers...'),
        _MenuItem('rename', 'Renommer'),
        _MenuItem('delete', 'Supprimer'),
      ]);
    } else {
      items.add(const _MenuItem('newFolder', 'Nouveau dossier'));
    }
    if (_viewModel.state.selectedPaths.isNotEmpty) {
      items.add(const _MenuItem('compress', 'Compresser en .zip'));
    }
    if (entry == null) {
      items.addAll(const [
        _MenuItem('copyPath', 'Copier le chemin courant'),
        _MenuItem('openTerminal', 'Ouvrir le terminal ici'),
      ]);
    }

    String? selected;
    try {
      final brightness = Theme.of(context).brightness;
      final menuBg = DesignTokens.selectionMenuBackground(brightness);
      final menuText = Theme.of(context).colorScheme.onSurface;
      selected = await showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          globalPosition.dx,
          globalPosition.dy,
          globalPosition.dx,
          globalPosition.dy,
        ),
        items: items
            .map(
              (item) => PopupMenuItem<String>(
                value: item.value,
                enabled: item.enabled,
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: menuText),
                  child: Text(item.label),
                ),
              ),
            )
            .toList(),
        color: menuBg,
      );
    } finally {
      _contextMenuOpen = false;
    }

    switch (selected) {
      case 'open':
        if (entry != null) _viewModel.open(entry);
        break;
      case 'reveal':
        if (entry != null) await _viewModel.openInFinder(entry);
        break;
      case 'launchApp':
        if (entry != null) await _viewModel.launchApplication(entry);
        break;
      case 'openPackage':
        if (entry != null) await _viewModel.openPackageAsFolder(entry);
        break;
      case 'copy':
        _viewModel.copySelectionToClipboard();
        break;
      case 'cut':
        _viewModel.cutSelectionToClipboard();
        break;
      case 'paste':
        await _viewModel.pasteClipboard(pasteDestination);
        break;
      case 'duplicate':
        await _viewModel.duplicateSelected();
        break;
      case 'move':
        await _promptMove();
        break;
      case 'rename':
        await _promptRename();
        break;
      case 'delete':
        await _confirmDeletion();
        break;
      case 'newFolder':
        await _promptCreateFolder();
        break;
      case 'copyPath':
        _viewModel.copyPathToClipboard(
          entry?.path ?? _viewModel.state.currentPath,
        );
        break;
      case 'openTerminal':
        await _viewModel.openTerminalHere(
          entry != null && entry.isDirectory
              ? entry.path
              : _viewModel.state.currentPath,
        );
        break;
      case 'compress':
        await _viewModel.compressSelected();
        break;
    }
  }

  Future<String?> _showTextDialog({
    required String title,
    required String label,
    String initial = '',
  }) async {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: label),
            autofocus: true,
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDraggableEntry({
    required FileEntry entry,
    required bool selectionMode,
    required ExplorerViewMode viewMode,
  }) {
    final selectedEntries = _viewModel.state.selectedPaths.contains(entry.path)
        ? _viewModel.state.entries
              .where((e) => _viewModel.state.selectedPaths.contains(e.path))
              .toList()
        : <FileEntry>[entry];

    final tile = FileEntryTile(
      entry: entry,
      viewMode: viewMode,
      selectionMode: selectionMode,
      isSelected: _viewModel.isSelected(entry),
      onToggleSelection: () => _viewModel.toggleSelection(entry),
      onOpen: () => _handleEntryTap(entry),
      onContextMenu: (position) => _showContextMenu(entry, position),
    );
    final draggingTile = Opacity(
      opacity: 0.35,
      child: FileEntryTile(
        entry: entry,
        viewMode: viewMode,
        selectionMode: selectionMode,
        isSelected: _viewModel.isSelected(entry),
        onToggleSelection: () => _viewModel.toggleSelection(entry),
        onOpen: () => _handleEntryTap(entry),
        onContextMenu: (position) => _showContextMenu(entry, position),
      ),
    );

    final draggable = Draggable<List<FileEntry>>(
      data: selectedEntries,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _DragFeedback(entry: entry),
      childWhenDragging: draggingTile,
      child: tile,
    );

    if (!entry.isDirectory) return draggable;

    return DragTarget<List<FileEntry>>(
      onWillAccept: (data) {
        if (data == null || data.isEmpty) return false;
        final hasSelf = data.any((item) => item.path == entry.path);
        if (hasSelf) return false;
        final intoDescendant = data.any(
          (item) => _isAncestorPath(item.path, entry.path),
        );
        if (intoDescendant) return false;
        return true;
      },
      onAccept: (data) => _viewModel.moveEntriesTo(data, entry.path),
      builder: (context, candidates, rejected) {
        final isHovering = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: isHovering
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                )
              : null,
          child: draggable,
        );
      },
    );
  }

  bool _isAncestorPath(String parent, String child) {
    final separator = Platform.pathSeparator;
    final normalizedParent = parent.endsWith(separator)
        ? parent
        : '$parent$separator';
    final normalizedChild = child.endsWith(separator)
        ? child
        : '$child$separator';
    return normalizedChild.startsWith(normalizedParent);
  }

  Widget _buildList(List<FileEntry> entries, bool selectionMode) {
    return ListViewTable(
      entries: entries,
      selectionMode: selectionMode,
      isSelected: (entry) => _viewModel.isSelected(entry),
      onEntryTap: (entry) {
        if (selectionMode) {
          _viewModel.toggleSelection(entry);
        } else {
          _viewModel.selectSingle(entry);
        }
      },
      onEntryDoubleTap: (entry) => _handleEntryTap(entry),
      onEntrySecondaryTap: (entry, offset) {
        if (!_viewModel.isSelected(entry)) {
          _viewModel.selectSingle(entry);
        }
        _showContextMenu(entry, offset);
      },
    );
  }

  Widget _buildGrid(List<FileEntry> entries, bool selectionMode) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final crossAxisCount = (maxWidth / 220).clamp(2, 6).floor();

        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _buildDraggableEntry(
              entry: entry,
              selectionMode: selectionMode,
              viewMode: ExplorerViewMode.grid,
            );
          },
        );
      },
    );
  }

  List<_NavItem> _buildFavoriteItems() {
    final home = Platform.environment['HOME'] ?? Directory.current.parent.path;
    return [
      _NavItem(label: 'Accueil', icon: lucide.LucideIcons.home, path: home),
      _NavItem(
        label: 'Bureau',
        icon: lucide.LucideIcons.monitor,
        path: _join(home, 'Desktop'),
      ),
      _NavItem(
        label: 'Documents',
        icon: lucide.LucideIcons.folderOpen,
        path: _join(home, 'Documents'),
      ),
      _NavItem(
        label: 'Telechargements',
        icon: lucide.LucideIcons.download,
        path: _join(home, 'Downloads'),
      ),
    ];
  }

  List<_NavItem> _buildSystemItems(String initialPath) {
    return [
      _NavItem(
        label: 'Bureau',
        icon: lucide.LucideIcons.monitor,
        path: SpecialLocations.desktop,
      ),
      _NavItem(
        label: 'Documents',
        icon: lucide.LucideIcons.fileText,
        path: SpecialLocations.documents,
      ),
      _NavItem(
        label: 'Téléchargements',
        icon: lucide.LucideIcons.download,
        path: SpecialLocations.downloads,
      ),
      _NavItem(
        label: 'Images',
        icon: lucide.LucideIcons.image,
        path: SpecialLocations.pictures,
      ),
    ];
  }

  List<_NavItem> _buildQuickItems() {
    final home = Platform.environment['HOME'] ?? Directory.current.parent.path;
    return [
      _NavItem(label: 'Recents', icon: lucide.LucideIcons.clock3, path: home),
      _NavItem(label: 'Partage', icon: lucide.LucideIcons.share2, path: home),
    ];
  }

  List<_TagItem> _buildTags() {
    return const [
      _TagItem(label: 'Rouge', color: Colors.redAccent),
      _TagItem(label: 'Orange', color: Colors.orangeAccent),
      _TagItem(label: 'Jaune', color: Colors.amberAccent),
      _TagItem(label: 'Vert', color: Colors.lightGreenAccent),
      _TagItem(label: 'Bleu', color: Colors.lightBlueAccent),
      _TagItem(label: 'Violet', color: Colors.purpleAccent),
      _TagItem(label: 'Gris', color: Colors.grey),
    ];
  }

  List<_VolumeInfo> _readVolumes() {
    final paths = <String>{};
    final volumesDir = Directory('/Volumes');
    if (volumesDir.existsSync()) {
      for (final entity in volumesDir.listSync()) {
        paths.add(entity.path);
      }
    }

    final volumes = <_VolumeInfo>[];
    for (final path in paths) {
      final info = _getVolumeInfo(path);
      if (info != null) {
        volumes.add(info);
      }
    }
    return volumes;
  }

  _VolumeInfo? _getVolumeInfo(String path) {
    try {
      final result = Process.runSync('df', ['-Pk', path]);
      if (result.exitCode != 0) return null;
      final lines = (result.stdout as String)
          .trim()
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      if (lines.length < 2) return null;

      // Parse the last line (actual data, skipping header)
      final line = lines.last;
      final parts = line.split(RegExp(r'\s+'));

      // Format: Filesystem | 1024-blocks | Used | Available | Capacity% | Mounted on
      if (parts.length < 6) return null;

      final totalKilobytes = double.tryParse(parts[1]);
      if (totalKilobytes == null || totalKilobytes <= 0) return null;

      // Extract capacity percentage (remove % and parse as double)
      final capacityStr = parts[4];
      final capacityPercent =
          double.tryParse(capacityStr.replaceAll('%', '')) ?? 0;
      final usage = capacityPercent / 100.0; // Convert to 0.0-1.0 range

      // Mount point can have spaces, so join remaining parts
      final mountPoint = parts.sublist(5).join(' ');

      // Extract label from mount point
      final label = mountPoint
          .split(Platform.pathSeparator)
          .where((p) => p.isNotEmpty)
          .lastWhere((p) => p.isNotEmpty, orElse: () => mountPoint);

      // totalKilobytes is in 1024-byte blocks (from df -Pk), so multiply by 1024 for bytes
      final totalBytes = (totalKilobytes * 1024).toInt();

      return _VolumeInfo(
        label: label,
        path: mountPoint,
        usage: usage,
        totalBytes: totalBytes,
      );
    } catch (_) {
      return null;
    }
  }

  String _join(String base, String child) {
    if (base.endsWith(Platform.pathSeparator)) return '$base$child';
    return '$base${Platform.pathSeparator}$child';
  }

  void _showToast(String message) {
    if (_isToastShowing) return;
    try {
      _isToastShowing = true;
      final theme = Theme.of(context);
      Flushbar(
        message: message,
        maxWidth: 360,
        margin: const EdgeInsets.only(left: 12, bottom: 8, right: 300),
        borderRadius: BorderRadius.circular(14),
        backgroundColor: theme.colorScheme.surface.withOpacity(0.9),
        duration: const Duration(milliseconds: 1700),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        icon: Icon(
          lucide.LucideIcons.info,
          size: 22,
          color: theme.colorScheme.primary,
        ),
        leftBarIndicatorColor: theme.colorScheme.primary,
        shouldIconPulse: false,
        flushbarPosition: FlushbarPosition.BOTTOM,
        onStatusChanged: (status) {
          if (status == FlushbarStatus.DISMISSED ||
              status == FlushbarStatus.IS_HIDING) {
            _isToastShowing = false;
          }
        },
      ).show(context);
    } catch (_) {
      _isToastShowing = false;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _MenuItem {
  const _MenuItem(this.value, this.label, {this.enabled = true});
  final String value;
  final String label;
  final bool enabled;
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.entry});

  final FileEntry entry;

  @override
  Widget build(BuildContext context) {
    final icon = entry.isDirectory ? lucide.LucideIcons.folder : lucide.LucideIcons.file;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                entry.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
  final bool collapsed;
  final bool isLight;
  final ColorPalette currentPalette;
  final Future<void> Function(bool) onToggleLight;
  final Future<void> Function(ColorPalette) onPaletteSelected;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return GlassPanelV2(
        level: GlassPanelLevel.tertiary,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: SingleChildScrollView(
          child: Column(
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
              if (onToggleCollapse != null) ...[
                const SizedBox(height: 10),
                _RailButton(
                  icon: lucide.LucideIcons.panelRightOpen,
                  tooltip: 'Etendre',
                  onTap: onToggleCollapse,
                ),
              ],
              const SizedBox(height: 12),
              ThemeRailControlsV2(
                isLight: isLight,
                currentPalette: currentPalette,
                onToggleLight: onToggleLight,
                onPaletteSelected: onPaletteSelected,
              ),
            ],
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
            // Bouton pour replier le menu en haut
            if (onToggleCollapse != null)
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onToggleCollapse,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Icon(
                            lucide.LucideIcons.panelLeftClose,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: isLight ? 0.75 : 0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Replier',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: isLight ? 0.75 : 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

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
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              child: ThemeControlsV2(
                isLight: isLight,
                currentPalette: currentPalette,
                onToggleLight: onToggleLight,
                onPaletteSelected: onPaletteSelected,
              ),
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

    return Opacity(
      opacity: 0.7,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _StatChip(
              label: 'Selectionés',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.black.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
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
    final labelColor = onSurface.withValues(alpha: isLight ? 0.7 : 0.75);
    final iconColor = onSurface.withValues(alpha: isLight ? 0.75 : 0.8);

    return TextField(
      controller: controller,
      onSubmitted: onSubmit,
      style: TextStyle(fontSize: 14, color: textColor),
      decoration: InputDecoration(
        labelText: 'Chemin du dossier',
        labelStyle: TextStyle(color: labelColor),
        prefixIcon: Icon(
          lucide.LucideIcons.folderOpen,
          color: iconColor,
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
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Recherche (nom ou extension)',
        prefixIcon: const Icon(lucide.LucideIcons.search),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final onSurface = theme.colorScheme.onSurface;
    final bgColor =
        isLight ? Colors.white.withValues(alpha: 0.82) : Colors.black.withValues(alpha: 0.85);
    final borderColor =
        isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.12);
    final headerText = onSurface.withValues(alpha: isLight ? 0.9 : 0.95);
    final subtitleText = onSurface.withValues(alpha: isLight ? 0.6 : 0.7);
    final tileBg =
        isLight ? onSurface.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.06);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 520),
          decoration: BoxDecoration(
            color: bgColor,
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
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      lucide.LucideIcons.hardDrive,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Tous les disques',
                      style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: headerText,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(lucide.LucideIcons.x),
                      onPressed: () => Navigator.of(context).pop(),
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
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
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: tileBg,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  lucide.LucideIcons.hardDrive,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      volume.label,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                            color: headerText,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      volume.path,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                            color: subtitleText,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: volume.usage.clamp(0, 1),
                                        minHeight: 6,
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
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$percent%',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                          color: headerText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatBytes(volume.totalBytes),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                          color: subtitleText,
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
