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
    await _pasteEntries(_clipboard, destinationPath);
  }

  Future<void> pasteClipboardWithRename(
    Map<String, String> renameMap, [
    String? destinationPath,
  ]) async {
    if (_clipboard.isEmpty) return;
    if (renameMap.isEmpty) {
      await pasteClipboard(destinationPath);
      return;
    }
    final entries = _clipboard.map((entry) {
      final newName = renameMap[entry.path];
      if (newName == null || newName.trim().isEmpty) return entry;
      return FileEntry(
        name: newName.trim(),
        path: entry.path,
        isDirectory: entry.isDirectory,
        size: entry.size,
        lastModified: entry.lastModified,
        isApplication: entry.isApplication,
        iconPath: entry.iconPath,
      );
    }).toList();
    await _pasteEntries(entries, destinationPath);
  }

  Future<void> _pasteEntries(
    List<FileEntry> entries, [
    String? destinationPath,
  ]) async {
    if (entries.isEmpty) return;
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
        await _moveEntries(entries, targetPath);
      } else {
        await _copyEntries(entries, targetPath);
      }
      await _reloadCurrent();
      _state = _state.copyWith(
        statusMessage:
            '${entries.length} element(s) ${_state.isCutOperation ? 'deplaces' : 'colles'}',
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
