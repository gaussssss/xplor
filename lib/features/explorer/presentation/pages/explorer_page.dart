import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:another_flushbar/flushbar.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../core/constants/special_locations.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/color_palettes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/mini_explorer_dialog.dart';
import '../../../../core/widgets/animated_background.dart';
import '../widgets/disks_page.dart';
import '../models/sort_config.dart';
import '../models/group_section.dart';
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
import '../../../../core/widgets/appearance_settings_dialog_v2.dart'
    as settings;
import '../../../settings/presentation/pages/about_page.dart';
import '../../../settings/presentation/pages/terms_of_service_page.dart';
import '../../../help/presentation/pages/help_page.dart';
import '../../domain/entities/duplicate_action.dart';
import '../services/volume_info_service.dart';
import '../../../onboarding/data/onboarding_service.dart';

part 'explorer/support.dart';
part 'explorer/sidebar.dart';
part 'explorer/dialogs.dart';
part 'explorer/actions.dart';
part 'explorer/content.dart';
part 'explorer/navigation.dart';

const String _fallbackAppVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.0.0',
);
const String _fallbackBuildNumber = String.fromEnvironment(
  'BUILD_NUMBER',
  defaultValue: 'dev',
);

class ExplorerPage extends StatefulWidget {
  const ExplorerPage({super.key});

  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

class _NavigateBackIntent extends Intent {
  const _NavigateBackIntent();
}

class _NavigateForwardIntent extends Intent {
  const _NavigateForwardIntent();
}

class _NavigateUpIntent extends Intent {
  const _NavigateUpIntent();
}

class _RefreshIntent extends Intent {
  const _RefreshIntent();
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _OpenSelectionIntent extends Intent {
  const _OpenSelectionIntent();
}

class _DeleteSelectionIntent extends Intent {
  const _DeleteSelectionIntent();
}

class _RenameSelectionIntent extends Intent {
  const _RenameSelectionIntent();
}

class _NewFolderIntent extends Intent {
  const _NewFolderIntent();
}

class _CopySelectionIntent extends Intent {
  const _CopySelectionIntent();
}

class _CutSelectionIntent extends Intent {
  const _CutSelectionIntent();
}

class _PasteSelectionIntent extends Intent {
  const _PasteSelectionIntent();
}

class _SelectAllIntent extends Intent {
  const _SelectAllIntent();
}

class _ClearSelectionIntent extends Intent {
  const _ClearSelectionIntent();
}

class _ExplorerShortcutAction<T extends Intent> extends ContextAction<T> {
  _ExplorerShortcutAction({
    required this.onInvoke,
    required this.isEnabledCallback,
  });

  final Object? Function() onInvoke;
  final bool Function() isEnabledCallback;

  @override
  bool isEnabled(T intent, [BuildContext? context]) => isEnabledCallback();

  @override
  Object? invoke(T intent, [BuildContext? context]) => onInvoke();
}

class _ExplorerPageState extends State<ExplorerPage> {
  static final Map<ShortcutActivator, Intent> _shortcuts =
      <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
            const _NavigateBackIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true):
            const _NavigateForwardIntent(),
        const SingleActivator(LogicalKeyboardKey.bracketLeft, meta: true):
            const _NavigateBackIntent(),
        const SingleActivator(LogicalKeyboardKey.bracketRight, meta: true):
            const _NavigateForwardIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true):
            const _NavigateUpIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowUp, meta: true):
            const _NavigateUpIntent(),
        const SingleActivator(LogicalKeyboardKey.browserBack):
            const _NavigateBackIntent(),
        const SingleActivator(LogicalKeyboardKey.browserForward):
            const _NavigateForwardIntent(),
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true):
            const _RefreshIntent(),
        const SingleActivator(LogicalKeyboardKey.keyR, control: true):
            const _RefreshIntent(),
        const SingleActivator(LogicalKeyboardKey.f5): const _RefreshIntent(),
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
            const _FocusSearchIntent(),
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            const _FocusSearchIntent(),
        const SingleActivator(LogicalKeyboardKey.enter):
            const _OpenSelectionIntent(),
        const SingleActivator(LogicalKeyboardKey.numpadEnter):
            const _OpenSelectionIntent(),
        const SingleActivator(LogicalKeyboardKey.delete):
            const _DeleteSelectionIntent(),
        const SingleActivator(LogicalKeyboardKey.backspace):
            const _DeleteSelectionIntent(),
        const SingleActivator(LogicalKeyboardKey.f2):
            const _RenameSelectionIntent(),
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true, shift: true):
            const _NewFolderIntent(),
        const SingleActivator(
          LogicalKeyboardKey.keyN,
          control: true,
          shift: true,
        ): const _NewFolderIntent(),
        const SingleActivator(LogicalKeyboardKey.keyC, meta: true):
            const _CopySelectionIntent(),
        const SingleActivator(LogicalKeyboardKey.keyC, control: true):
            const _CopySelectionIntent(),
        const SingleActivator(LogicalKeyboardKey.keyX, meta: true):
            const _CutSelectionIntent(),
        const SingleActivator(LogicalKeyboardKey.keyX, control: true):
            const _CutSelectionIntent(),
        const SingleActivator(LogicalKeyboardKey.keyV, meta: true):
            const _PasteSelectionIntent(),
        const SingleActivator(LogicalKeyboardKey.keyV, control: true):
            const _PasteSelectionIntent(),
        const SingleActivator(LogicalKeyboardKey.keyA, meta: true):
            const _SelectAllIntent(),
        const SingleActivator(LogicalKeyboardKey.keyA, control: true):
            const _SelectAllIntent(),
        const SingleActivator(LogicalKeyboardKey.escape):
            const _ClearSelectionIntent(),
      };
  late final ExplorerViewModel _viewModel;
  late final TextEditingController _pathController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final FocusNode _shortcutsFocusNode;
  late final ScrollController _scrollController;
  late final List<_NavItem> _favoriteItems;
  late final List<_NavItem> _systemItems;
  late final List<_NavItem> _quickItems;
  late final List<_TagItem> _tagItems;
  int? _lastSelectedIndex;
  late final List<VolumeInfo> _volumes;
  late final VolumeInfoService _volumeInfoService;
  String? _lastStatusMessage;
  String? _lastPendingOpenPath;
  bool _contextMenuOpen = false;
  bool _isSearchExpanded = false;
  bool _isToastShowing = false;
  bool _isSidebarCollapsed = false;
  bool _isMultiSelectionMode = false;
  bool _didInitialAutoRefresh = false;
  bool _hasLoggedVersion = false;
  double _sidebarWidth = 240.0; // Largeur du sidebar (redimensionnable)
  String _lastPath = ''; // Pour détecter les changements de dossier

  // État du drag and drop
  bool _isDragging = false;
  String? _dragTargetPath; // Le dossier cible pour le drop

  @override
  void initState() {
    super.initState();
    // Utiliser le vrai HOME de l'utilisateur au lieu du chemin sandbox
    const initialPath = SpecialLocations.disks;
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
    _viewModel.registerNavigationChannel();
    _pathController = TextEditingController(text: initialPath);
    _searchController = TextEditingController(text: '');
    _searchFocusNode = FocusNode();
    _shortcutsFocusNode = FocusNode(debugLabel: 'ExplorerShortcuts');
    _scrollController = ScrollController();
    _lastPath = initialPath;
    _favoriteItems = _buildFavoriteItems();
    _systemItems = _buildSystemItems(initialPath);
    _quickItems = _buildQuickItems();
    _tagItems = _buildTags();
    _volumeInfoService = VolumeInfoService();
    _volumes = _volumeInfoService.readVolumes();
    _logVersionInfo();
    _initializeExplorer(initialPath);
    _loadSelectionMode();
    _loadPreferredRootPath();
    _scheduleInitialRefresh();
  }

  Future<void> _initializeExplorer(String fallbackPath) async {
    await _viewModel.bootstrap();
    final startupPath = await _viewModel.resolveStartupPath(fallbackPath);
    if (!mounted) return;
    _pathController.text = startupPath;
    _lastPath = startupPath;
    await _viewModel.loadDirectory(startupPath);
  }

  Widget _buildSearchToggle() {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isLight = theme.brightness == Brightness.light;
    final textColor = onSurface.withValues(alpha: isLight ? 0.9 : 0.95);
    final hintColor = onSurface.withValues(alpha: isLight ? 0.5 : 0.6);
    final iconColor = onSurface.withValues(alpha: isLight ? 0.75 : 0.8);
    final bgColor = isLight
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: _isSearchExpanded ? 260 : 48,
      child: _isSearchExpanded
          ? Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: onSurface.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: TextField(
                focusNode: _searchFocusNode,
                controller: _searchController,
                onChanged: _viewModel.updateSearch,
                onSubmitted: _viewModel.updateSearch,
                style: TextStyle(fontSize: 14, color: textColor),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    lucide.LucideIcons.search,
                    color: iconColor,
                    size: 18,
                  ),
                  hintText: 'Recherche',
                  hintStyle: TextStyle(color: hintColor, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      lucide.LucideIcons.x,
                      color: iconColor,
                      size: 16,
                    ),
                    onPressed: () {
                      setState(() => _isSearchExpanded = false);
                      _searchFocusNode.unfocus();
                    },
                    tooltip: 'Fermer la recherche',
                  ),
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
    _shortcutsFocusNode.dispose();
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

  Future<void> _loadPreferredRootPath() async {
    if (_viewModel.state.currentPath == SpecialLocations.disks) return;
    final preferred = await OnboardingService.getPreferredRootPath();
    if (preferred == null || preferred.trim().isEmpty) return;
    if (!Directory(preferred).existsSync()) return;
    if (!mounted) return;
    if (_viewModel.state.currentPath == preferred) return;
    _pathController.text = preferred;
    await _viewModel.loadDirectory(preferred);
  }

  void _scheduleInitialRefresh() {
    if (_didInitialAutoRefresh) return;
    _didInitialAutoRefresh = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _viewModel.refresh();
    });
  }

  void _refreshVolumes() {
    setState(() {
      _volumes = _volumeInfoService.readVolumes();
    });
  }

  Future<void> _logVersionInfo() async {
    if (_hasLoggedVersion) return;
    _hasLoggedVersion = true;
    try {
      final info = await PackageInfo.fromPlatform();
      debugPrint('[Xplor] version ${info.version}+${info.buildNumber}');
    } catch (e) {
      debugPrint(
        '[Xplor] package_info_plus unavailable, using fallback: $_fallbackAppVersion+$_fallbackBuildNumber',
      );
      debugPrint('[Xplor] version $_fallbackAppVersion+$_fallbackBuildNumber');
    }
  }

  bool _isTextInputFocused() {
    final focus = FocusManager.instance.primaryFocus;
    final context = focus?.context;
    if (context == null) return false;
    final widget = context.widget;
    if (widget is EditableText) return true;
    return context.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  bool _shouldHandleShortcut({bool allowWhenTextInput = false}) {
    if (_contextMenuOpen) return false;
    if (!allowWhenTextInput && _isTextInputFocused()) return false;
    return true;
  }

  Action<Intent> _buildShortcutAction(
    Object? Function() handler, {
    bool allowWhenTextInput = false,
    bool Function()? isEnabled,
  }) {
    return _ExplorerShortcutAction(
      onInvoke: handler,
      isEnabledCallback: () {
        if (!_shouldHandleShortcut(allowWhenTextInput: allowWhenTextInput)) {
          return false;
        }
        return isEnabled == null ? true : isEnabled();
      },
    );
  }

  Map<Type, Action<Intent>> _buildShortcutActions(ExplorerViewState state) {
    return <Type, Action<Intent>>{
      _NavigateBackIntent: _buildShortcutAction(
        () => _viewModel.goBack(),
        isEnabled: () => !state.isLoading && _viewModel.canGoBack,
      ),
      _NavigateForwardIntent: _buildShortcutAction(
        () => _viewModel.goForward(),
        isEnabled: () => !state.isLoading && _viewModel.canGoForward,
      ),
      _NavigateUpIntent: _buildShortcutAction(
        () => _viewModel.goToParent(),
        isEnabled: () => !state.isLoading && !_viewModel.isAtRoot,
      ),
      _RefreshIntent: _buildShortcutAction(
        () => _viewModel.refresh(),
        isEnabled: () => !state.isLoading,
      ),
      _FocusSearchIntent: _buildShortcutAction(
        () => _focusSearch(),
        allowWhenTextInput: true,
      ),
      _OpenSelectionIntent: _buildShortcutAction(
        () => _openSelection(),
        isEnabled: () => !state.isLoading,
      ),
      _DeleteSelectionIntent: _buildShortcutAction(
        () => _confirmDeletion(),
        isEnabled: () => !state.isLoading && state.selectedPaths.isNotEmpty,
      ),
      _RenameSelectionIntent: _buildShortcutAction(
        () => _promptRename(),
        isEnabled: () => !state.isLoading && state.selectedPaths.length == 1,
      ),
      _NewFolderIntent: _buildShortcutAction(
        () => _promptCreateFolder(),
        isEnabled: () => !state.isLoading,
      ),
      _CopySelectionIntent: _buildShortcutAction(
        () => _viewModel.copySelectionToClipboard(),
        isEnabled: () => !state.isLoading && state.selectedPaths.isNotEmpty,
      ),
      _CutSelectionIntent: _buildShortcutAction(
        () => _viewModel.cutSelectionToClipboard(),
        isEnabled: () => !state.isLoading && state.selectedPaths.isNotEmpty,
      ),
      _PasteSelectionIntent: _buildShortcutAction(
        () => _pasteClipboardWithRename(),
        isEnabled: () => !state.isLoading && _viewModel.canPaste,
      ),
      _SelectAllIntent: _buildShortcutAction(
        () => _viewModel.selectAllVisible(force: true),
        isEnabled: () =>
            !state.isLoading && _viewModel.visibleEntries.isNotEmpty,
      ),
      _ClearSelectionIntent: _buildShortcutAction(
        () => _clearSelectionOrSearch(),
        allowWhenTextInput: true,
      ),
    };
  }

  void _focusSearch() {
    if (!_isSearchExpanded) {
      setState(() => _isSearchExpanded = true);
    }
    Future.microtask(() => _searchFocusNode.requestFocus());
  }

  void _openSelection() {
    final selected = _viewModel.state.selectedPaths;
    if (selected.isEmpty) return;
    final entries = _viewModel.visibleEntries;
    FileEntry? target;
    for (final entry in entries) {
      if (selected.contains(entry.path)) {
        target = entry;
        break;
      }
    }
    if (target != null) {
      _viewModel.open(target);
    }
  }

  void _clearSelectionOrSearch() {
    if (_isSearchExpanded && _searchFocusNode.hasFocus) {
      setState(() => _isSearchExpanded = false);
      _searchFocusNode.unfocus();
      return;
    }
    _viewModel.clearSelection();
  }

  void _handleMouseNavigation(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.mouse) return;
    if (_contextMenuOpen) return;
    final buttons = event.buttons;
    if ((buttons & kBackMouseButton) != 0 && _viewModel.canGoBack) {
      _viewModel.goBack();
      return;
    }
    if ((buttons & kForwardMouseButton) != 0 && _viewModel.canGoForward) {
      _viewModel.goForward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mergedListenable = Listenable.merge(
      [_viewModel, FocusManager.instance],
    );
    return AnimatedBuilder(
      animation: mergedListenable,
      builder: (context, _) {
        final themeProvider = context.watch<ThemeProvider>();
        final hasBgImage = themeProvider.hasBackgroundImage;
        final bgImage = themeProvider.backgroundImageProvider;
        final bgImageKey = themeProvider.backgroundImagePath;
        final isLight = themeProvider.isLight;
        final theme = Theme.of(context);
        final bgColor = hasBgImage
            ? (isLight
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.black.withValues(alpha: 0.5))
            : theme.colorScheme.surface;
        final adjustedSurface = hasBgImage
            ? (isLight
                  ? Colors.white.withValues(alpha: 0.98)
                  : Colors.black.withValues(alpha: 0.75))
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

        final shortcutMap = _isTextInputFocused()
            ? const <ShortcutActivator, Intent>{}
            : _shortcuts;
        return Theme(
          data: themed,
          child: Shortcuts(
            shortcuts: shortcutMap,
            child: Actions(
              actions: _buildShortcutActions(state),
              child: Focus(
                autofocus: true,
                focusNode: _shortcutsFocusNode,
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: _handleMouseNavigation,
                  child: Scaffold(
                    body: Stack(
                      children: [
                        // Background image
                        if (hasBgImage && bgImage != null)
                          AnimatedBackground(
                            image: bgImage,
                            imageKey: bgImageKey,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                selectedTags:
                                                    _viewModel.selectedTags,
                                                selectedTypes:
                                                    _viewModel.selectedTypes,
                                                onNavigate:
                                                    _viewModel.loadDirectory,
                                                onTagToggle:
                                                    _viewModel.toggleTag,
                                                onTypeToggle:
                                                    _viewModel.toggleType,
                                                onToggleCollapse: () {
                                                  setState(
                                                    () => _isSidebarCollapsed =
                                                        !_isSidebarCollapsed,
                                                  );
                                                },
                                                onSettingsClosed:
                                                    _loadSelectionMode,
                                                isLight: themeProvider.isLight,
                                                currentPalette: themeProvider
                                                    .currentPalette,
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
                                                cursor: SystemMouseCursors
                                                    .resizeColumn,
                                                child: GestureDetector(
                                                  onPanUpdate: (details) {
                                                    setState(() {
                                                      _sidebarWidth =
                                                          (_sidebarWidth +
                                                                  details
                                                                      .delta
                                                                      .dx)
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
                                                        color: Colors.white
                                                            .withValues(
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
                                                level:
                                                    GlassPanelLevel.secondary,
                                                child: _buildToolbar(state),
                                              ),
                                              const SizedBox(height: 8),
                                              if (state.currentPath !=
                                                  SpecialLocations.disks) ...[
                                                GlassPanelV2(
                                                  level:
                                                      GlassPanelLevel.secondary,
                                                  child: _buildActionBar(state),
                                                ),
                                                const SizedBox(height: 8),
                                              ],
                                              Expanded(
                                                child: GlassPanelV2(
                                                  level:
                                                      GlassPanelLevel.primary,
                                                  padding: const EdgeInsets.all(
                                                    0,
                                                  ),
                                                  child: _buildContent(
                                                    state,
                                                    entries,
                                                  ),
                                                ),
                                              ),
                                              if (state.currentPath !=
                                                  SpecialLocations.disks) ...[
                                                const SizedBox(height: 8),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                      ),
                                                  child: _StatsFooter(
                                                    state: state,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                              ],
                                              GlassPanelV2(
                                                level: GlassPanelLevel.secondary,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10,
                                                    ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    BreadcrumbBar(
                                                      path: _viewModel
                                                          .displayPath,
                                                      onNavigate: (path) =>
                                                          _viewModel
                                                              .loadDirectory(
                                                                path,
                                                              ),
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
