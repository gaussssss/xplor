part of '../explorer_view_model.dart';

extension ExplorerClipboardOps on ExplorerViewModel {
  bool get canPaste => _clipboard.isNotEmpty;

  void copySelectionToClipboard() {
    if (_state.selectedPaths.isEmpty) return;
    _clipboard = _state.entries
        .where((entry) => _state.selectedPaths.contains(entry.path))
        .toList();
    _state = _state.copyWith(
      clipboardCount: _clipboard.length,
      isCutOperation: false,
      statusMessage: 'Copie en memoire',
      clearError: true,
    );
    notifyListeners();
    unawaited(_cleanupStagedArchiveRoots());
  }

  void cutSelectionToClipboard() {
    if (_state.selectedPaths.isEmpty) return;
    if (_blockArchiveWrite('Impossible de couper dans une archive')) return;
    _clipboard = _state.entries
        .where((entry) => _state.selectedPaths.contains(entry.path))
        .toList();
    _state = _state.copyWith(
      clipboardCount: _clipboard.length,
      isCutOperation: true,
      statusMessage: 'Coupe en memoire',
      clearError: true,
    );
    notifyListeners();
    unawaited(_cleanupStagedArchiveRoots());
  }

  Future<void> pasteClipboard([String? destinationPath]) async {
    if (_clipboard.isEmpty) return;
    final targetPath = destinationPath ?? _state.currentPath;
    if (_state.isArchiveView || _isWithinArchive(targetPath)) {
      _state = _state.copyWith(
        statusMessage: 'Impossible de coller dans une archive',
        clearError: true,
      );
      notifyListeners();
      return;
    }
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );
    notifyListeners();
    try {
      if (_state.isCutOperation) {
        await _moveEntries(_clipboard, targetPath);
      } else {
        await _copyEntries(_clipboard, targetPath);
      }
      await _reloadCurrent();
      _state = _state.copyWith(
        statusMessage:
            '${_clipboard.length} element(s) ${_state.isCutOperation ? 'deplaces' : 'colles'}',
        isLoading: false,
        isCutOperation: false,
        clipboardCount: 0,
      );
      _clipboard = [];
      unawaited(_cleanupStagedArchiveRoots());
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  Future<void> moveEntriesTo(
    List<FileEntry> entries,
    String destinationPath,
  ) async {
    if (entries.isEmpty) return;
    if (_state.isArchiveView || _isWithinArchive(destinationPath)) {
      _state = _state.copyWith(
        statusMessage: 'Deplacement non supporte dans une archive',
        clearError: true,
      );
      notifyListeners();
      return;
    }
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );
    notifyListeners();
    try {
      await _moveEntries(entries, destinationPath);
      await _reloadCurrent();
      _state = _state.copyWith(
        statusMessage: '${entries.length} element(s) deplace(s)',
        isLoading: false,
      );
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }
}
