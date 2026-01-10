part of '../explorer_view_model.dart';

extension ExplorerSelectionOps on ExplorerViewModel {
  void toggleSelection(FileEntry entry) {
    if (!_multiSelectionEnabled) {
      selectSingle(entry);
      return;
    }
    final updated = <String>{..._state.selectedPaths};
    if (updated.contains(entry.path)) {
      updated.remove(entry.path);
    } else {
      updated.add(entry.path);
    }
    _state = _state.copyWith(selectedPaths: updated, clearStatus: true);
    notifyListeners();
  }

  void clearSelection() {
    if (_state.selectedPaths.isEmpty) return;
    _state = _state.copyWith(selectedPaths: <String>{}, clearStatus: true);
    notifyListeners();
  }

  void selectSingle(FileEntry entry) {
    if (_state.selectedPaths.length == 1 &&
        _state.selectedPaths.contains(entry.path)) {
      return;
    }
    _state = _state.copyWith(selectedPaths: {entry.path}, clearStatus: true);
    notifyListeners();
  }

  void selectPath(String path) {
    FileEntry? entry;
    try {
      entry = _state.entries.firstWhere((e) => e.path == path);
    } catch (_) {}
    if (entry != null) selectSingle(entry);
  }

  void selectRange(List<FileEntry> orderedEntries, int anchorIndex, int targetIndex) {
    if (orderedEntries.isEmpty) return;
    final start = anchorIndex < targetIndex ? anchorIndex : targetIndex;
    final end = anchorIndex > targetIndex ? anchorIndex : targetIndex;
    final clampedStart = start.clamp(0, orderedEntries.length - 1);
    final clampedEnd = end.clamp(0, orderedEntries.length - 1);
    final selected = orderedEntries
        .sublist(clampedStart, clampedEnd + 1)
        .map((e) => e.path)
        .toSet();
    _state = _state.copyWith(selectedPaths: selected, clearStatus: true);
    notifyListeners();
  }

  void selectAllVisible({bool force = false}) {
    if (!_multiSelectionEnabled && !force) return;
    final entries = visibleEntries;
    if (entries.isEmpty) return;
    _state = _state.copyWith(
      selectedPaths: entries.map((entry) => entry.path).toSet(),
      clearStatus: true,
    );
    notifyListeners();
  }

  void setMultiSelectionEnabled(bool enabled) {
    if (_multiSelectionEnabled == enabled) return;
    _multiSelectionEnabled = enabled;
    if (!enabled) {
      _collapseToSingleSelection();
    }
  }

  void _collapseToSingleSelection() {
    if (_state.selectedPaths.length <= 1) return;
    FileEntry? keepEntry;
    for (final entry in _state.entries) {
      if (_state.selectedPaths.contains(entry.path)) {
        keepEntry = entry;
        break;
      }
    }
    if (keepEntry != null) {
      _state = _state.copyWith(
        selectedPaths: {keepEntry.path},
        clearStatus: true,
      );
    } else {
      _state = _state.copyWith(
        selectedPaths: <String>{},
        clearStatus: true,
      );
    }
    notifyListeners();
  }

  bool isSelected(FileEntry entry) => _state.selectedPaths.contains(entry.path);
}
