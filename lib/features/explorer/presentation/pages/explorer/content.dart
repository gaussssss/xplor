part of '../explorer_page.dart';

extension _ExplorerPageContent on _ExplorerPageState {
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

}
