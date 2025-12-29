import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../domain/entities/file_entry.dart';
import '../../domain/usecases/copy_entries.dart';
import '../../domain/usecases/create_directory.dart';
import '../../domain/usecases/delete_entries.dart';
import '../../domain/usecases/duplicate_entries.dart';
import '../../domain/usecases/list_directory_entries.dart';
import '../../domain/usecases/move_entries.dart';
import '../../domain/usecases/rename_entry.dart';

enum ExplorerViewMode { list, grid }

class ExplorerViewState {
  const ExplorerViewState({
    required this.currentPath,
    required this.entries,
    required this.isLoading,
    required this.viewMode,
    required this.searchQuery,
    required this.selectedPaths,
    required this.clipboardCount,
    required this.isCutOperation,
    this.error,
    this.statusMessage,
  });

  final String currentPath;
  final List<FileEntry> entries;
  final bool isLoading;
  final ExplorerViewMode viewMode;
  final String searchQuery;
  final Set<String> selectedPaths;
  final int clipboardCount;
  final bool isCutOperation;
  final String? error;
  final String? statusMessage;

  factory ExplorerViewState.initial(String startingPath) {
    return ExplorerViewState(
      currentPath: startingPath,
      entries: const [],
      isLoading: false,
      viewMode: ExplorerViewMode.list,
      searchQuery: '',
      selectedPaths: <String>{},
      clipboardCount: 0,
      isCutOperation: false,
    );
  }

  ExplorerViewState copyWith({
    String? currentPath,
    List<FileEntry>? entries,
    bool? isLoading,
    ExplorerViewMode? viewMode,
    String? searchQuery,
    Set<String>? selectedPaths,
    int? clipboardCount,
    bool? isCutOperation,
    String? error,
    String? statusMessage,
    bool clearError = false,
    bool clearStatus = false,
  }) {
    return ExplorerViewState(
      currentPath: currentPath ?? this.currentPath,
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      viewMode: viewMode ?? this.viewMode,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedPaths: selectedPaths ?? this.selectedPaths,
      clipboardCount: clipboardCount ?? this.clipboardCount,
      isCutOperation: isCutOperation ?? this.isCutOperation,
      error: clearError ? null : (error ?? this.error),
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
    );
  }
}

class ExplorerViewModel extends ChangeNotifier {
  ExplorerViewModel({
    required ListDirectoryEntries listDirectoryEntries,
    required CreateDirectory createDirectory,
    required DeleteEntries deleteEntries,
    required MoveEntries moveEntries,
    required CopyEntries copyEntries,
    required DuplicateEntries duplicateEntries,
    required RenameEntry renameEntry,
    required String initialPath,
  })  : _listDirectoryEntries = listDirectoryEntries,
        _createDirectory = createDirectory,
        _deleteEntries = deleteEntries,
        _moveEntries = moveEntries,
        _copyEntries = copyEntries,
        _duplicateEntries = duplicateEntries,
        _renameEntry = renameEntry,
        _state = ExplorerViewState.initial(initialPath);

  final ListDirectoryEntries _listDirectoryEntries;
  final CreateDirectory _createDirectory;
  final DeleteEntries _deleteEntries;
  final MoveEntries _moveEntries;
  final CopyEntries _copyEntries;
  final DuplicateEntries _duplicateEntries;
  final RenameEntry _renameEntry;
  ExplorerViewState _state;
  List<FileEntry> _clipboard = [];

  ExplorerViewState get state => _state;

  List<FileEntry> get visibleEntries {
    final query = _state.searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _state.entries;

    return _state.entries
        .where((entry) => entry.name.toLowerCase().contains(query))
        .toList();
  }

  Future<void> loadDirectory(String path) async {
    final targetPath = path.trim().isEmpty ? _state.currentPath : path.trim();
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
    }
  }

  Future<void> refresh() {
    return loadDirectory(_state.currentPath);
  }

  Future<void> open(FileEntry entry) {
    if (!entry.isDirectory) return Future.value();
    return loadDirectory(entry.path);
  }

  Future<void> goToParent() {
    final parent = Directory(_state.currentPath).parent.path;
    if (parent == _state.currentPath) return Future.value();
    return loadDirectory(parent);
  }

  void toggleSelection(FileEntry entry) {
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
    _state = _state.copyWith(
      selectedPaths: {entry.path},
      clearStatus: true,
    );
    notifyListeners();
  }

  bool isSelected(FileEntry entry) => _state.selectedPaths.contains(entry.path);

  Future<void> createFolder(String name) async {
    _state = _state.copyWith(isLoading: true, clearError: true, clearStatus: true);
    notifyListeners();
    try {
      await _createDirectory(_state.currentPath, name);
      await loadDirectory(_state.currentPath);
      _state = _state.copyWith(
        statusMessage: 'Dossier cree',
        clearError: true,
        isLoading: false,
      );
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteSelected() async {
    if (_state.selectedPaths.isEmpty) return;
    _state = _state.copyWith(isLoading: true, clearError: true, clearStatus: true);
    notifyListeners();
    try {
      final toDelete = _state.entries
          .where((entry) => _state.selectedPaths.contains(entry.path))
          .toList();
      await _deleteEntries(toDelete);
      await loadDirectory(_state.currentPath);
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
    _state = _state.copyWith(isLoading: true, clearError: true, clearStatus: true);
    notifyListeners();
    try {
      final toMove = _state.entries
          .where((entry) => _state.selectedPaths.contains(entry.path))
          .toList();
      await _moveEntries(toMove, destinationPath);
      await loadDirectory(_state.currentPath);
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
    final entry = _state.entries
        .firstWhere((e) => _state.selectedPaths.contains(e.path));
    _state = _state.copyWith(isLoading: true, clearError: true, clearStatus: true);
    notifyListeners();
    try {
      await _renameEntry(entry, newName);
      await loadDirectory(_state.currentPath);
      _state = _state.copyWith(
        statusMessage: 'Renomme avec succes',
        isLoading: false,
      );
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  void updateSearch(String query) {
    _state = _state.copyWith(searchQuery: query);
    notifyListeners();
  }

  void setViewMode(ExplorerViewMode mode) {
    if (_state.viewMode == mode) return;
    _state = _state.copyWith(viewMode: mode);
    notifyListeners();
  }

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
  }

  void cutSelectionToClipboard() {
    if (_state.selectedPaths.isEmpty) return;
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
  }

  Future<void> pasteClipboard([String? destinationPath]) async {
    if (_clipboard.isEmpty) return;
    final targetPath = destinationPath ?? _state.currentPath;
    _state = _state.copyWith(isLoading: true, clearError: true, clearStatus: true);
    notifyListeners();
    try {
      if (_state.isCutOperation) {
        await _moveEntries(_clipboard, targetPath);
      } else {
        await _copyEntries(_clipboard, targetPath);
      }
      await loadDirectory(_state.currentPath);
      _state = _state.copyWith(
        statusMessage:
            '${_clipboard.length} element(s) ${_state.isCutOperation ? 'deplaces' : 'colles'}',
        isLoading: false,
        isCutOperation: false,
        clipboardCount: 0,
      );
      _clipboard = [];
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  Future<void> moveEntriesTo(List<FileEntry> entries, String destinationPath) async {
    if (entries.isEmpty) return;
    _state = _state.copyWith(isLoading: true, clearError: true, clearStatus: true);
    notifyListeners();
    try {
      await _moveEntries(entries, destinationPath);
      await loadDirectory(_state.currentPath);
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

  void clearStatus() {
    if (_state.statusMessage == null) return;
    _state = _state.copyWith(statusMessage: null);
    notifyListeners();
  }

  bool get isAtRoot {
    final parent = Directory(_state.currentPath).parent.path;
    return parent == _state.currentPath;
  }

  bool get canPaste => _clipboard.isNotEmpty;

  Future<void> duplicateSelected() async {
    if (_state.selectedPaths.isEmpty) return;
    _state = _state.copyWith(isLoading: true, clearError: true, clearStatus: true);
    notifyListeners();
    try {
      final toDuplicate = _state.entries
          .where((entry) => _state.selectedPaths.contains(entry.path))
          .toList();
      await _duplicateEntries(toDuplicate);
      await loadDirectory(_state.currentPath);
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

  Future<void> openInFinder(FileEntry entry) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', entry.path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', entry.path]);
      } else {
        await Process.run('xdg-open', [Directory(entry.path).parent.path]);
      }
    } catch (_) {
      _state = _state.copyWith(statusMessage: 'Impossible d ouvrir dans Finder');
      notifyListeners();
    }
  }
}
