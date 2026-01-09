part of '../explorer_view_model.dart';

extension ExplorerFileOps on ExplorerViewModel {
  Future<void> createFolder(String name) async {
    if (_blockArchiveWrite('Impossible de creer un dossier dans une archive')) {
      return;
    }
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );
    notifyListeners();
    try {
      await _createDirectory(_state.currentPath, name);
      await _reloadCurrent();
      _state = _state.copyWith(
        statusMessage: 'Dossier cree',
        clearError: true,
        isLoading: false,
      );
      // Mettre a jour l'index
      _updateIndexInBackground(_state.currentPath);
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteSelected() async {
    if (_state.selectedPaths.isEmpty) return;
    if (_blockArchiveWrite('Suppression non supportee dans une archive')) {
      return;
    }
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );
    notifyListeners();
    try {
      final toDelete = _state.entries
          .where((entry) => _state.selectedPaths.contains(entry.path))
          .toList();
      if (_state.currentPath == SpecialLocations.trash) {
        await _deleteEntries(toDelete);
        _state = _state.copyWith(
          statusMessage: '${toDelete.length} element(s) supprime(s)',
          isLoading: false,
        );
        await _reloadCurrent();
        notifyListeners();
        return;
      }
      if (Platform.isMacOS) {
        await _moveEntriesToTrash(toDelete);
      } else {
        await _deleteEntries(toDelete);
      }
      await _reloadCurrent();
      _state = _state.copyWith(
        statusMessage: '${toDelete.length} element(s) supprime(s)',
        isLoading: false,
      );
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  Future<void> restoreSelectedFromTrash() async {
    if (_state.selectedPaths.isEmpty) return;
    if (_state.currentPath != SpecialLocations.trash) return;
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );
    notifyListeners();
    try {
      final toRestore = _state.entries
          .where((entry) => _state.selectedPaths.contains(entry.path))
          .toList();
      if (!Platform.isMacOS) {
        _state = _state.copyWith(
          isLoading: false,
          error: 'Restauration non supportee sur cette plateforme.',
        );
        return;
      }
      for (final entry in toRestore) {
        await _putBackFromTrash(entry.path);
      }
      await _reloadCurrent();
      _state = _state.copyWith(
        statusMessage: '${toRestore.length} element(s) restaure(s)',
        isLoading: false,
      );
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } catch (_) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Impossible de restaurer les elements.',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> _moveEntriesToTrash(List<FileEntry> entries) async {
    for (final entry in entries) {
      final script = 'tell application "Finder" to delete POSIX file "${_escapeAppleScriptPath(entry.path)}"';
      final result = await Process.run('osascript', ['-e', script]);
      if (result.exitCode != 0) {
        throw FileSystemException(
          'Echec de suppression vers la corbeille',
          entry.path,
        );
      }
    }
  }

  Future<void> _putBackFromTrash(String path) async {
    final script = 'tell application "Finder" to put back (POSIX file "${_escapeAppleScriptPath(path)}")';
    final result = await Process.run('osascript', ['-e', script]);
    if (result.exitCode != 0) {
      throw FileSystemException('Echec de restauration', path);
    }
  }

  String _escapeAppleScriptPath(String path) {
    return path.replaceAll('"', '\\"');
  }

  Future<void> moveSelected(String destinationPath) async {
    if (_state.selectedPaths.isEmpty) return;
    if (_blockArchiveWrite('Deplacement non supporte dans une archive')) {
      return;
    }
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );
    notifyListeners();
    try {
      final toMove = _state.entries
          .where((entry) => _state.selectedPaths.contains(entry.path))
          .toList();
      await _moveEntries(toMove, destinationPath);
      await _reloadCurrent();
      _state = _state.copyWith(
        statusMessage: '${toMove.length} element(s) deplace(s)',
        isLoading: false,
      );
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  Future<void> renameSelected(String newName) async {
    if (_state.selectedPaths.length != 1) return;
    if (_blockArchiveWrite('Renommage non supporte dans une archive')) {
      return;
    }
    final entry = _state.entries.firstWhere(
      (e) => _state.selectedPaths.contains(e.path),
    );
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );
    notifyListeners();
    try {
      await _renameEntry(entry, newName);
      await _reloadCurrent();
      _state = _state.copyWith(
        statusMessage: 'Renomme avec succes',
        isLoading: false,
      );
      // Mettre a jour l'index
      _updateIndexInBackground(_state.currentPath);
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  Future<void> duplicateSelected() async {
    if (_state.selectedPaths.isEmpty) return;
    if (_blockArchiveWrite('Duplication non supportee dans une archive')) {
      return;
    }
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );
    notifyListeners();
    try {
      final toDuplicate = _state.entries
          .where((entry) => _state.selectedPaths.contains(entry.path))
          .toList();
      await _duplicateEntries(toDuplicate);
      await _reloadCurrent();
      _state = _state.copyWith(
        statusMessage: '${toDuplicate.length} element(s) dupliques',
        isLoading: false,
      );
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }
}
