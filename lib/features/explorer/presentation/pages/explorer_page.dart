import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
import '../widgets/glass_panel.dart';
import '../widgets/sidebar_section.dart';
import '../widgets/toolbar_button.dart';

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

  @override
  void initState() {
    super.initState();
    final initialPath = Directory.current.path;
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
                prefixIcon: const Icon(LucideIcons.search),
                hintText: 'Recherche',
                suffixIcon: IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () {
                    setState(() => _isSearchExpanded = false);
                    _searchFocusNode.unfocus();
                  },
                  tooltip: 'Fermer la recherche',
                ),
              ),
            )
          : ToolbarButton(
              icon: LucideIcons.search,
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

        return Scaffold(
          body: Container(
            color: Theme.of(context).colorScheme.background,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 240,
                      child: _Sidebar(
                        favoriteItems: _favoriteItems,
                        systemItems: _systemItems,
                        quickItems: _quickItems,
                        tags: _tagItems,
                        volumes: _volumes,
                        recentPaths: state.recentPaths,
                        selectedTag: _viewModel.selectedTag,
                        onNavigate: _viewModel.loadDirectory,
                        onTagSelected: (tag) => _viewModel.setTagFilter(
                          tag == _viewModel.selectedTag ? null : tag,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GlassPanel(child: _buildToolbar(state)),
                          const SizedBox(height: 12),
                          GlassPanel(child: _buildActionBar(state)),
                          const SizedBox(height: 12),
                          Expanded(
                            child: GlassPanel(
                              padding: const EdgeInsets.all(0),
                              child: _buildContent(state, entries),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _StatsFooter(state: state),
                          ),
                          const SizedBox(height: 12),
                          GlassPanel(
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolbar(ExplorerViewState state) {
    return Row(
      children: [
        ToolbarButton(
          icon: LucideIcons.arrowLeft,
          tooltip: 'Arriere',
          onPressed: state.isLoading || !_viewModel.canGoBack
              ? null
              : _viewModel.goBack,
        ),
        const SizedBox(width: 8),
        ToolbarButton(
          icon: LucideIcons.arrowRight,
          tooltip: 'Avant',
          onPressed: state.isLoading || !_viewModel.canGoForward
              ? null
              : _viewModel.goForward,
        ),
        const SizedBox(width: 8),
        ToolbarButton(
          icon: LucideIcons.history,
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
          icon: LucideIcons.refreshCw,
          tooltip: 'Rafraichir',
          onPressed: state.isLoading ? null : _viewModel.refresh,
        ),
        const SizedBox(width: 12),
        ToolbarButton(
          icon: LucideIcons.list,
          tooltip: 'Vue liste',
          isActive: state.viewMode == ExplorerViewMode.list,
          onPressed: () => _viewModel.setViewMode(ExplorerViewMode.list),
        ),
        const SizedBox(width: 8),
        ToolbarButton(
          icon: LucideIcons.grid,
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
              const Icon(LucideIcons.alertCircle, size: 48),
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
              Center(child: Icon(LucideIcons.folderX, size: 56)),
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
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final outlinedStyle = OutlinedButton.styleFrom(
      side: const BorderSide(color: Colors.white24),
      shape: buttonShape,
      foregroundColor: Colors.white,
      overlayColor: Colors.white10,
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    );
    final filledStyle = FilledButton.styleFrom(
      shape: buttonShape,
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.16),
      foregroundColor: Colors.white,
      overlayColor: Colors.white24,
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    );

    return SizedBox(
      height: 64,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            FilledButton.icon(
              icon: const Icon(LucideIcons.folderPlus),
              label: const Text('Nouveau dossier'),
              onPressed: state.isLoading ? null : _promptCreateFolder,
              style: filledStyle,
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.copy),
              label: const Text('Copier'),
              onPressed: state.isLoading || selectionCount == 0
                  ? null
                  : _viewModel.copySelectionToClipboard,
              style: outlinedStyle,
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              icon: const Icon(LucideIcons.clipboard),
              label: const Text('Coller'),
              onPressed: state.isLoading || !_viewModel.canPaste
                  ? null
                  : _viewModel.pasteClipboard,
              style: filledStyle,
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              icon: const Icon(LucideIcons.edit3),
              label: const Text('Renommer'),
              onPressed: state.isLoading || selectionCount != 1
                  ? null
                  : _promptRename,
              style: filledStyle,
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.move),
              label: const Text('Deplacer vers...'),
              onPressed: state.isLoading || selectionCount == 0
                  ? null
                  : _promptMove,
              style: outlinedStyle,
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.trash2),
              label: const Text('Supprimer'),
              onPressed: state.isLoading || selectionCount == 0
                  ? null
                  : _confirmDeletion,
              style: outlinedStyle,
            ),
            const SizedBox(width: 16),
            if (selectionCount > 0) ...[
              Text(
                '$selectionCount selectionne(s)',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.white70),
              ),
              IconButton(
                tooltip: 'Vider la selection',
                onPressed: state.isLoading ? null : _viewModel.clearSelection,
                icon: const Icon(LucideIcons.x),
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

    final menuItems = <PopupMenuEntry<String>>[];
    if (entry != null) {
      menuItems.add(
        const PopupMenuItem<String>(value: 'open', child: Text('Ouvrir')),
      );
      if (entry.isApplication) {
        menuItems.addAll([
          const PopupMenuItem<String>(
            value: 'launchApp',
            child: Text('Lancer l application'),
          ),
          const PopupMenuItem<String>(
            value: 'openPackage',
            child: Text('Ouvrir comme dossier'),
          ),
        ]);
      }
      menuItems.add(
        const PopupMenuItem<String>(
          value: 'reveal',
          child: Text('Afficher dans Finder'),
        ),
      );
      menuItems.add(
        const PopupMenuItem<String>(value: 'copy', child: Text('Copier')),
      );
      menuItems.add(
        const PopupMenuItem<String>(value: 'cut', child: Text('Couper')),
      );
    }

    final pasteDestination = entry != null && entry.isDirectory
        ? entry.path
        : null;
    if (_viewModel.canPaste) {
      menuItems.add(
        PopupMenuItem<String>(
          value: 'paste',
          child: Text(
            pasteDestination != null ? 'Coller dans ce dossier' : 'Coller ici',
          ),
        ),
      );
    }

    if (entry != null) {
      menuItems.addAll([
        const PopupMenuItem<String>(
          value: 'duplicate',
          child: Text('Dupliquer'),
        ),
        const PopupMenuItem<String>(
          value: 'move',
          child: Text('Deplacer vers...'),
        ),
        const PopupMenuItem<String>(value: 'rename', child: Text('Renommer')),
        const PopupMenuItem<String>(value: 'delete', child: Text('Supprimer')),
      ]);
    } else {
      menuItems.add(
        const PopupMenuItem<String>(
          value: 'newFolder',
          child: Text('Nouveau dossier'),
        ),
      );
    }

    String? selected;
    try {
      selected = await showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          globalPosition.dx,
          globalPosition.dy,
          globalPosition.dx,
          globalPosition.dy,
        ),
        items: menuItems,
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
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildDraggableEntry(
          entry: entry,
          selectionMode: selectionMode,
          viewMode: ExplorerViewMode.list,
        );
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
      _NavItem(label: 'Accueil', icon: LucideIcons.home, path: home),
      _NavItem(
        label: 'Bureau',
        icon: LucideIcons.monitor,
        path: _join(home, 'Desktop'),
      ),
      _NavItem(
        label: 'Documents',
        icon: LucideIcons.folderOpen,
        path: _join(home, 'Documents'),
      ),
      _NavItem(
        label: 'Telechargements',
        icon: LucideIcons.download,
        path: _join(home, 'Downloads'),
      ),
    ];
  }

  List<_NavItem> _buildSystemItems(String initialPath) {
    return [
      _NavItem(
        label: 'Racine',
        icon: LucideIcons.hardDrive,
        path: Platform.pathSeparator,
      ),
      _NavItem(
        label: 'Applications',
        icon: LucideIcons.box,
        path: Platform.isWindows ? 'C:\\Program Files' : '/Applications',
      ),
      _NavItem(
        label: 'Projet courant',
        icon: LucideIcons.folder,
        path: initialPath,
      ),
    ];
  }

  List<_NavItem> _buildQuickItems() {
    final home = Platform.environment['HOME'] ?? Directory.current.parent.path;
    return [
      _NavItem(label: 'Recents', icon: LucideIcons.clock3, path: home),
      _NavItem(label: 'Partage', icon: LucideIcons.share2, path: home),
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
          LucideIcons.info,
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

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.entry});

  final FileEntry entry;

  @override
  Widget build(BuildContext context) {
    final icon = entry.isDirectory ? LucideIcons.folder : LucideIcons.file;
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
    this.selectedTag,
    this.onTagSelected,
  });

  final List<_NavItem> favoriteItems;
  final List<_NavItem> systemItems;
  final List<_NavItem> quickItems;
  final List<_TagItem> tags;
  final List<_VolumeInfo> volumes;
  final List<String> recentPaths;
  final String? selectedTag;
  final void Function(String path) onNavigate;
  final void Function(String tag)? onTagSelected;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SidebarSection(
              title: 'Navigation',
              compact: true,
              items: quickItems
                  .map(
                    (item) => SidebarItem(
                      label: item.label,
                      icon: item.icon,
                      onTap: () => onNavigate(item.path),
                    ),
                  )
                  .toList(),
            ),
            if (recentPaths.isNotEmpty) ...[
              const SizedBox(height: 12),
              SidebarSection(
                title: 'Recents',
                compact: true,
                items: recentPaths
                    .take(6)
                    .map(
                      (path) => SidebarItem(
                        label: path
                            .split(Platform.pathSeparator)
                            .where((p) => p.isNotEmpty)
                            .last,
                        icon: LucideIcons.history,
                        onTap: () => onNavigate(path),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            SidebarSection(
              title: 'Emplacements',
              items: systemItems
                  .map(
                    (item) => SidebarItem(
                      label: item.label,
                      icon: item.icon,
                      onTap: () => onNavigate(item.path),
                    ),
                  )
                  .toList(),
            ),
            if (volumes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Disques',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.8,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 6),
              ...volumes.map(
                (volume) => _VolumeTile(
                  volume: volume,
                  onTap: () => onNavigate(volume.path),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Tags',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 0.8,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 6),
            ...tags.map((tag) {
              final isActive = selectedTag == tag.label;
              return InkWell(
                onTap: onTagSelected == null
                    ? null
                    : () => onTagSelected!(tag.label),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white.withOpacity(0.08) : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: tag.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tag.label,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: isActive ? Colors.white : Colors.white70,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _VolumeTile extends StatelessWidget {
  const _VolumeTile({required this.volume, required this.onTap});

  final _VolumeInfo volume;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = (volume.usage * 100).clamp(0, 100).round();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(LucideIcons.hardDrive, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    volume.label,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: volume.usage.clamp(0, 1),
                      ),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.06),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$percent%',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatBytes(volume.totalBytes),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
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

    return Opacity(
      opacity: 0.7,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _StatChip(label: 'Selectionés', value: '$selectionCount'),
            const SizedBox(width: 8),
            _StatChip(label: 'Dossiers', value: '$folderCount'),
            const SizedBox(width: 8),
            _StatChip(label: 'Fichiers', value: '$fileCount'),
            const SizedBox(width: 8),
            _StatChip(label: 'Taille', value: _formatBytes(totalSize)),
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
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 0.4,
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
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
    return TextField(
      controller: controller,
      onSubmitted: onSubmit,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Chemin du dossier',
        prefixIcon: const Icon(LucideIcons.folderOpen),
        suffixIcon: IconButton(
          icon: const Icon(LucideIcons.arrowRight, size: 16),
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
        prefixIcon: const Icon(LucideIcons.search),
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
