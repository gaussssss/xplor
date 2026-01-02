import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/special_locations.dart';
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
    required this.selectedTags,
    required this.selectedTypes,
    required this.recentPaths,
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
  final Set<String> selectedTags;
  final Set<String> selectedTypes;
  final List<String> recentPaths;
  final String? error;
  final String? statusMessage;

  factory ExplorerViewState.initial(String startingPath) {
    return ExplorerViewState(
      currentPath: startingPath,
      entries: const [],
      isLoading: false,
      viewMode: ExplorerViewMode.grid,
      searchQuery: '',
      selectedPaths: <String>{},
      clipboardCount: 0,
      isCutOperation: false,
      selectedTags: const <String>{},
      selectedTypes: const <String>{},
      recentPaths: const [],
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
    Set<String>? selectedTags,
    Set<String>? selectedTypes,
    List<String>? recentPaths,
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
      selectedTags: selectedTags ?? this.selectedTags,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      recentPaths: recentPaths ?? this.recentPaths,
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
  final List<String> _backStack = [];
  final List<String> _forwardStack = [];
  List<String> _recentPaths = [];

  ExplorerViewState get state => _state;

  List<FileEntry> get visibleEntries {
    final query = _state.searchQuery.trim().toLowerCase();
    Iterable<FileEntry> filtered = _state.entries;
    if (query.isNotEmpty) {
      filtered = filtered.where((entry) => entry.name.toLowerCase().contains(query));
    }
    if (_state.selectedTags.isNotEmpty) {
      filtered = filtered.where(_matchesTag);
    }
    if (_state.selectedTypes.isNotEmpty) {
      filtered = filtered.where(_matchesType);
    }
    return filtered.toList();
  }

  Future<void> loadDirectory(
    String path, {
    bool pushHistory = true,
  }) async {
    final targetPath = path.trim().isEmpty ? _state.currentPath : path.trim();
    if (pushHistory && targetPath == _state.currentPath) return;

    // Gérer les emplacements spéciaux
    if (SpecialLocations.isSpecialLocation(targetPath)) {
      return _loadSpecialLocation(targetPath, pushHistory: pushHistory);
    }

    if (pushHistory && _state.currentPath != targetPath) {
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
      await _recordRecent(targetPath);
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

    try {
      List<FileEntry> entries = [];

      // Charger les fichiers récents
      if (locationCode == SpecialLocations.recentFiles) {
        // Créer des entrées virtuelles pour chaque chemin récent
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

              entries.add(FileEntry(
                name: name,
                path: recentPath,
                isDirectory: entity is Directory,
                size: stat.size,
                lastModified: stat.modified,
              ));
            }
          } catch (_) {
            // Ignorer les fichiers qui n'existent plus
          }
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
      await _reloadCurrent();
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
    _state = _state.copyWith(isLoading: true, clearError: true, clearStatus: true);
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
    final entry = _state.entries
        .firstWhere((e) => _state.selectedPaths.contains(e.path));
    _state = _state.copyWith(isLoading: true, clearError: true, clearStatus: true);
    notifyListeners();
    try {
      await _renameEntry(entry, newName);
      await _reloadCurrent();
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

  void setTagFilter(String? tag) {
    _state = _state.copyWith(selectedTags: tag == null ? <String>{} : {tag});
    notifyListeners();
  }

  void toggleTag(String tag) {
    final updated = <String>{..._state.selectedTags};
    if (updated.contains(tag)) {
      updated.remove(tag);
    } else {
      updated.add(tag);
    }
    _state = _state.copyWith(selectedTags: updated);
    notifyListeners();
  }

  void toggleType(String type) {
    final updated = <String>{..._state.selectedTypes};
    if (updated.contains(type)) {
      updated.remove(type);
    } else {
      updated.add(type);
    }
    _state = _state.copyWith(selectedTypes: updated);
    notifyListeners();
  }

  void clearFilters() {
    _state = _state.copyWith(selectedTags: <String>{}, selectedTypes: <String>{});
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
      await _reloadCurrent();
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
  bool get canGoBack => _backStack.isNotEmpty;
  bool get canGoForward => _forwardStack.isNotEmpty;
  Set<String> get selectedTags => _state.selectedTags;
  Set<String> get selectedTypes => _state.selectedTypes;
  List<String> get recentPaths => _state.recentPaths;
  Future<void> openPackageAsFolder(FileEntry entry) =>
      loadDirectory(entry.path);

  Future<void> goBack() async {
    if (_backStack.isEmpty) return;
    final target = _backStack.removeLast();
    _forwardStack.add(_state.currentPath);
    await loadDirectory(target, pushHistory: false);
  }

  Future<void> goForward() async {
    if (_forwardStack.isEmpty) return;
    final target = _forwardStack.removeLast();
    _backStack.add(_state.currentPath);
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

  Future<void> launchApplication(FileEntry entry) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [entry.path]);
      } else if (Platform.isWindows) {
        await Process.run(entry.path, []);
      } else {
        await Process.run('xdg-open', [entry.path]);
      }
      _state = _state.copyWith(statusMessage: 'Application lancee');
    } catch (_) {
      _state =
          _state.copyWith(statusMessage: 'Impossible de lancer l application');
    } finally {
      notifyListeners();
    }
  }

  Future<void> duplicateSelected() async {
    if (_state.selectedPaths.isEmpty) return;
    _state = _state.copyWith(isLoading: true, clearError: true, clearStatus: true);
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

  bool _matchesTag(FileEntry entry) {
    final tags = _state.selectedTags;
    if (tags.isEmpty) return true;
    final lower = entry.name.toLowerCase();
    for (final tag in tags) {
      final extensions = _tagExtensions[tag] ?? [];
      if (extensions.contains('*')) return true;
      if (extensions.any((ext) => lower.endsWith(ext))) {
        return true;
      }
    }
    return false;
  }

  bool _matchesType(FileEntry entry) {
    final filters = _state.selectedTypes;
    if (filters.isEmpty) return true;
    final lower = entry.name.toLowerCase();
    for (final type in filters) {
      final extensions = _typeExtensions[type] ?? [];
      if (extensions.contains('*')) return true;
      if (extensions.any((ext) => lower.endsWith(ext))) {
        return true;
      }
    }
    return false;
  }

  static const Map<String, List<String>> _tagExtensions = {
    'Rouge': ['.jpg', '.jpeg', '.png', '.gif', '.webp'],
    'Orange': ['.mp4', '.mov', '.mkv', '.avi'],
    'Jaune': ['.pdf'],
    'Vert': ['.txt', '.md', '.rtf'],
    'Bleu': ['.doc', '.docx', '.ppt', '.pptx', '.xls', '.xlsx'],
    'Violet': ['.zip', '.tar', '.gz', '.rar', '.7z'],
    'Gris': ['*'],
  };

  static const Map<String, List<String>> _typeExtensions = {
    'Docs': ['.pdf', '.doc', '.docx', '.ppt', '.pptx', '.xls', '.xlsx', '.txt', '.md'],
    'Media': ['.mp4', '.mov', '.mkv', '.avi', '.mp3', '.wav', '.flac', '.jpg', '.jpeg', '.png', '.gif', '.webp'],
    'Archives': ['.zip', '.tar', '.gz', '.rar', '.7z'],
    'Code': ['.dart', '.js', '.ts', '.jsx', '.tsx', '.java', '.kt', '.swift', '.py', '.rb', '.go', '.c', '.cpp', '.rs'],
    'Apps': ['.app', '.exe', '.pkg', '.dmg'],
  };

  static const _recentKey = 'recent_paths';

  Future<void> bootstrap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _recentPaths = prefs.getStringList(_recentKey) ?? [];
      _state = _state.copyWith(recentPaths: List.unmodifiable(_recentPaths));
      notifyListeners();
    } catch (_) {
      // ignore prefs errors
    }
  }

  Future<void> _recordRecent(String path) async {
    if (path.isEmpty) return;
    _recentPaths.remove(path);
    _recentPaths.insert(0, path);
    if (_recentPaths.length > 15) {
      _recentPaths = _recentPaths.sublist(0, 15);
    }
    _state = _state.copyWith(recentPaths: List.unmodifiable(_recentPaths));
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentKey, _recentPaths);
    } catch (_) {
      // ignore persistence errors
    }
  }

  Future<void> _reloadCurrent() {
    return loadDirectory(_state.currentPath, pushHistory: false);
  }

  Future<void> openTerminalHere([String? path]) async {
    final target = path ?? _state.currentPath;
    try {
      if (Platform.isMacOS) {
        await Process.run('open', ['-a', 'Terminal', target]);
      } else if (Platform.isWindows) {
        await Process.run(
          'cmd',
          ['/C', 'start', 'cmd', '/K', 'cd /d "$target"'],
        );
      } else {
        await Process.run('xdg-open', [target]);
      }
      _state = _state.copyWith(statusMessage: 'Terminal ouvert');
    } catch (_) {
      _state = _state.copyWith(statusMessage: 'Impossible d ouvrir le terminal');
    } finally {
      notifyListeners();
    }
  }

  void copyPathToClipboard(String path) {
    Clipboard.setData(ClipboardData(text: path));
    _state = _state.copyWith(statusMessage: 'Chemin copie');
    notifyListeners();
  }

  Future<void> compressSelected() async {
    if (_state.selectedPaths.isEmpty) return;
    // Best-effort simple zip on macOS/Linux.
    if (Platform.isWindows) {
      _state = _state.copyWith(statusMessage: 'Compression non supportee ici');
      notifyListeners();
      return;
    }
    final entries = _state.entries
        .where((e) => _state.selectedPaths.contains(e.path))
        .toList();
    if (entries.isEmpty) return;

    final archiveName = _uniqueArchiveName();
    _state = _state.copyWith(isLoading: true, clearStatus: true, clearError: true);
    notifyListeners();
    try {
      final args = [
        '-r',
        archiveName,
        ...entries.map((e) => e.path.split(Platform.pathSeparator).last),
      ];
      final result = await Process.run('zip', args, workingDirectory: _state.currentPath);
      if (result.exitCode != 0) {
        throw Exception(result.stderr);
      }
      await _reloadCurrent();
      _state = _state.copyWith(
        isLoading: false,
        statusMessage: 'Archive creee: $archiveName',
      );
    } catch (_) {
      _state = _state.copyWith(
        isLoading: false,
        statusMessage: 'Echec de la compression',
      );
    } finally {
      notifyListeners();
    }
  }

  String _uniqueArchiveName() {
    var base = 'Archive.zip';
    var counter = 1;
    while (File('${_state.currentPath}${Platform.pathSeparator}$base').existsSync()) {
      base = 'Archive_$counter.zip';
      counter++;
    }
    return base;
  }
}
