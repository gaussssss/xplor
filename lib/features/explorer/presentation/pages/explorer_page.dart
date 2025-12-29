import 'dart:io';

import 'package:flutter/material.dart';

import '../../../explorer/data/datasources/local_file_system_data_source.dart';
import '../../../explorer/data/repositories/file_system_repository_impl.dart';
import '../../../explorer/domain/entities/file_entry.dart';
import '../../../explorer/domain/usecases/copy_entries.dart';
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
  late final List<_NavItem> _favoriteItems;
  late final List<_NavItem> _systemItems;
  String? _lastStatusMessage;
  bool _contextMenuOpen = false;

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
    _favoriteItems = _buildFavoriteItems();
    _systemItems = _buildSystemItems(initialPath);
    _viewModel.loadDirectory(initialPath, pushHistory: false);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _pathController.dispose();
    _searchController.dispose();
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.statusMessage!),
                behavior: SnackBarBehavior.floating,
              ),
            );
            _viewModel.clearStatus();
            _lastStatusMessage = null;
          });
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B0E14), Color(0xFF0E1321)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 240,
                      child: _Sidebar(
                        favoriteItems: _favoriteItems,
                        systemItems: _systemItems,
                        onNavigate: _viewModel.loadDirectory,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GlassPanel(child: _buildToolbar(state)),
                          const SizedBox(height: 12),
                          Expanded(
                            child: GlassPanel(
                              padding: const EdgeInsets.all(0),
                              child: _buildContent(state, entries),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GlassPanel(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: BreadcrumbBar(
                              path: state.currentPath,
                              onNavigate: (path) => _viewModel.loadDirectory(path),
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
          icon: Icons.arrow_back_rounded,
          tooltip: 'Arriere',
          onPressed: state.isLoading || !_viewModel.canGoBack
              ? null
              : _viewModel.goBack,
        ),
        const SizedBox(width: 8),
        ToolbarButton(
          icon: Icons.arrow_forward_rounded,
          tooltip: 'Avant',
          onPressed: state.isLoading || !_viewModel.canGoForward
              ? null
              : _viewModel.goForward,
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
        Expanded(
          flex: 2,
          child: _SearchInput(
            controller: _searchController,
            onChanged: _viewModel.updateSearch,
          ),
        ),
        const SizedBox(width: 12),
        ToolbarButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Rafraichir',
          onPressed: state.isLoading ? null : _viewModel.refresh,
        ),
        const SizedBox(width: 12),
        ToolbarButton(
          icon: Icons.view_list_rounded,
          tooltip: 'Vue liste',
          isActive: state.viewMode == ExplorerViewMode.list,
          onPressed: () => _viewModel.setViewMode(ExplorerViewMode.list),
        ),
        const SizedBox(width: 8),
        ToolbarButton(
          icon: Icons.grid_view_rounded,
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
              const Icon(Icons.error_outline_rounded, size: 48),
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
              Center(child: Icon(Icons.folder_off_rounded, size: 56)),
              SizedBox(height: 8),
              Center(child: Text('Aucun element dans ce dossier (ou acces limite)')),
              SizedBox(height: 40),
            ],
          )
        : state.viewMode == ExplorerViewMode.list
            ? _buildList(entries, selectionMode)
            : _buildGrid(entries, selectionMode);

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onSecondaryTapDown: (details) => _showContextMenu(null, details.globalPosition),
      child: Column(
        children: [
          _buildActionBar(state),
          const Divider(height: 1),
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _viewModel.refresh,
                  child: content,
                ),
                if (state.isLoading)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(ExplorerViewState state) {
    final selectionCount = state.selectedPaths.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          FilledButton.icon(
            icon: const Icon(Icons.create_new_folder_rounded),
            label: const Text('Nouveau dossier'),
            onPressed: state.isLoading ? null : _promptCreateFolder,
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copier'),
            onPressed: state.isLoading || selectionCount == 0
                ? null
                : _viewModel.copySelectionToClipboard,
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.paste_rounded),
            label: const Text('Coller'),
            onPressed:
                state.isLoading || !_viewModel.canPaste ? null : _viewModel.pasteClipboard,
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.drive_file_rename_outline_rounded),
            label: const Text('Renommer'),
            onPressed: state.isLoading || selectionCount != 1
                ? null
                : _promptRename,
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.drive_folder_upload_rounded),
            label: const Text('Deplacer vers...'),
            onPressed: state.isLoading || selectionCount == 0
                ? null
                : _promptMove,
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Supprimer'),
            onPressed: state.isLoading || selectionCount == 0
                ? null
                : _confirmDeletion,
          ),
          const Spacer(),
          if (selectionCount > 0) ...[
            Text(
              '$selectionCount selectionne(s)',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Colors.white70),
            ),
            IconButton(
              tooltip: 'Vider la selection',
              onPressed: state.isLoading ? null : _viewModel.clearSelection,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ],
      ),
    );
  }

  void _handleEntryTap(FileEntry entry) {
    _viewModel.open(entry);
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
    final entry = _viewModel.state.entries
        .firstWhere((element) => selected.contains(element.path));
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

    if (entry != null &&
        !_viewModel.state.selectedPaths.contains(entry.path)) {
      _viewModel.selectSingle(entry);
    }

    final menuItems = <PopupMenuEntry<String>>[];
    if (entry != null) {
      menuItems.add(
        const PopupMenuItem<String>(
          value: 'open',
          child: Text('Ouvrir'),
        ),
      );
      menuItems.add(
        const PopupMenuItem<String>(
          value: 'reveal',
          child: Text('Afficher dans Finder'),
        ),
      );
      menuItems.add(
        const PopupMenuItem<String>(
          value: 'copy',
          child: Text('Copier'),
        ),
      );
      menuItems.add(
        const PopupMenuItem<String>(
          value: 'cut',
          child: Text('Couper'),
        ),
      );
    }

    final pasteDestination =
        entry != null && entry.isDirectory ? entry.path : null;
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
        const PopupMenuItem<String>(
          value: 'rename',
          child: Text('Renommer'),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text('Supprimer'),
        ),
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
        final intoDescendant =
            data.any((item) => _isAncestorPath(item.path, entry.path));
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
    final normalizedParent =
        parent.endsWith(separator) ? parent : '$parent$separator';
    final normalizedChild =
        child.endsWith(separator) ? child : '$child$separator';
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
      _NavItem(
        label: 'Accueil',
        icon: Icons.home_filled,
        path: home,
      ),
      _NavItem(
        label: 'Bureau',
        icon: Icons.desktop_mac_rounded,
        path: _join(home, 'Desktop'),
      ),
      _NavItem(
        label: 'Documents',
        icon: Icons.folder_shared_rounded,
        path: _join(home, 'Documents'),
      ),
      _NavItem(
        label: 'Telechargements',
        icon: Icons.download_rounded,
        path: _join(home, 'Downloads'),
      ),
    ];
  }

  List<_NavItem> _buildSystemItems(String initialPath) {
    return [
      _NavItem(
        label: 'Racine',
        icon: Icons.computer_rounded,
        path: Platform.pathSeparator,
      ),
      _NavItem(
        label: 'Applications',
        icon: Icons.apps_rounded,
        path: Platform.isWindows ? 'C:\\Program Files' : '/Applications',
      ),
      _NavItem(
        label: 'Projet courant',
        icon: Icons.folder_special_rounded,
        path: initialPath,
      ),
    ];
  }

  String _join(String base, String child) {
    if (base.endsWith(Platform.pathSeparator)) return '$base$child';
    return '$base${Platform.pathSeparator}$child';
  }
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.entry});

  final FileEntry entry;

  @override
  Widget build(BuildContext context) {
    final icon = entry.isDirectory
        ? Icons.folder_rounded
        : Icons.insert_drive_file_rounded;
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
  });

  final List<_NavItem> favoriteItems;
  final List<_NavItem> systemItems;
  final void Function(String path) onNavigate;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xplor',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Explorateur futuriste',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          SidebarSection(
            title: 'Systeme',
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
          const Spacer(),
          const Divider(height: 12),
          Text(
            'Navigation inspiree de Windows Explorer avec une touche macOS.',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _PathInput extends StatelessWidget {
  const _PathInput({
    required this.controller,
    required this.onSubmit,
  });

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
        prefixIcon: const Icon(Icons.folder_open_rounded),
        suffixIcon: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onPressed: () => onSubmit(controller.text),
        ),
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({
    required this.controller,
    required this.onChanged,
  });

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
        prefixIcon: const Icon(Icons.search_rounded),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final String path;
}
