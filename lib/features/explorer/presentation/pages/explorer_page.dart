import 'dart:io';
import 'dart:ui';

import 'package:another_flushbar/flushbar.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';
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

// Enum pour les actions de gestion des doublons
enum DuplicateActionType {
  replace,   // Remplacer le fichier existant
  duplicate, // Créer une copie avec un nouveau nom
  skip,      // Ne pas copier ce fichier
}

// Classe pour stocker l'action à effectuer pour un doublon
class DuplicateAction {
  const DuplicateAction({
    required this.type,
    this.newName,
  });

  final DuplicateActionType type;
  final String? newName; // Utilisé si type == duplicate

  DuplicateAction copyWith({
    DuplicateActionType? type,
    String? newName,
  }) {
    return DuplicateAction(
      type: type ?? this.type,
      newName: newName ?? this.newName,
    );
  }
}

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
  bool _contextMenuOpen = false;
  bool _isSearchExpanded = false;
  bool _isToastShowing = false;
  bool _isSidebarCollapsed = false;
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

    final selectionMode = true; // Multi-selection always enabled
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
    await _viewModel.extractArchiveTo(destination.trim());
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
    await _viewModel.extractSelectionTo(destination.trim());
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

    final tile = FileEntryTile(
      entry: entry,
      viewMode: viewMode,
      selectionMode: selectionMode,
      isSelected: _viewModel.isSelected(entry),
      onToggleSelection: () => _viewModel.toggleSelection(entry),
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
        onToggleSelection: () => _viewModel.toggleSelection(entry),
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

class _MenuItem {
  const _MenuItem(this.value, this.label);
  final String value;
  final String label;
  
  bool get enabled => true;
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
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      const AppearanceSettingsDialogV2(),
                                );
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
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => const AppearanceSettingsDialogV2(),
                      );
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
class _DuplicateDialog extends StatefulWidget {
  const _DuplicateDialog({
    required this.duplicates,
    required this.sourcePathMap,
  });

  final List<String> duplicates;
  final Map<String, String> sourcePathMap;

  @override
  State<_DuplicateDialog> createState() => _DuplicateDialogState();
}

class _DuplicateDialogState extends State<_DuplicateDialog> {
  late final Map<String, TextEditingController> _nameControllers;
  late final Map<String, DuplicateActionType?> _selectedActions;
  bool _applyToAll = false;
  DuplicateActionType? _batchAction;

  @override
  void initState() {
    super.initState();
    _nameControllers = {};
    _selectedActions = {};

    for (final fileName in widget.duplicates) {
      _nameControllers[fileName] = TextEditingController(text: _generateDuplicateName(fileName));
      _selectedActions[fileName] = null;
    }
  }

  @override
  void dispose() {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _generateDuplicateName(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1) {
      return '$fileName copie';
    }
    final name = fileName.substring(0, lastDot);
    final ext = fileName.substring(lastDot);
    return '$name copie$ext';
  }

  void _handleConfirm() {
    final actions = <String, DuplicateAction>{};

    if (_applyToAll && _batchAction != null) {
      // Mode batch: appliquer la même action à tous
      for (final fileName in widget.duplicates) {
        if (_batchAction == DuplicateActionType.duplicate) {
          actions[fileName] = DuplicateAction(
            type: _batchAction!,
            newName: _nameControllers[fileName]!.text,
          );
        } else {
          actions[fileName] = DuplicateAction(type: _batchAction!);
        }
      }
    } else {
      // Mode individuel: utiliser les actions spécifiques de chaque fichier
      for (final fileName in widget.duplicates) {
        final actionType = _selectedActions[fileName];
        if (actionType != null) {
          if (actionType == DuplicateActionType.duplicate) {
            actions[fileName] = DuplicateAction(
              type: actionType,
              newName: _nameControllers[fileName]!.text,
            );
          } else {
            actions[fileName] = DuplicateAction(type: actionType);
          }
        } else {
          // Aucune action sélectionnée = skip par défaut
          actions[fileName] = const DuplicateAction(type: DuplicateActionType.skip);
        }
      }
    }

    Navigator.pop(context, actions);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = context.read<ThemeProvider>();
    final isLight = themeProvider.isLight;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550, maxHeight: 700),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  children: [
                    Icon(
                      lucide.LucideIcons.alertTriangle,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Fichiers existants',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  '${widget.duplicates.length} fichier(s) existent déjà. Choisissez une action:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // Option "Appliquer à tous"
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isLight ? Colors.black : Colors.white).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _applyToAll,
                            onChanged: (value) {
                              setState(() {
                                _applyToAll = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              'Appliquer la même action à tous les fichiers',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_applyToAll) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const SizedBox(width: 40),
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Remplacer'),
                                    selected: _batchAction == DuplicateActionType.replace,
                                    onSelected: (selected) {
                                      setState(() {
                                        _batchAction = selected ? DuplicateActionType.replace : null;
                                      });
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Dupliquer'),
                                    selected: _batchAction == DuplicateActionType.duplicate,
                                    onSelected: (selected) {
                                      setState(() {
                                        _batchAction = selected ? DuplicateActionType.duplicate : null;
                                      });
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Ne pas copier'),
                                    selected: _batchAction == DuplicateActionType.skip,
                                    onSelected: (selected) {
                                      setState(() {
                                        _batchAction = selected ? DuplicateActionType.skip : null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Liste des fichiers
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: (isLight ? Colors.black : Colors.white).withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.onSurface.withValues(alpha: 0.1),
                      ),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.duplicates.length,
                      itemBuilder: (context, index) {
                        final fileName = widget.duplicates[index];
                        final selectedAction = _selectedActions[fileName];

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: index < widget.duplicates.length - 1
                                  ? BorderSide(
                                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                                    )
                                  : BorderSide.none,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nom du fichier
                              Row(
                                children: [
                                  Icon(
                                    lucide.LucideIcons.file,
                                    size: 16,
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      fileName,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              if (!_applyToAll) ...[
                                const SizedBox(height: 8),
                                // Actions individuelles
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    ChoiceChip(
                                      label: const Text('Remplacer'),
                                      selected: selectedAction == DuplicateActionType.replace,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedActions[fileName] = selected
                                              ? DuplicateActionType.replace
                                              : null;
                                        });
                                      },
                                    ),
                                    ChoiceChip(
                                      label: const Text('Dupliquer'),
                                      selected: selectedAction == DuplicateActionType.duplicate,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedActions[fileName] = selected
                                              ? DuplicateActionType.duplicate
                                              : null;
                                        });
                                      },
                                    ),
                                    ChoiceChip(
                                      label: const Text('Ne pas copier'),
                                      selected: selectedAction == DuplicateActionType.skip,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedActions[fileName] = selected
                                              ? DuplicateActionType.skip
                                              : null;
                                        });
                                      },
                                    ),
                                  ],
                                ),

                                // Champ de renommage si "Dupliquer" est sélectionné
                                if (selectedAction == DuplicateActionType.duplicate) ...[
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _nameControllers[fileName],
                                    decoration: InputDecoration(
                                      labelText: 'Nouveau nom',
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      isDense: true,
                                    ),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Boutons d'action
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _handleConfirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                      ),
                      child: const Text('Confirmer'),
                    ),
                  ],
                ),
              ],
            ),
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
