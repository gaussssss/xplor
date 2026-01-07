import 'dart:io';
import 'dart:ui';

import 'package:another_flushbar/flushbar.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../core/constants/assets.dart';
import '../../../../core/constants/special_locations.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/color_palettes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/mini_explorer_dialog.dart';
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
import '../../../search/domain/usecases/search_files_progressive.dart';
import '../../../search/domain/usecases/build_index.dart';
import '../../../search/domain/usecases/update_index.dart';
import '../../../search/domain/usecases/get_index_status.dart';
import '../../../search/data/repositories/search_repository_impl.dart';
import '../../../search/data/datasources/sqlite_search_impl.dart';
import '../viewmodels/explorer_view_model.dart';
import '../widgets/breadcrumb_bar.dart';
import '../widgets/file_entry_tile.dart';
import '../widgets/glass_panel_v2.dart';
import '../widgets/list_view_table.dart';
import '../widgets/sidebar_section.dart';
import '../widgets/toolbar_button.dart';
import '../../../../core/widgets/theme_controls_v2.dart';
import '../../../../core/widgets/appearance_settings_dialog_v2.dart';
import '../../../settings/presentation/pages/about_page.dart';
import '../../../settings/presentation/pages/terms_of_service_page.dart';
import '../../domain/entities/duplicate_action.dart';

part 'explorer_page_support.dart';
part 'explorer_page_sidebar.dart';
part 'explorer_page_dialogs.dart';

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
  late final ScrollController _scrollController;
  late final List<_NavItem> _favoriteItems;
  late final List<_NavItem> _systemItems;
  late final List<_NavItem> _quickItems;
  late final List<_TagItem> _tagItems;
  late final List<_VolumeInfo> _volumes;
  String? _lastStatusMessage;
  String? _lastPendingOpenPath;
  bool _contextMenuOpen = false;
  bool _isSearchExpanded = false;
  bool _isToastShowing = false;
  bool _isSidebarCollapsed = false;
  bool _isMultiSelectionMode = false;
  double _sidebarWidth = 240.0; // Largeur du sidebar (redimensionnable)
  String _lastPath = ''; // Pour détecter les changements de dossier

  // État du drag and drop
  bool _isDragging = false;
  String? _dragTargetPath; // Le dossier cible pour le drop

  @override
  void initState() {
    super.initState();
    // Utiliser le vrai HOME de l'utilisateur au lieu du chemin sandbox
    final initialPath = Platform.environment['HOME'] ?? SpecialLocations.desktop;
    final repository = FileSystemRepositoryImpl(LocalFileSystemDataSource());
    final searchRepository = SearchRepositoryImpl(SqliteSearchDatabase());
    _viewModel = ExplorerViewModel(
      listDirectoryEntries: ListDirectoryEntries(repository),
      createDirectory: CreateDirectory(repository),
      deleteEntries: DeleteEntries(repository),
      moveEntries: MoveEntries(repository),
      copyEntries: CopyEntries(repository),
      duplicateEntries: DuplicateEntries(repository),
      renameEntry: RenameEntry(repository),
      initialPath: initialPath,
      searchFilesProgressive: SearchFilesProgressive(searchRepository),
      buildIndex: BuildIndex(searchRepository),
      updateIndex: UpdateIndex(searchRepository),
      getIndexStatus: GetIndexStatus(searchRepository),
    );
    _pathController = TextEditingController(text: initialPath);
    _searchController = TextEditingController(text: '');
    _searchFocusNode = FocusNode();
    _scrollController = ScrollController();
    _lastPath = initialPath;
    _favoriteItems = _buildFavoriteItems();
    _systemItems = _buildSystemItems(initialPath);
    _quickItems = _buildQuickItems();
    _tagItems = _buildTags();
    _volumes = _readVolumes();
    _viewModel.loadDirectory(initialPath);
    _loadSelectionMode();
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSelectionMode() async {
    bool enabled = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool('multi_selection_mode') ?? false;
    } catch (_) {
      enabled = false;
    }
    if (!mounted) return;
    if (_isMultiSelectionMode != enabled) {
      setState(() => _isMultiSelectionMode = enabled);
    }
    _viewModel.setMultiSelectionEnabled(enabled);
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
        final displayPath = _viewModel.displayPath;
        if (_pathController.text != displayPath) {
          _pathController.text = displayPath;
        }

        // Scroller vers le haut quand on change de dossier
        if (_lastPath != state.currentPath) {
          _lastPath = state.currentPath;
          // Utiliser addPostFrameCallback pour éviter les erreurs pendant le build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(0);
            }
          });
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
        if (state.pendingOpenPath != null &&
            state.pendingOpenPath != _lastPendingOpenPath) {
          _lastPendingOpenPath = state.pendingOpenPath;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            final targetPath = state.pendingOpenPath!;
            final shouldOpen = await _showOpenExtractedPrompt(
              targetPath,
              state.pendingOpenLabel,
            );
            _viewModel.clearPendingOpenPath();
            if (shouldOpen == true && mounted) {
              await _viewModel.loadDirectory(targetPath);
            }
          });
        } else if (state.pendingOpenPath == null &&
            _lastPendingOpenPath != null) {
          _lastPendingOpenPath = null;
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
                      padding: EdgeInsets.only(
                        left: 10,
                        top: 35,
                        right: 10,
                        bottom: 10,
                      ),
                      child: Column(
                        children: [
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
                              onSettingsClosed: _loadSelectionMode,
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
                                  // TODO: Implémenter la sauvegarde de la largeur si nécessaire
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
                // Zone de double-clic pour maximiser/restaurer la fenêtre (macOS/Windows)
                // Placé à la fin du Stack pour être au-dessus du contenu
                if (Platform.isMacOS || Platform.isWindows)
                  Positioned(
                    top: 0,
                    left: Platform.isMacOS ? 80 : 0,
                    right: Platform.isMacOS ? 0 : 140,
                    height: Platform.isMacOS ? 28 : 32,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onDoubleTap: () async {
                        if (await windowManager.isMaximized()) {
                          await windowManager.unmaximize();
                        } else {
                          await windowManager.maximize();
                        }
                      },
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
              ], // Stack children
            ), // Stack
          ), // Scaffold body
        );
      },
    );
  }

  Widget _buildToolbar(ExplorerViewState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
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
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(width: 12),
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 200,
                maxWidth: 900,
              ),
              child: _PathInput(
                controller: _pathController,
                onSubmit: (value) => _viewModel
                    .loadDirectory(_viewModel.resolveInputPath(value)),
              ),
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
      ),
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

    final selectionMode = _isMultiSelectionMode;
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

    return DropTarget(
      onDragEntered: (details) {
        setState(() {
          _isDragging = true;
          _dragTargetPath = state.currentPath;
        });
      },
      onDragExited: (details) {
        setState(() {
          _isDragging = false;
          _dragTargetPath = null;
        });
      },
      onDragDone: (details) async {
        setState(() {
          _isDragging = false;
          _dragTargetPath = null;
        });

        // Vérifier les doublons et créer un mapping source -> nom de fichier
        final targetDir = Directory(state.currentPath);
        final duplicates = <String>[];
        final sourcePathMap = <String, String>{};

        for (final file in details.files) {
          final fileName = file.path.split(Platform.pathSeparator).last;
          final targetPath = '${targetDir.path}${Platform.pathSeparator}$fileName';
          sourcePathMap[fileName] = file.path;

          if (FileSystemEntity.typeSync(targetPath) != FileSystemEntityType.notFound) {
            duplicates.add(fileName);
          }
        }

        // Demander l'action pour chaque doublon
        Map<String, DuplicateAction>? actions;
        if (duplicates.isNotEmpty && mounted) {
          actions = await _showDuplicateDialog(duplicates, sourcePathMap);
          if (actions == null) {
            return; // L'utilisateur a annulé
          }
        }

        // Copier les fichiers/dossiers
        try {
          int copiedCount = 0;

          for (final file in details.files) {
            final sourcePath = file.path;
            final fileName = sourcePath.split(Platform.pathSeparator).last;
            String targetPath = '${targetDir.path}${Platform.pathSeparator}$fileName';

            // Si c'est un doublon, vérifier l'action à effectuer
            if (duplicates.contains(fileName)) {
              final action = actions?[fileName];
              if (action == null || action.type == DuplicateActionType.skip) {
                continue; // Ne pas copier ce fichier
              }

              if (action.type == DuplicateActionType.duplicate && action.newName != null) {
                // Utiliser le nouveau nom
                targetPath = '${targetDir.path}${Platform.pathSeparator}${action.newName}';
              } else if (action.type == DuplicateActionType.replace) {
                // Supprimer l'existant avant de copier
                final source = FileSystemEntity.typeSync(sourcePath);
                if (source == FileSystemEntityType.directory) {
                  await Directory(targetPath).delete(recursive: true);
                } else {
                  await File(targetPath).delete();
                }
              }
            }

            // Copier le fichier ou le dossier
            final source = FileSystemEntity.typeSync(sourcePath);
            if (source == FileSystemEntityType.directory) {
              await _copyDirectory(sourcePath, targetPath);
            } else if (source == FileSystemEntityType.file) {
              await File(sourcePath).copy(targetPath);
            }

            copiedCount++;
          }

          // Recharger le répertoire
          await _viewModel.refresh();

          if (mounted) {
            _showToast('$copiedCount élément(s) copié(s)');
          }
        } catch (e) {
          if (mounted) {
            _showToast('Erreur lors de la copie: $e');
          }
        }
      },
      child: GestureDetector(
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

            // Overlay de drag and drop
            if (_isDragging)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                lucide.LucideIcons.download,
                                size: 56,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Déposer ici pour copier',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'dans ${_dragTargetPath?.split(Platform.pathSeparator).last ?? "ce dossier"}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Dialog pour confirmer le remplacement de fichiers doublons
  Future<Map<String, DuplicateAction>?> _showDuplicateDialog(
    List<String> duplicates,
    Map<String, String> sourcePathMap,
  ) {
    return showDialog<Map<String, DuplicateAction>>(
      context: context,
      builder: (context) => _DuplicateDialog(
        duplicates: duplicates,
        sourcePathMap: sourcePathMap,
      ),
    );
  }

  Future<Map<String, DuplicateAction>?> _resolveDuplicateActionsForExtraction(
    Map<String, String> sourcePathMap,
    String destinationPath,
  ) async {
    if (sourcePathMap.isEmpty) {
      return <String, DuplicateAction>{};
    }

    final duplicates = <String>[];
    for (final name in sourcePathMap.keys) {
      final targetPath = '$destinationPath${Platform.pathSeparator}$name';
      if (FileSystemEntity.typeSync(targetPath) != FileSystemEntityType.notFound) {
        duplicates.add(name);
      }
    }

    if (duplicates.isEmpty) {
      return <String, DuplicateAction>{};
    }
    if (!mounted) return null;
    return _showDuplicateDialog(duplicates, sourcePathMap);
  }

  // Fonction helper pour copier un dossier récursivement
  Future<void> _copyDirectory(String sourcePath, String targetPath) async {
    final sourceDir = Directory(sourcePath);
    final targetDir = Directory(targetPath);

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    await for (final entity in sourceDir.list(recursive: false)) {
      final fileName = entity.path.split(Platform.pathSeparator).last;
      final newPath = '${targetDir.path}${Platform.pathSeparator}$fileName';

      if (entity is Directory) {
        await _copyDirectory(entity.path, newPath);
      } else if (entity is File) {
        await entity.copy(newPath);
      }
    }
  }

  Widget _buildActionBar(ExplorerViewState state) {
    final selectionCount = state.selectedPaths.length;

    if (state.isArchiveView) {
      return _buildArchiveActionBar(state);
    }

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
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
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
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
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

  Widget _buildArchiveActionBar(ExplorerViewState state) {
    final selectionCount = state.selectedPaths.length;
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            ToolbarButton(
              icon: lucide.LucideIcons.copy,
              tooltip: 'Copier depuis l\'archive',
              isActive: !state.isLoading && selectionCount > 0,
              onPressed: state.isLoading || selectionCount == 0
                  ? null
                  : _viewModel.copySelectionToClipboard,
            ),
            const SizedBox(width: 8),
            ToolbarButton(
              icon: lucide.LucideIcons.download,
              tooltip: 'Extraire la sélection',
              isActive: !state.isLoading && selectionCount > 0,
              onPressed: state.isLoading || selectionCount == 0
                  ? null
                  : _promptExtractSelection,
            ),
            const SizedBox(width: 4),
            ToolbarButton(
              icon: lucide.LucideIcons.folderOpen,
              tooltip: 'Extraire toute l\'archive',
              isActive: !state.isLoading,
              onPressed: state.isLoading ? null : _promptExtractArchive,
            ),
            const SizedBox(width: 12),
            Container(
              width: 1,
              height: 24,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(width: 12),
            ToolbarButton(
              icon: lucide.LucideIcons.x,
              tooltip: 'Fermer l archive',
              isActive: !state.isLoading,
              onPressed: state.isLoading ? null : _viewModel.exitArchiveView,
            ),
            const SizedBox(width: 12),
            if (selectionCount > 0) ...[
              Text(
                '$selectionCount sélectionné(s)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      fontSize: 12,
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
    final destination = await _pickDirectoryPath(
      title: 'Deplacer vers...',
      initialPath: _viewModel.state.currentPath,
      confirmLabel: 'Deplacer ici',
    );
    if (destination == null || destination.trim().isEmpty) return;
    await _viewModel.moveSelected(destination.trim());
  }

  Future<void> _promptExtractArchive() async {
    final archivePath = _viewModel.state.archivePath;
    final initialPath = archivePath != null
        ? Directory(archivePath).parent.path
        : _viewModel.state.currentPath;
    final destination = await _pickDirectoryPath(
      title: 'Extraire l archive',
      initialPath: initialPath,
      confirmLabel: 'Extraire ici',
    );
    if (destination == null || destination.trim().isEmpty) return;
    final target = destination.trim();
    final archiveRootPath = _viewModel.state.archiveRootPath;
    if (archiveRootPath == null) return;

    final sourceDir = Directory(archiveRootPath);
    if (!await sourceDir.exists()) {
      if (mounted) {
        _showToast('Archive introuvable');
      }
      return;
    }

    final sourcePathMap = <String, String>{};
    await for (final entity in sourceDir.list(recursive: false, followLinks: false)) {
      final name = entity.path.split(Platform.pathSeparator).last;
      sourcePathMap[name] = entity.path;
    }

    final actions = await _resolveDuplicateActionsForExtraction(
      sourcePathMap,
      target,
    );
    if (actions == null) return;

    await _viewModel.extractArchiveTo(
      target,
      duplicateActions: actions,
    );
  }

  Future<void> _promptExtractSelection() async {
    final archivePath = _viewModel.state.archivePath;
    final initialPath = archivePath != null
        ? Directory(archivePath).parent.path
        : _viewModel.state.currentPath;
    final destination = await _pickDirectoryPath(
      title: 'Extraire la sélection',
      initialPath: initialPath,
      confirmLabel: 'Extraire ici',
    );
    if (destination == null || destination.trim().isEmpty) return;
    final target = destination.trim();
    final entries = _viewModel.state.entries
        .where((entry) => _viewModel.state.selectedPaths.contains(entry.path))
        .toList();
    if (entries.isEmpty) return;

    final sourcePathMap = <String, String>{};
    for (final entry in entries) {
      sourcePathMap[entry.name] = entry.path;
    }

    final actions = await _resolveDuplicateActionsForExtraction(
      sourcePathMap,
      target,
    );
    if (actions == null) return;

    await _viewModel.extractSelectionTo(
      target,
      duplicateActions: actions,
    );
  }

  Future<bool?> _showOpenExtractedPrompt(
    String destinationPath,
    String? message,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          alignment: Alignment.center,
          insetPadding: EdgeInsets.symmetric(
            horizontal: Platform.isMacOS ? 80 : 40,
            vertical: 40,
          ),
          child: AlertDialog(
            title: const Text('Extraction terminee'),
            content: Text(
              message ?? 'Ouvrir le dossier ou les fichiers ont ete extraits ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Plus tard'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Ouvrir'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeletion() async {
    final count = _viewModel.state.selectedPaths.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          alignment: Alignment.center,
          insetPadding: EdgeInsets.symmetric(
            horizontal: Platform.isMacOS ? 80 : 40,
            vertical: 40,
          ),
          child: AlertDialog(
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
          ),
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

    final isArchiveView = _viewModel.state.isArchiveView;
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
        _MenuItem('copyPath', 'Copier le chemin'),
        _MenuItem('openTerminal', 'Ouvrir le terminal ici'),
      ]);
      if (!isArchiveView) {
        items.add(const _MenuItem('cut', 'Couper'));
      }
    }

    final pasteDestination = entry != null && entry.isDirectory
        ? entry.path
        : null;
    if (_viewModel.canPaste && !isArchiveView) {
      items.add(
        _MenuItem(
          'paste',
          pasteDestination != null ? 'Coller dans ce dossier' : 'Coller ici',
        ),
      );
    }

    if (entry != null && !isArchiveView) {
      items.addAll(const [
        _MenuItem('duplicate', 'Dupliquer'),
        _MenuItem('move', 'Deplacer vers...'),
        _MenuItem('rename', 'Renommer'),
        _MenuItem('delete', 'Supprimer'),
      ]);
    } else if (entry == null && !isArchiveView) {
      items.add(const _MenuItem('newFolder', 'Nouveau dossier'));
    }
    if (_viewModel.state.selectedPaths.isNotEmpty && !isArchiveView) {
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
        return Dialog(
          alignment: Alignment.center,
          insetPadding: EdgeInsets.symmetric(
            horizontal: Platform.isMacOS ? 80 : 40,
            vertical: 40,
          ),
          child: AlertDialog(
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
          ),
        );
      },
    );
  }

  Future<String?> _pickDirectoryPath({
    required String title,
    required String initialPath,
    String? confirmLabel,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => MiniExplorerDialog(
        title: title,
        mode: MiniExplorerPickerMode.directory,
        initialPath: initialPath,
        confirmLabel: confirmLabel,
        showFiles: false,
      ),
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
    final handleSelection = selectionMode
        ? () => _viewModel.toggleSelection(entry)
        : () => _viewModel.selectSingle(entry);

    final tile = FileEntryTile(
      entry: entry,
      viewMode: viewMode,
      selectionMode: selectionMode,
      isSelected: _viewModel.isSelected(entry),
      onToggleSelection: handleSelection,
      onOpen: () => _handleEntryTap(entry),
      onContextMenu: (position) => _showContextMenu(entry, position),
      enableDrop: !_viewModel.state.isArchiveView,
    );
    final draggingTile = Opacity(
      opacity: 0.35,
      child: FileEntryTile(
        entry: entry,
        viewMode: viewMode,
        selectionMode: selectionMode,
        isSelected: _viewModel.isSelected(entry),
        onToggleSelection: handleSelection,
        onOpen: () => _handleEntryTap(entry),
        onContextMenu: (position) => _showContextMenu(entry, position),
        enableDrop: !_viewModel.state.isArchiveView,
      ),
    );

    final draggable = Draggable<List<FileEntry>>(
      data: selectedEntries,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _DragFeedback(entry: entry),
      childWhenDragging: draggingTile,
      child: tile,
    );

    if (!entry.isDirectory || _viewModel.state.isArchiveView) return draggable;

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
      scrollController: _scrollController,
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
        // Plus de colonnes et espacement réduit pour un meilleur affichage
        final crossAxisCount = (maxWidth / 160).clamp(3, 8).floor();

        return GridView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16, // Espacement horizontal réduit
            mainAxisSpacing: 16, // Espacement vertical réduit
            childAspectRatio: 0.75, // Ratio ajusté pour les previews 120x120
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
        label: 'Applications',
        icon: lucide.LucideIcons.appWindow,
        path: SpecialLocations.applications,
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
    final physicalPaths = <String>{};
    final cloudPaths = <String>[];

    // 1. Volumes physiques montés dans /Volumes
    final volumesDir = Directory('/Volumes');
    if (volumesDir.existsSync()) {
      for (final entity in volumesDir.listSync()) {
        physicalPaths.add(entity.path);
      }
    }

    // 2. Services cloud - Chemins typiques sur macOS
    final home = Platform.environment['HOME'] ?? '';
    if (home.isNotEmpty) {
      final potentialCloudPaths = [
        // iCloud Drive
        '$home/Library/Mobile Documents/com~apple~CloudDocs',
        // Google Drive (nouveau format CloudStorage)
        '$home/Library/CloudStorage',
        // OneDrive (plusieurs variantes)
        '$home/OneDrive',
        '$home/OneDrive - Personal',
        // Dropbox
        '$home/Dropbox',
      ];

      for (final cloudPath in potentialCloudPaths) {
        final dir = Directory(cloudPath);

        // Pour CloudStorage, lister les sous-dossiers (GoogleDrive, OneDrive, etc.)
        if (cloudPath.contains('CloudStorage') && dir.existsSync()) {
          try {
            for (final entity in dir.listSync()) {
              if (entity is Directory) {
                cloudPaths.add(entity.path);
              }
            }
          } catch (_) {
            // Ignorer les erreurs de permission
          }
        } else if (dir.existsSync()) {
          cloudPaths.add(cloudPath);
        }
      }
    }

    final volumes = <_VolumeInfo>[];

    // Ajouter les volumes physiques
    for (final path in physicalPaths) {
      final info = _getVolumeInfo(path);
      if (info != null) {
        volumes.add(info);
      }
    }

    // Ajouter les services cloud (avec info simplifiée)
    for (final path in cloudPaths) {
      final info = _getCloudInfo(path);
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

      // Extract label from mount point with cloud service detection
      String label = _extractVolumeLabel(mountPoint);

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

  /// Crée une info de volume pour un service cloud
  /// Utilise le disque système pour les stats mais avec un label cloud
  _VolumeInfo? _getCloudInfo(String path) {
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) return null;

      // Obtenir les infos du disque système (les dossiers cloud sont sur le disque local)
      final result = Process.runSync('df', ['-Pk', path]);
      if (result.exitCode != 0) return null;

      final lines = (result.stdout as String)
          .trim()
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      if (lines.length < 2) return null;

      final line = lines.last;
      final parts = line.split(RegExp(r'\s+'));

      if (parts.length < 6) return null;

      final totalKilobytes = double.tryParse(parts[1]);
      if (totalKilobytes == null || totalKilobytes <= 0) return null;

      final capacityStr = parts[4];
      final capacityPercent =
          double.tryParse(capacityStr.replaceAll('%', '')) ?? 0;
      final usage = capacityPercent / 100.0;

      // Utiliser le label cloud au lieu du mount point
      final label = _extractVolumeLabel(path);
      final totalBytes = (totalKilobytes * 1024).toInt();

      return _VolumeInfo(
        label: label,
        path: path, // Utiliser le chemin cloud, pas le mount point système
        usage: usage,
        totalBytes: totalBytes,
      );
    } catch (_) {
      return null;
    }
  }

  /// Extrait un nom lisible pour un volume ou service cloud
  String _extractVolumeLabel(String path) {
    final normalized = path.trim();
    if (normalized == '/' || normalized == '/System/Volumes/Data') {
      return 'Racine';
    }
    // Détection des services cloud avec emojis et noms clairs
    if (normalized.contains('com~apple~CloudDocs')) {
      return 'iCloud Drive';
    }
    if (normalized.contains('GoogleDrive')) {
      // Extraire l'email si présent: GoogleDrive-email@gmail.com
      final match = RegExp(r'GoogleDrive-(.+?)(?:/|$)').firstMatch(normalized);
      if (match != null) {
        final email = match.group(1) ?? '';
        return 'Google Drive ($email)';
      }
      return 'Google Drive';
    }
    if (normalized.contains('OneDrive')) {
      if (normalized.contains('Personal')) {
        return 'OneDrive Personal';
      } else if (normalized.contains('Business')) {
        return 'OneDrive Business';
      }
      return 'OneDrive';
    }
    if (normalized.contains('Dropbox')) {
      return 'Dropbox';
    }

    // Pour les volumes physiques, extraire le dernier segment du chemin
    final label = normalized
        .split(Platform.pathSeparator)
        .where((p) => p.isNotEmpty)
        .lastWhere((p) => p.isNotEmpty, orElse: () => normalized);

    return label;
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

