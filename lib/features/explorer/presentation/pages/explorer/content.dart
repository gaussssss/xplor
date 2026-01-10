part of '../explorer_page.dart';

extension _ExplorerPageContent on _ExplorerPageState {
  Widget _buildContent(ExplorerViewState state, List<FileEntry> entries) {
    if (state.currentPath == SpecialLocations.disks) {
      if (state.isLoading && entries.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      return DisksPage(
        volumes: _volumes,
        onNavigate: _viewModel.loadDirectory,
        onRefresh: _refreshVolumes,
      );
    }

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
                style: FilledButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final selectionMode = _isMultiSelectionMode;
    final groupedSections = state.groupBy != GroupByOption.none
        ? _groupEntries(entries, state.groupBy)
        : null;
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
            ? _buildList(entries, selectionMode, groupedSections)
            : _buildGrid(entries, selectionMode, groupedSections);

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
          final targetPath =
              '${targetDir.path}${Platform.pathSeparator}$fileName';
          sourcePathMap[fileName] = file.path;

          if (FileSystemEntity.typeSync(targetPath) !=
              FileSystemEntityType.notFound) {
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
            String targetPath =
                '${targetDir.path}${Platform.pathSeparator}$fileName';

            // Si c'est un doublon, vérifier l'action à effectuer
            if (duplicates.contains(fileName)) {
              final action = actions?[fileName];
              if (action == null || action.type == DuplicateActionType.skip) {
                continue; // Ne pas copier ce fichier
              }

              if (action.type == DuplicateActionType.duplicate &&
                  action.newName != null) {
                // Utiliser le nouveau nom
                targetPath =
                    '${targetDir.path}${Platform.pathSeparator}${action.newName}';
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
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.3),
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
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'dans ${_dragTargetPath?.split(Platform.pathSeparator).last ?? "ce dossier"}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
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
    required int index,
  }) {
    final selectedEntries = _viewModel.state.selectedPaths.contains(entry.path)
        ? _viewModel.state.entries
              .where((e) => _viewModel.state.selectedPaths.contains(e.path))
              .toList()
        : <FileEntry>[entry];
    final handleSelection = () =>
        _handleEntrySingleTap(entry, index, selectionMode: selectionMode);
    final appIconFuture = entry.isDirectory
        ? null
        : _viewModel.resolveDefaultAppIconPath(entry.path);
    final previewFuture =
        entry.isDirectory || _viewModel.isLockedPath(entry.path)
        ? null
        : (_viewModel.shouldGeneratePreview(entry.path)
              ? _viewModel.resolvePreviewThumbnail(entry.path)
              : (_viewModel.isVideoFile(entry.path)
                    ? _viewModel.resolveVideoThumbnail(entry.path)
                    : null));
    final audioArtFuture = _viewModel.isAudioFile(entry.path)
        ? _viewModel.resolveAudioArtwork(entry.path)
        : null;
    final tagColor = _tagColorForPath(entry.path);

    final tile = FileEntryTile(
      entry: entry,
      viewMode: viewMode,
      selectionMode: selectionMode,
      isSelected: _viewModel.isSelected(entry),
      isLocked: _viewModel.isLockedPath(entry.path),
      appIconFuture: appIconFuture,
      previewFuture: previewFuture,
      audioArtFuture: audioArtFuture,
      onToggleSelection: handleSelection,
      onOpen: () => _handleEntryTap(entry),
      onContextMenu: (position) => _showContextMenu(entry, position),
      enableDrop: !_viewModel.state.isArchiveView,
      tagColor: tagColor,
    );
    final draggingTile = Opacity(
      opacity: 0.35,
      child: FileEntryTile(
        entry: entry,
        viewMode: viewMode,
        selectionMode: selectionMode,
        isSelected: _viewModel.isSelected(entry),
        isLocked: _viewModel.isLockedPath(entry.path),
        appIconFuture: appIconFuture,
        previewFuture: previewFuture,
        audioArtFuture: audioArtFuture,
        onToggleSelection: handleSelection,
        onOpen: () => _handleEntryTap(entry),
        onContextMenu: (position) => _showContextMenu(entry, position),
        enableDrop: !_viewModel.state.isArchiveView,
        tagColor: tagColor,
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

  Widget _buildList(
    List<FileEntry> entries,
    bool selectionMode,
    List<GroupSection>? groupedSections,
  ) {
    return ListViewTable(
      entries: entries,
      selectionMode: selectionMode,
      scrollController: _scrollController,
      sortConfig: _viewModel.state.sortConfig,
      onSortChanged: _viewModel.setSort,
      groupedSections: groupedSections,
      isSelected: (entry) => _viewModel.isSelected(entry),
      onEntryTap: (entry) {
        _handleEntrySingleTap(entry, null, selectionMode: selectionMode);
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

  Widget _buildGrid(
    List<FileEntry> entries,
    bool selectionMode,
    List<GroupSection>? groupedSections,
  ) {
    if (groupedSections != null && groupedSections.isNotEmpty) {
      return ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: groupedSections.length,
        itemBuilder: (context, index) {
          final section = groupedSections[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  section.label,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _buildGridSection(section.entries, selectionMode,
                  embedded: true),
            ],
          );
        },
      );
    }
    return _buildGridSection(entries, selectionMode);
  }

  Widget _buildGridSection(List<FileEntry> entries, bool selectionMode,
      {bool embedded = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        // Plus de colonnes et espacement réduit pour un meilleur affichage
        final crossAxisCount = (maxWidth / 160).clamp(3, 8).floor();

        return GridView.builder(
          controller: embedded ? null : _scrollController,
          shrinkWrap: embedded,
          physics: embedded
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16, // Espacement horizontal réduit
            mainAxisSpacing: 16, // Espacement vertical réduit
            childAspectRatio: 1.2, // Ratio plus large pour des cartes moins hautes
          ),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _buildDraggableEntry(
              entry: entry,
              selectionMode: selectionMode,
              viewMode: ExplorerViewMode.grid,
              index: index,
            );
          },
        );
      },
    );
  }

  List<GroupSection> _groupEntries(
    List<FileEntry> entries,
    GroupByOption option,
  ) {
    if (entries.isEmpty || option == GroupByOption.none) return const [];

    String labelFor(FileEntry entry) {
      switch (option) {
        case GroupByOption.nameInitial:
          return entry.name.isNotEmpty
              ? entry.name.substring(0, 1).toUpperCase()
              : '#';
        case GroupByOption.size:
          if (entry.isDirectory) return 'Dossiers';
          final size = entry.size ?? 0;
          if (size < 1024 * 1024) return '< 1 Mo';
          if (size < 1024 * 1024 * 128) return '< 128 Mo';
          if (size < 1024 * 1024 * 1024) return '< 1 Go';
          return '>= 1 Go';
        case GroupByOption.dateModified:
          final date = entry.lastModified ?? entry.created ?? entry.accessed;
          if (date == null) return 'Sans date';
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final entryDay = DateTime(date.year, date.month, date.day);
          if (entryDay == today) return "Aujourd'hui";
          if (entryDay == today.subtract(const Duration(days: 1))) {
            return 'Hier';
          }
          if (now.difference(entryDay).inDays < 7) return 'Cette semaine';
          if (now.month == date.month && now.year == date.year) {
            return 'Ce mois-ci';
          }
          return 'Plus anciens';
        case GroupByOption.type:
          if (entry.isDirectory) return 'Dossiers';
          if (entry.name.contains('.')) {
            return entry.name.split('.').last.toUpperCase();
          }
          return 'Fichier';
        case GroupByOption.tag:
          return entry.tag ?? 'Sans tag';
        case GroupByOption.none:
          return '';
      }
    }

    final sections = <GroupSection>[];
    String? currentLabel;
    final currentEntries = <FileEntry>[];

    for (final entry in entries) {
      final label = labelFor(entry);
      if (currentLabel == null || currentLabel != label) {
        if (currentEntries.isNotEmpty) {
          sections.add(GroupSection(
            label: currentLabel!,
            entries: List.unmodifiable(currentEntries),
          ));
          currentEntries.clear();
        }
        currentLabel = label;
      }
      currentEntries.add(entry);
    }

    if (currentEntries.isNotEmpty && currentLabel != null) {
      sections.add(
        GroupSection(label: currentLabel!, entries: List.unmodifiable(currentEntries)),
      );
    }
    return sections;
  }

  void _handleEntrySingleTap(
    FileEntry entry,
    int? index, {
    required bool selectionMode,
  }) {
    final entries = _viewModel.visibleEntries;
    final currentIndex = index ?? entries.indexOf(entry);
    if (currentIndex < 0) {
      _viewModel.selectSingle(entry);
      return;
    }
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final isShift = pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);
    final isMeta = pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight);
    final isCtrl = pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);
    final useToggle = isMeta || isCtrl;

    if (selectionMode || useToggle || isShift) {
      if (isShift && _lastSelectedIndex != null) {
        _viewModel.selectRange(entries, _lastSelectedIndex!, currentIndex);
      } else if (useToggle) {
        _viewModel.toggleSelection(entry);
        _lastSelectedIndex = currentIndex;
      } else {
        _viewModel.selectSingle(entry);
        _lastSelectedIndex = currentIndex;
      }
      return;
    }

    final isTrash = _viewModel.state.currentPath == SpecialLocations.trash;
    final isArchive = _viewModel.state.isArchiveView;
    final selectedPaths = _viewModel.state.selectedPaths;
    final isSingleSelected =
        selectedPaths.length == 1 && selectedPaths.contains(entry.path);

    _lastSelectedIndex = currentIndex;
    if (isSingleSelected && !isTrash && !isArchive) {
      _promptRename();
      return;
    }
    _viewModel.selectSingle(entry);
  }
}
