part of '../explorer_page.dart';

extension _ExplorerPageActions on _ExplorerPageState {
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
