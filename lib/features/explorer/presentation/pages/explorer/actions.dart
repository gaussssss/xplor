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
              constraints: const BoxConstraints(minWidth: 200, maxWidth: 900),
              child: _PathInput(
                controller: _pathController,
                onSubmit: (value) => _viewModel.loadDirectory(
                  _viewModel.resolveInputPath(value),
                ),
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
      if (FileSystemEntity.typeSync(targetPath) !=
          FileSystemEntityType.notFound) {
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
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
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
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
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
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
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
    await for (final entity in sourceDir.list(
      recursive: false,
      followLinks: false,
    )) {
      final name = entity.path.split(Platform.pathSeparator).last;
      sourcePathMap[name] = entity.path;
    }

    final actions = await _resolveDuplicateActionsForExtraction(
      sourcePathMap,
      target,
    );
    if (actions == null) return;

    await _viewModel.extractArchiveTo(target, duplicateActions: actions);
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

    await _viewModel.extractSelectionTo(target, duplicateActions: actions);
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

    final selectionCount = _viewModel.state.selectedPaths.length;
    final pasteDestination = entry != null && entry.isDirectory
        ? entry.path
        : null;
    final canPaste = _viewModel.canPaste && !isArchiveView;
    final isLocked = entry != null && _viewModel.isLockedEntry(entry);

    final items = <_ContextMenuEntry>[];
    if (entry != null) {
      items.add(
        _ContextMenuEntry(
          id: 'openMenu',
          label: 'Ouvrir',
          icon: lucide.LucideIcons.folderOpen,
          children: [
            _ContextMenuEntry(
              id: 'open',
              label: 'Ouvrir',
              icon: lucide.LucideIcons.folderOpen,
            ),
            _ContextMenuEntry(
              id: 'openWithMenu',
              label: 'Ouvrir avec',
              icon: lucide.LucideIcons.appWindow,
              children: const [
                _ContextMenuEntry(
                  id: 'openWithDefault',
                  label: 'Application par defaut',
                  icon: lucide.LucideIcons.appWindow,
                ),
                _ContextMenuEntry(
                  id: 'openWithCustom',
                  label: 'Choisir une application...',
                  icon: lucide.LucideIcons.search,
                ),
              ],
            ),
            _ContextMenuEntry(
              id: 'preview',
              label: 'Previsualiser',
              icon: lucide.LucideIcons.eye,
              enabled: !entry.isDirectory && !isLocked,
            ),
            if (entry.isApplication) const _ContextMenuEntry.separator(),
            if (entry.isApplication)
              const _ContextMenuEntry(
                id: 'launchApp',
                label: 'Lancer l application',
                icon: lucide.LucideIcons.play,
              ),
            if (entry.isApplication)
              const _ContextMenuEntry(
                id: 'openPackage',
                label: 'Ouvrir comme dossier',
                icon: lucide.LucideIcons.folderOpen,
              ),
          ],
        ),
      );
      items.add(const _ContextMenuEntry.separator());
    }

    items.add(
      _ContextMenuEntry(
        id: 'refresh',
        label: 'Rafraichir',
        icon: lucide.LucideIcons.refreshCw,
      ),
    );

    items.add(
      _ContextMenuEntry(
        id: 'share',
        label: 'Partager',
        icon: lucide.LucideIcons.share2,
        children: [
          _ContextMenuEntry(
            id: 'shareSystem',
            label: 'Partager...',
            icon: lucide.LucideIcons.send,
            enabled: entry != null || selectionCount > 0,
          ),
          _ContextMenuEntry(
            id: 'shareBluetooth',
            label: 'Envoyer par Bluetooth',
            icon: lucide.LucideIcons.bluetooth,
            enabled: entry != null || selectionCount > 0,
          ),
          _ContextMenuEntry(
            id: 'shareWifi',
            label: 'Envoyer par Wi-Fi',
            icon: lucide.LucideIcons.wifi,
            enabled: entry != null || selectionCount > 0,
          ),
          const _ContextMenuEntry.separator(),
          _ContextMenuEntry(
            id: 'shareCopyMenu',
            label: 'Copier',
            icon: lucide.LucideIcons.copy,
            children: [
              _ContextMenuEntry(
                id: 'shareCopyName',
                label: 'Nom du fichier',
                icon: lucide.LucideIcons.type,
                enabled: entry != null,
              ),
              _ContextMenuEntry(
                id: 'shareCopyPath',
                label: entry == null ? 'Chemin courant' : 'Chemin complet',
                icon: lucide.LucideIcons.link2,
              ),
            ],
          ),
          _ContextMenuEntry(
            id: 'shareReveal',
            label: entry == null
                ? 'Afficher le dossier courant'
                : 'Afficher dans Finder',
            icon: lucide.LucideIcons.search,
            enabled: true,
          ),
        ],
      ),
    );

    items.add(
      _ContextMenuEntry(
        id: 'toolsMenu',
        label: 'Outils',
        icon: lucide.LucideIcons.wrench,
        children: [
          _ContextMenuEntry(
            id: 'openTerminal',
            label: entry == null ? 'Ouvrir le terminal ici' : 'Terminal ici',
            icon: lucide.LucideIcons.terminal,
          ),
          _ContextMenuEntry(
            id: 'copyPath',
            label: entry == null
                ? 'Copier le chemin courant'
                : 'Copier le chemin',
            icon: lucide.LucideIcons.link2,
          ),
        ],
      ),
    );

    items.add(
      _ContextMenuEntry(
        id: 'clipboardMenu',
        label: 'Presse-papier',
        icon: lucide.LucideIcons.clipboard,
        children: [
          _ContextMenuEntry(
            id: 'copy',
            label: 'Copier',
            icon: lucide.LucideIcons.copy,
            enabled: selectionCount > 0,
          ),
          _ContextMenuEntry(
            id: 'cut',
            label: 'Couper',
            icon: lucide.LucideIcons.scissors,
            enabled: selectionCount > 0 && !isArchiveView,
          ),
          _ContextMenuEntry(
            id: 'paste',
            label: pasteDestination != null
                ? 'Coller dans ce dossier'
                : 'Coller ici',
            icon: lucide.LucideIcons.clipboard,
            enabled: canPaste,
          ),
        ],
      ),
    );

    if (entry != null && !isArchiveView) {
      items.add(
        _ContextMenuEntry(
          id: 'organizeMenu',
          label: 'Organiser',
          icon: lucide.LucideIcons.folder,
          children: const [
            _ContextMenuEntry(
              id: 'move',
              label: 'Deplacer vers...',
              icon: lucide.LucideIcons.arrowRight,
            ),
            _ContextMenuEntry(
              id: 'rename',
              label: 'Renommer',
              icon: lucide.LucideIcons.pencil,
            ),
            _ContextMenuEntry(
              id: 'duplicate',
              label: 'Dupliquer',
              icon: lucide.LucideIcons.copy,
            ),
          ],
        ),
      );
    }

    if (_viewModel.state.selectedPaths.isNotEmpty && !isArchiveView) {
      items.add(
        const _ContextMenuEntry(
          id: 'compress',
          label: 'Compresser en .zip',
          icon: lucide.LucideIcons.archive,
        ),
      );
    }

    if (entry != null && !isArchiveView) {
      items.add(
        _ContextMenuEntry(
          id: 'securityMenu',
          label: 'Securite',
          icon: lucide.LucideIcons.shield,
          children: [
            _ContextMenuEntry(
              id: isLocked ? 'unlock' : 'lock',
              label: isLocked
                  ? 'Deverrouiller (dechiffrer)'
                  : 'Verrouiller (chiffrer)',
              icon: isLocked
                  ? lucide.LucideIcons.unlock
                  : lucide.LucideIcons.lock,
            ),
          ],
        ),
      );
    }

    if (entry != null) {
      items.add(
        _ContextMenuEntry(
          id: 'properties',
          label: 'Proprietes',
          icon: lucide.LucideIcons.info,
        ),
      );
      if (!isArchiveView) {
        items.add(
          const _ContextMenuEntry(
            id: 'delete',
            label: 'Supprimer',
            icon: lucide.LucideIcons.trash2,
            destructive: true,
          ),
        );
      }
    } else {
      items.add(const _ContextMenuEntry.separator());
      if (!isArchiveView) {
        items.add(
          const _ContextMenuEntry(
            id: 'newFolder',
            label: 'Nouveau dossier',
            icon: lucide.LucideIcons.folderPlus,
          ),
        );
      }
      items.add(
        _ContextMenuEntry(
          id: 'properties',
          label: 'Proprietes du dossier courant',
          icon: lucide.LucideIcons.info,
        ),
      );
    }

    String? selected;
    try {
      selected = await _ContextMenuOverlay.show(
        context: context,
        position: globalPosition,
        items: items,
      );
    } finally {
      _contextMenuOpen = false;
    }

    switch (selected) {
      case 'open':
        if (entry != null) _viewModel.open(entry);
        break;
      case 'openWithDefault':
        if (entry != null) _viewModel.open(entry);
        break;
      case 'openWithCustom':
        if (entry != null) await _promptOpenWith(entry);
        break;
      case 'preview':
        if (entry != null) await _previewEntry(entry);
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
      case 'refresh':
        await _viewModel.refresh();
        break;
      case 'shareCopyName':
        if (entry != null) {
          Clipboard.setData(ClipboardData(text: entry.name));
          _showToast('Nom copie');
        }
        break;
      case 'shareSystem':
        await _shareSelection(entry);
        break;
      case 'shareBluetooth':
        await _shareSelection(entry, channelLabel: 'Bluetooth');
        break;
      case 'shareWifi':
        await _shareSelection(entry, channelLabel: 'Wi-Fi');
        break;
      case 'shareCopyPath':
        _viewModel.copyPathToClipboard(
          entry?.path ?? _viewModel.state.currentPath,
        );
        break;
      case 'shareReveal':
        if (entry != null) {
          await _viewModel.openInFinder(entry);
        } else {
          await _openCurrentInFinder();
        }
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
      case 'properties':
        await _showProperties(entry);
        break;
      case 'lock':
        if (entry != null) await _lockEntry(entry);
        break;
      case 'unlock':
        if (entry != null) await _unlockEntry(entry);
        break;
    }
  }

  Future<void> _shareSelection(FileEntry? entry, {String? channelLabel}) async {
    final entries = _resolveShareEntries(entry);
    if (entries.isEmpty) {
      await _safeShare(_viewModel.state.currentPath);
      return;
    }
    if (entries.any(_viewModel.isLockedEntry)) {
      _showToast('Impossible de partager un fichier verrouille');
      return;
    }
    try {
      final hasDirectory = entries.any((item) => item.isDirectory);
      if (hasDirectory) {
        final text = entries.map((item) => item.path).join('\n');
        await _safeShare(text);
      } else {
        final files = entries.map((item) => XFile(item.path)).toList();
        await Share.shareXFiles(files);
      }
      if (channelLabel != null) {
        _showToast('Choisissez $channelLabel dans la fenetre de partage');
      }
    } catch (_) {
      _showToast('Partage impossible');
    }
  }

  List<FileEntry> _resolveShareEntries(FileEntry? entry) {
    final selected = _viewModel.state.entries
        .where((item) => _viewModel.state.selectedPaths.contains(item.path))
        .toList();
    if (selected.isNotEmpty) return selected;
    if (entry != null) return [entry];
    return const [];
  }

  Future<void> _promptOpenWith(FileEntry entry) async {
    if (!Platform.isMacOS) {
      _showToast('Ouverture avec application indisponible ici');
      return;
    }
    final app = await _showTextDialog(
      title: 'Ouvrir avec',
      label: 'Nom de l application (ex: Preview)',
    );
    if (app == null || app.trim().isEmpty) return;
    try {
      await Process.run('open', ['-a', app.trim(), entry.path]);
      _showToast('Ouvert avec $app');
    } catch (_) {
      _showToast('Impossible d ouvrir avec $app');
    }
  }

  Future<void> _previewEntry(FileEntry entry) async {
    if (entry.isDirectory) {
      await _viewModel.open(entry);
      return;
    }
    try {
      if (Platform.isMacOS) {
        await Process.run('qlmanage', ['-p', entry.path]);
      } else {
        await _viewModel.openFile(entry);
      }
    } catch (_) {
      _showToast('Previsualisation impossible');
    }
  }

  Future<void> _openCurrentInFinder() async {
    final target = _viewModel.state.currentPath;
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [target]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [target]);
      } else {
        await Process.run('xdg-open', [target]);
      }
    } catch (_) {
      _showToast('Impossible d ouvrir le dossier');
    }
  }

  Future<void> _showProperties(FileEntry? entry) async {
    final targetPath = entry?.path ?? _viewModel.state.currentPath;
    final fallbackName = targetPath.split(Platform.pathSeparator).last;
    final name =
        entry?.name ??
        (fallbackName.trim().isNotEmpty ? fallbackName : targetPath);
    final type = FileSystemEntity.typeSync(targetPath);
    final isDirectory =
        entry?.isDirectory ?? type == FileSystemEntityType.directory;
    final isLocked = _viewModel.isLockedPath(targetPath);
    final stat = await FileStat.stat(targetPath);
    final size = entry?.size ?? (isDirectory ? null : stat.size);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Proprietes'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPropertyRow('Nom', name),
                _buildPropertyRow(
                  'Type',
                  isDirectory
                      ? 'Dossier'
                      : isLocked
                      ? 'Fichier verrouille (.xplrlock)'
                      : 'Fichier',
                ),
                _buildPropertyRow(
                  'Taille',
                  size == null ? '-' : _formatBytes(size),
                ),
                _buildPropertyRow('Modifie', _formatDate(stat.modified)),
                _buildPropertyRow('Cree', _formatDate(stat.changed)),
                const SizedBox(height: 8),
                Text(
                  'Emplacement',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  targetPath,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int value) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = value.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final formatted = size.toStringAsFixed(size < 10 ? 1 : 0);
    return '$formatted ${units[unitIndex]}';
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _lockEntry(FileEntry entry) async {
    final key = await _promptEncryptionKey(
      title: entry.isDirectory
          ? 'Verrouiller le dossier'
          : 'Verrouiller le fichier',
      confirm: true,
    );
    if (key == null) return;
    final success = await _viewModel.lockEntry(entry, key);
    if (success) {
      await _promptShareEncryptionKey(key);
    }
  }

  Future<void> _unlockEntry(FileEntry entry) async {
    final key = await _promptEncryptionKey(
      title: 'Deverrouiller',
      confirm: false,
    );
    if (key == null) return;
    await _viewModel.unlockEntry(entry, key);
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

  Future<String?> _promptEncryptionKey({
    required String title,
    required bool confirm,
  }) {
    final keyController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorText;

    return showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void submit() {
              final key = keyController.text.trim();
              final confirmKey = confirmController.text.trim();
              if (key.length < 4) {
                setState(() => errorText = 'Min. 4 caracteres');
                return;
              }
              if (confirm && key != confirmKey) {
                setState(() => errorText = 'Les cles ne correspondent pas');
                return;
              }
              Navigator.of(context).pop(key);
            }

            final theme = Theme.of(context);
            final description = confirm
                ? 'Definissez une cle de chiffrement. Elle ne sera pas stockee.'
                : 'Entrez la cle utilisee lors du verrouillage.';
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: keyController,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      textInputAction: confirm
                          ? TextInputAction.next
                          : TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Cle de chiffrement',
                      ),
                      autofocus: true,
                      onSubmitted: (_) {
                        if (confirm) {
                          FocusScope.of(context).nextFocus();
                        } else {
                          submit();
                        }
                      },
                    ),
                    if (confirm) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirmController,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Confirmer la cle',
                        ),
                        onSubmitted: (_) => submit(),
                      ),
                    ],
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(onPressed: submit, child: const Text('Valider')),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _promptShareEncryptionKey(String key) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Cle de chiffrement'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conservez cette cle dans un endroit sur. Elle est requise pour '
                  'deverrouiller le fichier ou le dossier.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  '•' * key.length,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: key));
                Navigator.of(context).pop();
                _showToast('Cle copiee');
              },
              child: const Text('Copier'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _shareSecret(key);
              },
              child: const Text('Partager'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareSecret(String value) async {
    try {
      await _safeShare(value);
    } catch (_) {
      _showToast('Partage indisponible sur cette plateforme');
    }
  }

  Future<void> _safeShare(String value) async {
    try {
      await Share.share(value);
    } on MissingPluginException {
      _showToast('Partage indisponible sur cette plateforme');
    }
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
