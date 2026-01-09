part of '../explorer_view_model.dart';

extension ExplorerNavigationOps on ExplorerViewModel {
  Future<void> loadDirectory(String path, {bool pushHistory = true}) async {
    var targetPath = path.trim().isEmpty ? _state.currentPath : path.trim();
    targetPath = SpecialLocations.resolveSystemPath(targetPath);
    if (pushHistory && targetPath == _state.currentPath) return;
    final wasArchiveView = _state.isArchiveView;
    final archivePath = _state.archivePath;
    final leavingArchive = wasArchiveView && !_isWithinArchive(targetPath);

    // Gerer les emplacements speciaux
    if (SpecialLocations.isSpecialLocation(targetPath)) {
      if (leavingArchive) {
        await _closeArchiveSession(notify: false);
      }
      return _loadSpecialLocation(targetPath, pushHistory: pushHistory);
    }

    if (_isArchivePath(targetPath) &&
        FileSystemEntity.typeSync(targetPath) == FileSystemEntityType.file) {
      return openArchive(
        FileEntry(
          name: p.basename(targetPath),
          path: targetPath,
          isDirectory: false,
        ),
        pushHistory: pushHistory,
      );
    }

    if (pushHistory && _state.currentPath != targetPath) {
      final historyPath = leavingArchive && archivePath != null
          ? archivePath
          : _state.currentPath;
      _backStack.add(historyPath);
      _forwardStack.clear();
    }
    if (leavingArchive) {
      await _closeArchiveSession(notify: false);
    }
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
      selectedPaths: <String>{},
    );
    notifyListeners();

    try {
      final entries = await _listDirectoryEntries(targetPath);
      _state = _state.copyWith(
        currentPath: targetPath,
        entries: entries,
        isLoading: false,
        searchQuery: '',
        clearError: true,
        clearStatus: true,
      );
      final recentPath = _state.isArchiveView && _state.archivePath != null
          ? _state.archivePath!
          : targetPath;
      await _recordRecent(recentPath);
      await _recordLastPath(recentPath);

      // Mettre a jour l'index en arriere-plan (au lieu de rebuilder)
      if (!_state.isArchiveView) {
        _updateIndexInBackground(targetPath);
      }
    } on FileSystemException catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        error: error.message.isNotEmpty
            ? error.message
            : 'Acces au dossier refuse.',
      );
    } catch (_) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Impossible de charger ce dossier.',
      );
    } finally {
      notifyListeners();
      unawaited(_cleanupStagedArchiveRoots());
    }
  }

  Future<void> _loadSpecialLocation(
    String locationCode, {
    bool pushHistory = true,
  }) async {
    if (pushHistory && _state.currentPath != locationCode) {
      _backStack.add(_state.currentPath);
      _forwardStack.clear();
    }

    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
      selectedPaths: <String>{},
    );
    notifyListeners();

    final resolvedLocation = SpecialLocations.isSpecialLocation(locationCode)
        ? locationCode
        : SpecialLocations.normalizePath(locationCode);
    try {
      List<FileEntry> entries = [];

      // Charger les fichiers recents
      if (resolvedLocation == SpecialLocations.recentFiles) {
        // Creer des entrees virtuelles pour chaque chemin recent
        for (final recentPath in _recentPaths) {
          try {
            final entity = FileSystemEntity.isDirectorySync(recentPath)
                ? Directory(recentPath)
                : File(recentPath);

            if (await entity.exists()) {
              final stat = await entity.stat();
              final segments = recentPath
                  .split(Platform.pathSeparator)
                  .where((s) => s.isNotEmpty)
                  .toList();
              final name = segments.isNotEmpty ? segments.last : recentPath;

              entries.add(
                FileEntry(
                  name: name,
                  path: recentPath,
                  isDirectory: entity is Directory,
                  size: stat.size,
                  lastModified: stat.modified,
                ),
              );
            }
          } catch (_) {
            // Ignorer les fichiers qui n'existent plus
          }
        }
      }
      if (resolvedLocation == SpecialLocations.trash) {
        final trashDir = Directory(SpecialLocations.trashPath);
        if (await trashDir.exists()) {
          entries = await _listDirectoryEntries(trashDir.path);
        }
      }

      _state = _state.copyWith(
        currentPath: locationCode,
        entries: entries,
        isLoading: false,
        searchQuery: '',
        clearError: true,
        clearStatus: true,
      );
      unawaited(_recordLastPath(locationCode));
    } catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Impossible de charger cet emplacement spécial.',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> refresh() {
    return loadDirectory(_state.currentPath, pushHistory: false);
  }

  Future<void> open(FileEntry entry) {
    if (entry.isApplication) {
      return launchApplication(entry);
    }
    if (entry.isDirectory) {
      return loadDirectory(entry.path);
    }
    if (isLockedPath(entry.path)) {
      _state = _state.copyWith(statusMessage: 'Fichier verrouille');
      notifyListeners();
      return Future.value();
    }
    if (_isArchivePath(entry.path)) {
      return openArchive(entry);
    }
    return openFile(entry);
  }

  Future<void> goToParent() {
    if (_state.isArchiveView && _state.archiveRootPath != null) {
      final root = p.normalize(_state.archiveRootPath!);
      final current = p.normalize(_state.currentPath);
      if (p.equals(root, current)) {
        return exitArchiveView();
      }
    }
    final parent = Directory(_state.currentPath).parent.path;
    if (parent == _state.currentPath) return Future.value();
    return loadDirectory(parent);
  }

  bool get isAtRoot {
    final parent = Directory(_state.currentPath).parent.path;
    return parent == _state.currentPath;
  }

  bool get canGoBack => _backStack.isNotEmpty;
  bool get canGoForward => _forwardStack.isNotEmpty;

  Future<void> goBack() async {
    if (_backStack.isEmpty) return;
    final target = _backStack.removeLast();
    final leavingArchive = _state.isArchiveView && !_isWithinArchive(target);
    final forwardPath = leavingArchive && _state.archivePath != null
        ? _state.archivePath!
        : _state.currentPath;
    _forwardStack.add(forwardPath);
    await loadDirectory(target, pushHistory: false);
  }

  Future<void> goForward() async {
    if (_forwardStack.isEmpty) return;
    final target = _forwardStack.removeLast();
    final leavingArchive = _state.isArchiveView && !_isWithinArchive(target);
    final backPath = leavingArchive && _state.archivePath != null
        ? _state.archivePath!
        : _state.currentPath;
    _backStack.add(backPath);
    await loadDirectory(target, pushHistory: false);
  }

  Future<void> goToLastVisited() async {
    final target = _recentPaths.firstWhere(
      (p) => p != _state.currentPath,
      orElse: () => '',
    );
    if (target.isEmpty) return;
    await loadDirectory(target);
  }

  Future<void> openPackageAsFolder(FileEntry entry) =>
      loadDirectory(entry.path);

  Future<void> _reloadCurrent() {
    return loadDirectory(_state.currentPath, pushHistory: false);
  }
}
