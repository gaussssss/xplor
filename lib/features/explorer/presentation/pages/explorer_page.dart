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
import '../services/volume_info_service.dart';

part 'explorer/support.dart';
part 'explorer/sidebar.dart';
part 'explorer/dialogs.dart';
part 'explorer/actions.dart';
part 'explorer/content.dart';
part 'explorer/navigation.dart';

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
  late final List<VolumeInfo> _volumes;
  late final VolumeInfoService _volumeInfoService;
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
    final initialPath =
        Platform.environment['HOME'] ?? SpecialLocations.desktop;
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
    _volumeInfoService = VolumeInfoService();
    _volumes = _volumeInfoService.readVolumes();
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
                                      width: _isSidebarCollapsed
                                          ? 70
                                          : _sidebarWidth,
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
                                            () => _isSidebarCollapsed =
                                                !_isSidebarCollapsed,
                                          );
                                        },
                                        onSettingsClosed: _loadSelectionMode,
                                        isLight: themeProvider.isLight,
                                        currentPalette:
                                            themeProvider.currentPalette,
                                        onToggleLight:
                                            themeProvider.setLightMode,
                                        onPaletteSelected:
                                            themeProvider.setPalette,
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
                                              _sidebarWidth =
                                                  (_sidebarWidth +
                                                          details.delta.dx)
                                                      .clamp(
                                                        180.0,
                                                        400.0,
                                                      ); // Min 180px, Max 400px
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
                                                color: Colors.white.withValues(
                                                  alpha: 0.1,
                                                ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            BreadcrumbBar(
                                              path: state.currentPath,
                                              onNavigate: (path) => _viewModel
                                                  .loadDirectory(path),
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
                      child: Container(color: Colors.transparent),
                    ),
                  ),
              ], // Stack children
            ), // Stack
          ), // Scaffold body
        );
      },
    );
  }
}
