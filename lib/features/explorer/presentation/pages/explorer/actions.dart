part of '../explorer_page.dart';

extension _ExplorerPageActions on _ExplorerPageState {
  Dialog _buildCompactDialog(
    Widget child, {
    double maxWidth = 360,
    double maxHeight = 420,
  }) {
    final baseTheme = Theme.of(context);
    final dialogTheme = baseTheme.copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(foregroundColor: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
      ),
    );
    return Dialog(
      alignment: Alignment.center,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Theme(data: dialogTheme, child: child),
      ),
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
          if (state.currentPath != SpecialLocations.trash) ...[
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

    if (state.currentPath == SpecialLocations.trash) {
      return _buildTrashActionBar(state);
    }

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
                  : _pasteClipboardWithRename,
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

  Widget _buildTrashActionBar(ExplorerViewState state) {
    final selectionCount = state.selectedPaths.length;
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            ToolbarButton(
              icon: lucide.LucideIcons.undo2,
              tooltip: 'Restaurer',
              isActive: !state.isLoading && selectionCount > 0,
              onPressed: state.isLoading || selectionCount == 0
                  ? null
                  : _confirmRestoreFromTrash,
            ),
            const SizedBox(width: 8),
            ToolbarButton(
              icon: lucide.LucideIcons.trash2,
              tooltip: 'Supprimer définitivement',
              isActive: !state.isLoading && selectionCount > 0,
              onPressed: state.isLoading || selectionCount == 0
                  ? null
                  : _confirmDeletion,
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
    _openEntryWithUnlock(entry);
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
        return _buildCompactDialog(
          AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
          maxWidth: 360,
        );
      },
    );
  }

  Future<void> _confirmDeletion() async {
    final count = _viewModel.state.selectedPaths.length;
    final isTrash = _viewModel.state.currentPath == SpecialLocations.trash;
    final title = isTrash ? 'Suppression definitive' : 'Supprimer';
    final content = isTrash
        ? 'Supprimer definitivement $count element(s) ? Cette action est irreversible.'
        : 'Deplacer $count element(s) dans la corbeille ?';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return _buildCompactDialog(
          AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isTrash ? Colors.redAccent.shade200 : null,
                ),
                child: Text(isTrash ? 'Supprimer' : 'Deplacer'),
              ),
            ],
          ),
          maxWidth: 360,
        );
      },
    );

    if (confirmed == true) {
      await _viewModel.deleteSelected();
    }
  }

  Future<void> _confirmRestoreFromTrash() async {
    final entries = _viewModel.state.entries
        .where((entry) => _viewModel.state.selectedPaths.contains(entry.path))
        .toList();
    if (entries.isEmpty) return;
    final lockedCount = entries.where(_viewModel.isLockedEntry).length;
    final title = 'Restaurer';
    final baseMessage =
        'Restaurer ${entries.length} element(s) vers leur emplacement d origine ?';
    final lockedMessage = lockedCount == 0
        ? null
        : '$lockedCount fichier(s) verrouille(s) (.xplrlock) resteront chiffré(s) et seront replacés à leur emplacement d origine.';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return _buildCompactDialog(
          AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Text(title),
            content: Text(
              lockedMessage == null
                  ? baseMessage
                  : '$baseMessage\n\n$lockedMessage',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Restaurer'),
              ),
            ],
          ),
          maxWidth: 380,
        );
      },
    );

    if (confirmed != true) return;
    final restoredPaths = await _viewModel.restoreSelectedFromTrash();
    if (restoredPaths.isEmpty) return;

    final shouldOpen = await _showOpenRestoredPrompt(restoredPaths.length);
    if (shouldOpen == true) {
      await _openRestoredLocation(restoredPaths.first);
    }
  }

  Future<bool?> _showOpenRestoredPrompt(int restoredCount) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return _buildCompactDialog(
          AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: const Text('Restauration terminee'),
            content: Text(
              restoredCount == 1
                  ? 'Ouvrir l emplacement du fichier restauré ?'
                  : 'Ouvrir l emplacement d un des fichiers restaurés ?',
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
          maxWidth: 360,
        );
      },
    );
  }

  Future<void> _openRestoredLocation(String path) async {
    final entry = FileEntry(
      name: p.basename(path),
      path: path,
      isDirectory: Directory(path).existsSync(),
      created: null,
      accessed: null,
      mode: null,
    );
    await _viewModel.openInFinder(entry);
  }

  Future<void> _openEntryWithUnlock(FileEntry entry) async {
    if (entry.isApplication) {
      await _viewModel.launchApplication(entry);
      return;
    }
    if (_isArchive(entry.path)) {
      try {
        await _viewModel.openArchive(entry);
      } on ArchivePasswordRequired {
        final pwd = await _promptEncryptionKey(
          title: 'Archive protegee',
          confirm: false,
        );
        if (pwd == null || pwd.trim().isEmpty) return;
        try {
          await _viewModel.openArchive(entry, password: pwd);
        } on ArchivePasswordRequired {
          _showToast('Mot de passe requis pour cette archive.');
        }
      }
      return;
    }
    if (_viewModel.isLockedEntry(entry)) {
      _showToast('Fichier verrouille, demande de cle...');
      final key = await _promptEncryptionKey(
        title: 'Fichier verrouille',
        confirm: true,
      );
      if (key == null || key.trim().isEmpty) return;
      debugPrint('[Xplor][Unlock] Tentative de déverrouillage de ${entry.path}');
      final success = await _viewModel.unlockEntry(entry, key);
      debugPrint('[Xplor][Unlock] Résultat: ${success ? 'OK' : 'ECHEC'} pour ${entry.path}');
      if (!success) return;
      await _viewModel.refresh();
      final unlockedName =
          p.basename(entry.path).replaceAll(RegExp(r'\\.xplrlock$'), '');
      final maybe = _viewModel.state.entries.firstWhere(
        (e) => e.name == unlockedName,
        orElse: () => FileEntry(
          name: unlockedName,
          path: p.join(p.dirname(entry.path), unlockedName),
          isDirectory: Directory(p.join(p.dirname(entry.path), unlockedName))
              .existsSync(),
          created: null,
          accessed: null,
          mode: null,
        ),
      );
      await _viewModel.open(maybe);
      return;
    }
    await _viewModel.open(entry);
  }

  bool _isArchive(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.zip') ||
        lower.endsWith('.rar') ||
        lower.endsWith('.7z') ||
        lower.endsWith('.tar') ||
        lower.endsWith('.gz') ||
        lower.endsWith('.bz2') ||
        lower.endsWith('.xz');
  }

  void _applySort(FileColumn column) {
    final current = _viewModel.state.sortConfig;
    final newConfig = current.column == column
        ? current.toggle()
        : SortConfig(column: column, order: SortOrder.ascending);
    _viewModel.setSort(newConfig);
  }

  Future<void> _applyTagToSelection(String? tag) async {
    final selected = _viewModel.state.entries
        .where((e) => _viewModel.state.selectedPaths.contains(e.path))
        .toList();
    if (selected.isEmpty) return;
    for (final entry in selected) {
      await _viewModel.setNativeTag(entry.path, tag);
    }
  }

  Future<void> _pasteClipboardWithRename([String? destinationPath]) async {
    if (!_viewModel.canPaste) return;
    final targetPath = destinationPath ?? _viewModel.state.currentPath;
    final entries = _viewModel.clipboardEntries;
    if (entries.isEmpty) return;

    final renameMap = <String, String>{};
    for (final entry in entries) {
      final target = p.join(targetPath, entry.name);
      if (_pathExists(target)) {
        final suggested = _generateUniqueName(entry.name, targetPath);
        final renamed = await _promptRenameOnPaste(
          entry.name,
          suggested,
          targetPath,
        );
        if (renamed == null) return;
        renameMap[entry.path] = renamed;
      }
    }

    if (renameMap.isEmpty) {
      await _viewModel.pasteClipboard(targetPath);
    } else {
      await _viewModel.pasteClipboardWithRename(renameMap, targetPath);
    }
  }

  bool _pathExists(String targetPath) {
    return FileSystemEntity.typeSync(targetPath) !=
        FileSystemEntityType.notFound;
  }

  String _generateUniqueName(String fileName, String targetDir) {
    final ext = p.extension(fileName);
    final base = ext.isEmpty
        ? fileName
        : p.basenameWithoutExtension(fileName);
    var counter = 1;
    while (true) {
      final candidate =
          ext.isEmpty ? '$base ($counter)' : '$base ($counter)$ext';
      final candidatePath = p.join(targetDir, candidate);
      if (!_pathExists(candidatePath)) return candidate;
      counter++;
    }
  }

  Future<String?> _promptRenameOnPaste(
    String currentName,
    String suggestedName,
    String targetDir,
  ) {
    final controller = TextEditingController(text: suggestedName);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return _buildCompactDialog(
          AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: const Text('Renommer le fichier'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Un fichier nommé "$currentName" existe déjà.',
                ),
                const SizedBox(height: 8),
                const Text('Choisissez un nouveau nom.'),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Nouveau nom',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isEmpty) {
                    Navigator.of(context).pop(null);
                    return;
                  }
                  final candidatePath = p.join(targetDir, value);
                  if (_pathExists(candidatePath)) {
                    final fallback = _generateUniqueName(value, targetDir);
                    Navigator.of(context).pop(fallback);
                    return;
                  }
                  Navigator.of(context).pop(value);
                },
                child: const Text('Renommer'),
              ),
            ],
          ),
          maxWidth: 380,
        );
      },
    );
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
    final isTrash = _viewModel.state.currentPath == SpecialLocations.trash;
    final isLocked = entry != null && _viewModel.isLockedEntry(entry);
    final canPreview =
        entry != null &&
        !entry.isDirectory &&
        !isLocked &&
        _viewModel.canPreviewPath(entry.path);

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
            if (canPreview)
              const _ContextMenuEntry(
                id: 'preview',
                label: 'Previsualiser',
                icon: lucide.LucideIcons.eye,
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
        id: 'sortMenu',
        label: 'Trier par',
        icon: lucide.LucideIcons.arrowUpDown,
        children: const [
          _ContextMenuEntry(
            id: 'sort:name',
            label: 'Nom',
            icon: lucide.LucideIcons.arrowUpAZ,
          ),
          _ContextMenuEntry(
            id: 'sort:date',
            label: 'Date de modification',
            icon: lucide.LucideIcons.calendarClock,
          ),
          _ContextMenuEntry(
            id: 'sort:size',
            label: 'Taille',
            icon: lucide.LucideIcons.ruler,
          ),
          _ContextMenuEntry(
            id: 'sort:type',
            label: 'Type',
            icon: lucide.LucideIcons.layers,
          ),
        ],
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

    // Tags
    items.add(
      _ContextMenuEntry(
        id: 'tagsMenu',
        label: 'Tags',
        icon: lucide.LucideIcons.palette,
        children: [
          ..._tagItems.map(
            (tag) => _ContextMenuEntry(
              id: 'tag:${tag.label}',
              label: tag.label,
              icon: lucide.LucideIcons.circle,
              iconColor: tag.color,
            ),
          ),
          const _ContextMenuEntry.separator(),
          const _ContextMenuEntry(
            id: 'tag:clear',
            label: 'Effacer le tag',
            icon: lucide.LucideIcons.x,
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
        if (isTrash) {
          items.add(
            const _ContextMenuEntry(
              id: 'restore',
              label: 'Restaurer',
              icon: lucide.LucideIcons.undo2,
            ),
          );
          items.add(
            const _ContextMenuEntry(
              id: 'delete',
              label: 'Supprimer definitivement',
              icon: lucide.LucideIcons.trash2,
              destructive: true,
            ),
          );
        } else {
          items.add(
            const _ContextMenuEntry(
              id: 'delete',
              label: 'Supprimer',
              icon: lucide.LucideIcons.trash2,
              destructive: true,
            ),
          );
        }
      }
    } else {
      items.add(const _ContextMenuEntry.separator());
      if (!isArchiveView && !isTrash) {
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
        if (entry != null) await _openEntryWithUnlock(entry);
        break;
      case 'openWithDefault':
        if (entry != null) await _openEntryWithUnlock(entry);
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
        await _pasteClipboardWithRename(pasteDestination);
        break;
      case 'duplicate':
        await _viewModel.duplicateSelected();
        break;
      case 'move':
        await _promptMove();
        break;
      case 'sort:name':
        _applySort(FileColumn.name);
        break;
      case 'sort:date':
        _applySort(FileColumn.dateModified);
        break;
      case 'sort:size':
        _applySort(FileColumn.size);
        break;
      case 'sort:type':
        _applySort(FileColumn.kind);
        break;
      case 'rename':
        await _promptRename();
        break;
      case 'delete':
        await _confirmDeletion();
        break;
      case 'restore':
        await _confirmRestoreFromTrash();
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
      default:
        if (selected != null && selected.startsWith('tag:')) {
          final label = selected.substring(4);
          await _applyTagToSelection(label == 'clear' ? null : label);
        }
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
    try {
      final apps = await _viewModel.resolveOpenWithApps(entry.path);
      final selection = await _showOpenWithDialog(apps);
      if (selection == null) return;
      if (selection.name == '__choose__') {
        final appPath = await _pickApplicationPath();
        if (appPath == null) return;
        await Process.run('open', ['-a', appPath, entry.path]);
        _showToast('Ouvert avec ${p.basenameWithoutExtension(appPath)}');
        return;
      }
      await Process.run('open', ['-a', selection.path, entry.path]);
      _showToast('Ouvert avec ${selection.name}');
    } catch (_) {
      _showToast('Impossible d ouvrir avec cette application');
    }
  }

  Future<OpenWithApp?> _showOpenWithDialog(List<OpenWithApp> apps) async {
    final maxHeight = 220.0;
    return showDialog<OpenWithApp?>(
      context: context,
      builder: (context) {
        return _buildCompactDialog(
          AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            contentPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: const Text('Ouvrir avec'),
            content: SizedBox(
              width: 300,
              height: apps.isEmpty ? 120 : maxHeight,
              child: apps.isEmpty
                  ? const Center(child: Text('Aucune application trouvée.'))
                  : ListView.separated(
                      itemCount: apps.length + 1,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        if (index == apps.length) {
                          return ListTile(
                            leading: const Icon(lucide.LucideIcons.search),
                            title: const Text('Choisir une autre application'),
                            onTap: () => Navigator.of(context).pop(
                              const OpenWithApp(name: '__choose__', path: ''),
                            ),
                          );
                        }
                        final app = apps[index];
                        return ListTile(
                          title: Text(app.name),
                          subtitle: Text(
                            app.path,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.of(context).pop(app),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
            ],
          ),
          maxWidth: 360,
        );
      },
    );
  }

  Future<String?> _pickApplicationPath() async {
    if (!Platform.isMacOS) return null;
    const script = 'POSIX path of (choose application)';
    try {
      final result = await Process.run('osascript', ['-e', script]);
      if (result.exitCode != 0) return null;
      final output = (result.stdout ?? '').toString().trim();
      if (output.isEmpty) return null;
      return output;
    } catch (_) {
      return null;
    }
  }

  Future<void> _previewEntry(FileEntry entry) async {
    if (entry.isDirectory) {
      await _viewModel.open(entry);
      return;
    }
    await _showPreviewDialog(entry);
  }

  Future<void> _showPreviewDialog(FileEntry entry) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return _MediaPreviewDialog(entry: entry, viewModel: _viewModel);
      },
    );
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
    final accessed = stat.accessed;
    final permissionString = _formatPermissions(stat.mode);
    int? childrenCount;
    if (isDirectory) {
      try {
        childrenCount = Directory(targetPath).listSync().length;
      } catch (_) {
        childrenCount = null;
      }
    }
    final ext = isDirectory ? '—' : p.extension(name).replaceFirst('.', '').toUpperCase();
    final tagLabel = entry?.tag ?? _viewModel.tagForPath(targetPath);
    final tagColor = _tagColorForLabel(tagLabel);

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
                _buildPropertyRow('Extension', ext.isEmpty ? '—' : '.$ext'),
                if (childrenCount != null)
                  _buildPropertyRow(
                    'Éléments',
                    '$childrenCount',
                  ),
                _buildPropertyRow(
                  'Taille',
                  size == null ? '-' : _formatBytes(size),
                ),
                _buildPropertyRow('Modifie', _formatDate(stat.modified)),
                _buildPropertyRow('Cree', _formatDate(stat.changed)),
                _buildPropertyRow('Accede', _formatDate(accessed)),
                _buildPropertyRow('Permissions', permissionString),
                if (tagLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                            'Tag',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.7),
                                ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: tagColor ?? Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.12),
                                  width: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tagLabel,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Emplacement',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SelectableText(
                        targetPath,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copier le chemin',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: targetPath));
                        _showToast('Chemin copie');
                      },
                      icon: const Icon(lucide.LucideIcons.copy, size: 16),
                    ),
                  ],
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

  String _formatPermissions(int mode) {
    final perms = mode & 0x1FF;
    String triplet(int shift) {
      final r = ((perms >> shift) & 0x4) != 0 ? 'r' : '-';
      final w = ((perms >> shift) & 0x2) != 0 ? 'w' : '-';
      final x = ((perms >> shift) & 0x1) != 0 ? 'x' : '-';
      return '$r$w$x';
    }

    return '${triplet(6)} ${triplet(3)} ${triplet(0)}';
  }

  Color? _tagColorForLabel(String? tag) {
    switch (tag) {
      case 'Rouge':
        return Colors.redAccent;
      case 'Orange':
        return Colors.orangeAccent;
      case 'Jaune':
        return Colors.amberAccent;
      case 'Vert':
        return Colors.lightGreenAccent;
      case 'Bleu':
        return Colors.lightBlueAccent;
      case 'Violet':
        return Colors.purpleAccent;
      case 'Gris':
        return Colors.grey;
      case 'Important':
        return Colors.grey;
      case 'Bureau':
        return Colors.grey;
      case 'Domicile':
        return Colors.grey;
      default:
        return null;
    }
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
        return _buildCompactDialog(
          AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Text(title),
            content: SizedBox(
              width: 300,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(labelText: label),
                autofocus: true,
                onSubmitted: (value) => Navigator.of(context).pop(value),
              ),
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
          maxWidth: 360,
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
            return _buildCompactDialog(
              AlertDialog(
                titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                title: Text(title),
                content: SizedBox(
                  width: 360,
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
              ),
              maxWidth: 400,
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
        return _buildCompactDialog(
          AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: const Text('Cle de chiffrement'),
            content: SizedBox(
              width: 360,
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
          ),
          maxWidth: 380,
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
      final isDark = theme.brightness == Brightness.dark;
      final surface = theme.colorScheme.surface;
      final onSurface = theme.colorScheme.onSurface;
      final borderColor = theme.colorScheme.outlineVariant.withValues(
        alpha: isDark ? 0.35 : 0.6,
      );
      final flushbar = Flushbar(
        maxWidth: 420,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        borderRadius: BorderRadius.circular(14),
        backgroundColor: surface.withValues(alpha: isDark ? 0.88 : 0.94),
        duration: const Duration(milliseconds: 1700),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        icon: Icon(
          lucide.LucideIcons.info,
          size: 22,
          color: theme.colorScheme.primary.withValues(alpha: 0.9),
        ),
        messageText: Text(
          message,
          style: theme.textTheme.labelLarge?.copyWith(
            color: onSurface.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
        borderColor: borderColor,
        borderWidth: 1,
        boxShadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        shouldIconPulse: false,
        flushbarPosition: FlushbarPosition.BOTTOM,
        onStatusChanged: (status) {
          if (status == FlushbarStatus.DISMISSED ||
              status == FlushbarStatus.IS_HIDING) {
            _isToastShowing = false;
          }
        },
      );
      flushbar.show(context).whenComplete(() {
        _isToastShowing = false;
      });
    } catch (_) {
      _isToastShowing = false;
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _MediaPreviewDialog extends StatefulWidget {
  const _MediaPreviewDialog({required this.entry, required this.viewModel});

  final FileEntry entry;
  final ExplorerViewModel viewModel;

  @override
  State<_MediaPreviewDialog> createState() => _MediaPreviewDialogState();
}

class _MediaPreviewDialogState extends State<_MediaPreviewDialog> {
  VideoPlayerController? _videoController;
  bool _videoInitFailed = false;
  Future<Uint8List?>? _audioArtFuture;
  Future<String?>? _docPreviewFuture;
  late final bool _isVideo;
  late final bool _isAudio;
  late final bool _isImage;
  late final bool _isSvg;
  late final bool _isText;
  Future<String>? _textPreviewFuture;

  @override
  void initState() {
    super.initState();
    final ext = p.extension(widget.entry.path).toLowerCase();
    _isSvg = ext == '.svg';
    _isImage = const {
      '.png',
      '.jpg',
      '.jpeg',
      '.gif',
      '.webp',
      '.bmp',
    }.contains(ext);
    _isVideo = const {
      '.mp4',
      '.mov',
      '.avi',
      '.mkv',
      '.webm',
      '.flv',
    }.contains(ext);
    _isAudio = const {
      '.mp3',
      '.wav',
      '.aac',
      '.flac',
      '.ogg',
      '.m4a',
      '.wma',
    }.contains(ext);
    _isText = const {
      '.txt',
      '.md',
      '.json',
      '.yaml',
      '.yml',
      '.csv',
      '.log',
      '.ini',
      '.conf',
      '.xml',
    }.contains(ext);

    if (_isVideo) {
      _videoController = VideoPlayerController.file(File(widget.entry.path))
        ..initialize()
            .then((_) {
              if (mounted) setState(() {});
            })
            .catchError((_) {
              _videoInitFailed = true;
              if (mounted) setState(() {});
            });
    } else if (_isAudio) {
      _audioArtFuture = widget.viewModel.resolveAudioArtwork(widget.entry.path);
    } else if (widget.viewModel.shouldGeneratePreview(widget.entry.path)) {
      _docPreviewFuture = widget.viewModel.resolvePreviewThumbnail(
        widget.entry.path,
      );
    } else if (_isText) {
      _textPreviewFuture = _loadTextPreview(widget.entry.path);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(lucide.LucideIcons.x),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Fermer',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(child: _buildPreviewBody(theme)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      widget.viewModel.openFile(widget.entry);
                    },
                    child: const Text('Ouvrir'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewBody(ThemeData theme) {
    if (_isVideo) {
      final controller = _videoController;
      if (_videoInitFailed) {
        return _buildVideoFallback(theme);
      }
      if (controller == null || !controller.value.isInitialized) {
        return _buildLoading(theme);
      }
      return SizedBox(
        width: 420,
        height: 236,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
            IconButton(
              iconSize: 48,
              icon: Icon(
                controller.value.isPlaying
                    ? lucide.LucideIcons.pauseCircle
                    : lucide.LucideIcons.playCircle,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  controller.value.isPlaying
                      ? controller.pause()
                      : controller.play();
                });
              },
            ),
          ],
        ),
      );
    }

    if (_isAudio) {
      final artFuture = _audioArtFuture;
      if (artFuture == null) {
        return _buildAudioFallback(theme);
      }
      return FutureBuilder<Uint8List?>(
        future: artFuture,
        builder: (context, snapshot) {
          final art = snapshot.data;
          if (art == null || art.isEmpty) {
            return _buildAudioFallback(theme);
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              art,
              width: 220,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildAudioFallback(theme),
            ),
          );
        },
      );
    }

    if (_isImage && widget.entry.path.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(widget.entry.path),
          width: 280,
          height: 280,
          fit: BoxFit.contain,
        ),
      );
    }

    if (_isSvg && widget.entry.path.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SvgPicture.file(
          File(widget.entry.path),
          width: 280,
          height: 280,
          fit: BoxFit.contain,
        ),
      );
    }

    if (_isText && _textPreviewFuture != null) {
      return FutureBuilder<String>(
        future: _textPreviewFuture,
        builder: (context, snapshot) {
          final content = snapshot.data ?? 'Aperçu indisponible';
          return Container(
            width: 360,
            constraints: const BoxConstraints(maxHeight: 260),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                content,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  height: 1.45,
                  fontFamily: 'Menlo',
                ),
              ),
            ),
          );
        },
      );
    }

    final previewFuture = _docPreviewFuture;
    if (previewFuture == null) {
      return _buildFallbackIcon(theme);
    }
    return FutureBuilder<String?>(
      future: previewFuture,
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path == null || path.isEmpty) {
          return _buildFallbackIcon(theme);
        }
        final file = File(path);
        if (!file.existsSync()) {
          return _buildFallbackIcon(theme);
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, width: 280, height: 280, fit: BoxFit.contain),
        );
      },
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildFallbackIcon(ThemeData theme) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        lucide.LucideIcons.fileText,
        size: 72,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildAudioFallback(ThemeData theme) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        lucide.LucideIcons.music2,
        size: 72,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildVideoFallback(ThemeData theme) {
    return Container(
      width: 240,
      height: 160,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        lucide.LucideIcons.video,
        size: 64,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Future<String> _loadTextPreview(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return 'Aperçu indisponible';
      final stream = file.openRead(0, 12 * 1024);
      final chunks = await stream.toList();
      final bytes = chunks.expand((b) => b).toList();
      final decoded = utf8.decode(bytes, allowMalformed: true);
      final lines = decoded.split('\n');
      final limited = lines.take(120).join('\n');
      return limited;
    } catch (e) {
      return 'Aperçu indisponible: $e';
    }
  }
}
