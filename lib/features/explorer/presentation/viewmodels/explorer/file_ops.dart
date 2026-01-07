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
      await _deleteEntries(toDelete);
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
