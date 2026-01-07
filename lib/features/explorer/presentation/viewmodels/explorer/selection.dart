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
