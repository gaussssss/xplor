import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
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
import '../../../search/domain/usecases/search_files_progressive.dart';
import '../../../search/domain/usecases/build_index.dart';
import '../../../search/domain/usecases/update_index.dart';
import '../../../search/domain/usecases/get_index_status.dart';
import '../../../search/domain/entities/search_result.dart';
import 'search_view_model.dart';

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
    required this.isArchiveView,
    this.archivePath,
    this.archiveRootPath,
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
  final bool isArchiveView;
  final String? archivePath;
  final String? archiveRootPath;
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
      isArchiveView: false,
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
    bool? isArchiveView,
    String? archivePath,
    String? archiveRootPath,
    String? error,
    String? statusMessage,
    bool clearError = false,
    bool clearStatus = false,
    bool clearArchive = false,
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
      isArchiveView: isArchiveView ?? this.isArchiveView,
      archivePath: clearArchive ? null : (archivePath ?? this.archivePath),
      archiveRootPath:
          clearArchive ? null : (archiveRootPath ?? this.archiveRootPath),
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
    required SearchFilesProgressive searchFilesProgressive,
    required BuildIndex buildIndex,
    required UpdateIndex updateIndex,
    required GetIndexStatus getIndexStatus,
  }) : _listDirectoryEntries = listDirectoryEntries,
       _createDirectory = createDirectory,
       _deleteEntries = deleteEntries,
       _moveEntries = moveEntries,
       _copyEntries = copyEntries,
       _duplicateEntries = duplicateEntries,
       _renameEntry = renameEntry,
       _searchViewModel = SearchViewModel(
         searchFilesProgressive: searchFilesProgressive,
         buildIndex: buildIndex,
         updateIndex: updateIndex,
       ),
       _state = ExplorerViewState.initial(initialPath);

  final ListDirectoryEntries _listDirectoryEntries;
  final CreateDirectory _createDirectory;
  final DeleteEntries _deleteEntries;
  final MoveEntries _moveEntries;
  final CopyEntries _copyEntries;
  final DuplicateEntries _duplicateEntries;
  final RenameEntry _renameEntry;
  late final SearchViewModel _searchViewModel;
  ExplorerViewState _state;
  List<FileEntry> _clipboard = [];
  final List<String> _backStack = [];
  final List<String> _forwardStack = [];
  List<String> _recentPaths = [];
  final List<String> _stagedArchiveRoots = [];
  static const List<String> _archiveExtensions = [
    '.zip',
    '.zipx',
    '.jar',
    '.war',
    '.ear',
    '.apk',
    '.ipa',
    '.xpi',
    '.crx',
    '.whl',
    '.nupkg',
    '.vsix',
    '.appx',
    '.msix',
    '.docx',
    '.xlsx',
    '.pptx',
    '.odt',
    '.ods',
    '.odp',
    '.epub',
    '.pages',
    '.numbers',
    '.key',
    '.sketch',
    '.7z',
    '.rar',
    '.r00',
    '.r01',
    '.r02',
    '.cab',
    '.xar',
    '.iso',
    '.dmg',
    '.cpio',
    '.ar',
    '.deb',
    '.rpm',
    '.tar',
    '.tgz',
    '.tar.gz',
    '.tar.bz2',
    '.tbz',
    '.tbz2',
    '.tar.xz',
    '.txz',
    '.tar.zst',
    '.tzst',
    '.tar.lz',
    '.tar.lzma',
    '.tar.z',
    '.gz',
    '.gzip',
    '.bz2',
    '.xz',
    '.lzma',
    '.zst',
    '.lz4',
    '.z',
    '.br',
    '.cbz',
    '.cbr',
    '.cb7',
    '.cbt',
  ];
  static final RegExp _rarPartRegex = RegExp(r'\\.part\\d+\\.rar$');
  static final RegExp _sevenZipPartRegex = RegExp(r'\\.7z\\.\\d{3}$');

  ExplorerViewState get state => _state;
  bool get isArchiveView => _state.isArchiveView;
  String get displayPath => _formatDisplayPath(_state.currentPath);

  String _formatDisplayPath(String currentPath) {
    if (!_state.isArchiveView ||
        _state.archivePath == null ||
        _state.archiveRootPath == null) {
      return currentPath;
    }
    final root = p.normalize(_state.archiveRootPath!);
    final current = p.normalize(currentPath);
    if (!p.isWithin(root, current) && !p.equals(root, current)) {
      return currentPath;
    }
    final relative = p.relative(current, from: root);
    if (relative.isEmpty || relative == '.') {
      return _state.archivePath!;
    }
    return p.join(_state.archivePath!, relative);
  }

  bool _isArchivePath(String path) {
    final lower = path.toLowerCase();
    if (_archiveExtensions.any((ext) => lower.endsWith(ext))) {
      return true;
    }
    if (_rarPartRegex.hasMatch(lower) || _sevenZipPartRegex.hasMatch(lower)) {
      return true;
    }
    return false;
  }

  bool _isWithinArchive(String path) {
    if (!_state.isArchiveView || _state.archiveRootPath == null) {
      return false;
    }
    final root = p.normalize(_state.archiveRootPath!);
    final target = p.normalize(path);
    return p.equals(root, target) || p.isWithin(root, target);
  }

  bool _isWithinRoot(String rootPath, String targetPath) {
    final root = p.normalize(rootPath);
    final target = p.normalize(targetPath);
    return p.equals(root, target) || p.isWithin(root, target);
  }

  bool _clipboardReferencesRoot(String rootPath) {
    return _clipboard.any((entry) => _isWithinRoot(rootPath, entry.path));
  }

  Future<void> _cleanupStagedArchiveRoots() async {
    if (_stagedArchiveRoots.isEmpty) return;
    final remaining = <String>[];
    for (final root in _stagedArchiveRoots) {
      if (_clipboardReferencesRoot(root)) {
        remaining.add(root);
        continue;
      }
      try {
        final dir = Directory(root);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (_) {
        remaining.add(root);
      }
    }
    _stagedArchiveRoots
      ..clear()
      ..addAll(remaining);
  }

  List<FileEntry> get visibleEntries {
    final query = _state.searchQuery.trim().toLowerCase();
    Iterable<FileEntry> filtered = _state.entries;
    // Si une recherche globale est en cours, afficher les résultats globaux
    if (query.isNotEmpty && _searchViewModel.globalSearchResults.isNotEmpty) {
      return _searchViewModel.globalSearchResults
          .map(
            (result) => FileEntry(
              name: result.name,
              path: result.path,
              isDirectory: result.isDirectory,
              size: result.size,
              lastModified: result.lastModified,
              isApplication: false,
            ),
          )
          .toList();
    }
    // Sinon filtrer les fichiers locaux
    if (query.isNotEmpty) {
      filtered = filtered.where(
        (entry) => entry.name.toLowerCase().contains(query),
      );
    }
    if (_state.selectedTags.isNotEmpty) {
      filtered = filtered.where(_matchesTag);
    }
    if (_state.selectedTypes.isNotEmpty) {
      filtered = filtered.where(_matchesType);
    }
    return filtered.toList();
  }

  /// Retourne les résultats de recherche globale
  List<SearchResult> get globalSearchResults => _searchViewModel.globalSearchResults;

  /// Effectue une recherche globale dans les sous-répertoires avec affichage progressif
  Future<void> globalSearch(String query) async {
    if (query.trim().isEmpty) {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      await _searchViewModel.globalSearch(
        query,
        rootPath: _state.currentPath,
        onUpdate: notifyListeners,
      );
    } catch (_) {
      // Ignorer les erreurs
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
    }
  }

  /// Construit l'index du répertoire courant
  Future<void> buildSearchIndex() async {
    await _searchViewModel.buildSearchIndex(_state.currentPath);
  }

  /// Met à jour l'index si nécessaire
  Future<void> updateSearchIndex() async {
    await _searchViewModel.updateSearchIndex(_state.currentPath);
  }

  Future<void> loadDirectory(String path, {bool pushHistory = true}) async {
    final targetPath = path.trim().isEmpty ? _state.currentPath : path.trim();
    if (pushHistory && targetPath == _state.currentPath) return;
    final wasArchiveView = _state.isArchiveView;
    final archivePath = _state.archivePath;
    final leavingArchive = wasArchiveView && !_isWithinArchive(targetPath);

    // Gérer les emplacements spéciaux
    if (SpecialLocations.isSpecialLocation(targetPath)) {
      if (leavingArchive) {
        await _closeArchiveSession(notify: false);
      }
      return _loadSpecialLocation(targetPath, pushHistory: pushHistory);
    }

    if (_isArchivePath(targetPath) &&
        FileSystemEntity.typeSync(targetPath) ==
            FileSystemEntityType.file) {
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
      final historyPath =
          leavingArchive && archivePath != null ? archivePath : _state.currentPath;
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

      // Mettre à jour l'index en arrière-plan (au lieu de rebuilder)
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
    if (entry.isDirectory) {
      return loadDirectory(entry.path);
    }
    if (_isArchivePath(entry.path)) {
      return openArchive(entry);
    }
    return openFile(entry);
  }

  Future<void> openArchive(FileEntry entry, {bool pushHistory = true}) async {
    final archivePath = entry.path;
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
      selectedPaths: <String>{},
    );
    notifyListeners();
    try {
      if (_state.isArchiveView && !_isWithinArchive(archivePath)) {
        await _closeArchiveSession(notify: false);
      }
      final extractedRoot = await _prepareArchiveExtraction(archivePath);
      _state = _state.copyWith(
        isArchiveView: true,
        archivePath: archivePath,
        archiveRootPath: extractedRoot,
      );
      await loadDirectory(extractedRoot, pushHistory: pushHistory);
    } catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Impossible d ouvrir l archive.',
      );
      notifyListeners();
    }
  }

  Future<void> exitArchiveView() async {
    if (!_state.isArchiveView || _state.archivePath == null) return;
    final parentPath = Directory(_state.archivePath!).parent.path;
    await loadDirectory(parentPath);
  }

  Future<void> extractArchiveTo(String destinationPath) async {
    if (!_state.isArchiveView || _state.archiveRootPath == null) return;
    final target = destinationPath.trim();
    if (target.isEmpty) return;
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );
    notifyListeners();
    try {
      await _copyDirectoryContents(_state.archiveRootPath!, target);
      _state = _state.copyWith(
        isLoading: false,
        statusMessage: 'Archive extraite',
      );
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  Future<void> extractSelectionTo(String destinationPath) async {
    if (!_state.isArchiveView || _state.archiveRootPath == null) return;
    final target = destinationPath.trim();
    if (target.isEmpty) return;
    final entries = _state.entries
        .where((entry) => _state.selectedPaths.contains(entry.path))
        .toList();
    if (entries.isEmpty) return;
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );
    notifyListeners();
    try {
      await _copyEntries(entries, target);
      _state = _state.copyWith(
        isLoading: false,
        statusMessage: '${entries.length} element(s) extrait(s)',
      );
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
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
    _state = _state.copyWith(selectedPaths: {entry.path}, clearStatus: true);
    notifyListeners();
  }

  bool isSelected(FileEntry entry) => _state.selectedPaths.contains(entry.path);

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
      // Mettre à jour l'index
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
      // Mettre à jour l'index
      _updateIndexInBackground(_state.currentPath);
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  void updateSearch(String query) {
    _state = _state.copyWith(searchQuery: query);
    notifyListeners();

    _searchViewModel.updateSearch(
      query,
      currentPath: _state.currentPath,
      onUpdate: notifyListeners,
    );
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
    _state = _state.copyWith(
      selectedTags: <String>{},
      selectedTypes: <String>{},
    );
    notifyListeners();
  }

  void setViewMode(ExplorerViewMode mode) async {
    if (_state.viewMode == mode) return;
    _state = _state.copyWith(viewMode: mode);
    notifyListeners();

    // Sauvegarder le mode de vue
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'view_mode',
        mode == ExplorerViewMode.list ? 'list' : 'grid',
      );
    } catch (_) {
      // Ignorer les erreurs de sauvegarde
    }
  }

  bool _blockArchiveWrite(String message) {
    if (!_state.isArchiveView) return false;
    _state = _state.copyWith(statusMessage: message, clearError: true);
    notifyListeners();
    return true;
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
    final leavingArchive =
        _state.isArchiveView && !_isWithinArchive(target);
    final forwardPath = leavingArchive && _state.archivePath != null
        ? _state.archivePath!
        : _state.currentPath;
    _forwardStack.add(forwardPath);
    await loadDirectory(target, pushHistory: false);
  }

  Future<void> goForward() async {
    if (_forwardStack.isEmpty) return;
    final target = _forwardStack.removeLast();
    final leavingArchive =
        _state.isArchiveView && !_isWithinArchive(target);
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
      _state = _state.copyWith(
        statusMessage: 'Impossible de lancer l application',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> openFile(FileEntry entry) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [entry.path]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', entry.path]);
      } else {
        await Process.run('xdg-open', [entry.path]);
      }
      _state = _state.copyWith(statusMessage: 'Fichier ouvert');
    } catch (_) {
      _state = _state.copyWith(
        statusMessage: 'Impossible d ouvrir le fichier',
      );
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
      _state = _state.copyWith(
        statusMessage: 'Impossible d ouvrir dans Finder',
      );
      notifyListeners();
    }
  }

  Future<String> _prepareArchiveExtraction(String archivePath) async {
    final tempDir = await Directory.systemTemp.createTemp('xplor_archive_');
    await _extractArchive(archivePath, tempDir.path);
    return tempDir.path;
  }

  Future<void> _closeArchiveSession({bool notify = true}) async {
    final root = _state.archiveRootPath;
    _state = _state.copyWith(isArchiveView: false, clearArchive: true);
    if (notify) {
      notifyListeners();
    }
    if (root == null) return;
    if (_clipboardReferencesRoot(root)) {
      if (!_stagedArchiveRoots.contains(root)) {
        _stagedArchiveRoots.add(root);
      }
      return;
    }
    try {
      final dir = Directory(root);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      // Ignorer les erreurs de nettoyage
    }
  }

  Future<void> _extractArchive(
    String archivePath,
    String destinationPath,
  ) async {
    final tools = <({String cmd, List<String> args})>[
      (
        cmd: '7z',
        args: ['x', '-y', '-o$destinationPath', archivePath],
      ),
      (
        cmd: 'unar',
        args: ['-quiet', '-output-directory', destinationPath, archivePath],
      ),
      (
        cmd: 'bsdtar',
        args: ['-xf', archivePath, '-C', destinationPath],
      ),
      (
        cmd: 'unzip',
        args: ['-q', '-o', archivePath, '-d', destinationPath],
      ),
      (
        cmd: 'tar',
        args: ['-xf', archivePath, '-C', destinationPath],
      ),
    ];

    String? lastError;
    for (final tool in tools) {
      if (!await _commandExists(tool.cmd)) {
        continue;
      }
      final result = await Process.run(tool.cmd, tool.args);
      if (result.exitCode == 0) {
        return;
      }
      final stderrText = result.stderr is String
          ? result.stderr as String
          : result.stderr.toString();
      final stdoutText = result.stdout is String
          ? result.stdout as String
          : result.stdout.toString();
      lastError = stderrText.trim().isNotEmpty
          ? stderrText.trim()
          : stdoutText.trim();
    }
    throw FileSystemException(
      lastError ?? 'Extraction impossible',
      archivePath,
    );
  }

  Future<bool> _commandExists(String command) async {
    final checker = Platform.isWindows ? 'where' : 'which';
    final result = await Process.run(checker, [command]);
    return result.exitCode == 0;
  }

  Future<void> _copyDirectoryContents(
    String sourcePath,
    String destinationPath,
  ) async {
    final sourceDir = Directory(sourcePath);
    if (!await sourceDir.exists()) {
      throw FileSystemException('Source introuvable', sourcePath);
    }
    final destinationDir = Directory(destinationPath);
    if (!await destinationDir.exists()) {
      throw FileSystemException('Destination introuvable', destinationPath);
    }

    await for (final entity
        in sourceDir.list(recursive: false, followLinks: false)) {
      final name = p.basename(entity.path);
      final targetPath = p.join(destinationDir.path, name);
      if (entity is Directory) {
        await _copyDirectory(Directory(entity.path), Directory(targetPath));
      } else if (entity is File) {
        await _copyFile(File(entity.path), File(targetPath));
      }
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    await for (final entity
        in source.list(recursive: false, followLinks: false)) {
      final name = p.basename(entity.path);
      final targetPath = p.join(destination.path, name);
      if (entity is File) {
        await _copyFile(entity, File(targetPath));
      } else if (entity is Directory) {
        await _copyDirectory(Directory(entity.path), Directory(targetPath));
      }
    }
  }

  Future<void> _copyFile(File source, File destination) async {
    await destination.create(recursive: true);
    await source.copy(destination.path);
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
    'Docs': [
      '.pdf',
      '.doc',
      '.docx',
      '.ppt',
      '.pptx',
      '.xls',
      '.xlsx',
      '.txt',
      '.md',
    ],
    'Media': [
      '.mp4',
      '.mov',
      '.mkv',
      '.avi',
      '.mp3',
      '.wav',
      '.flac',
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
    ],
    'Archives': ['.zip', '.tar', '.gz', '.rar', '.7z'],
    'Code': [
      '.dart',
      '.js',
      '.ts',
      '.jsx',
      '.tsx',
      '.java',
      '.kt',
      '.swift',
      '.py',
      '.rb',
      '.go',
      '.c',
      '.cpp',
      '.rs',
    ],
    'Apps': ['.app', '.exe', '.pkg', '.dmg'],
  };

  static const _recentKey = 'recent_paths';

  Future<void> bootstrap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _recentPaths = prefs.getStringList(_recentKey) ?? [];

      // Charger le mode de vue sauvegardé
      final savedViewMode = prefs.getString('view_mode');
      final viewMode = savedViewMode == 'list'
          ? ExplorerViewMode.list
          : ExplorerViewMode.grid;

      _state = _state.copyWith(
        recentPaths: List.unmodifiable(_recentPaths),
        viewMode: viewMode,
      );
      notifyListeners();

      // Initialiser l'index de recherche de manière asynchrone
      _initializeSearchIndex();
    } catch (_) {
      // ignore prefs errors
    }
  }

  Future<void> _initializeSearchIndex() async {
    try {
      // Mettre à jour l'index en arrière-plan
      await updateSearchIndex();
    } catch (_) {
      // Ignorer les erreurs d'indexation
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
        await Process.run('cmd', [
          '/C',
          'start',
          'cmd',
          '/K',
          'cd /d "$target"',
        ]);
      } else {
        await Process.run('xdg-open', [target]);
      }
      _state = _state.copyWith(statusMessage: 'Terminal ouvert');
    } catch (_) {
      _state = _state.copyWith(
        statusMessage: 'Impossible d ouvrir le terminal',
      );
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
    if (_blockArchiveWrite('Compression non supportee dans une archive')) {
      return;
    }
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
    _state = _state.copyWith(
      isLoading: true,
      clearStatus: true,
      clearError: true,
    );
    notifyListeners();
    try {
      final args = [
        '-r',
        archiveName,
        ...entries.map((e) => e.path.split(Platform.pathSeparator).last),
      ];
      final result = await Process.run(
        'zip',
        args,
        workingDirectory: _state.currentPath,
      );
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
    while (File(
      '${_state.currentPath}${Platform.pathSeparator}$base',
    ).existsSync()) {
      base = 'Archive_$counter.zip';
      counter++;
    }
    return base;
  }

  /// Met à jour l'index d'un répertoire en arrière-plan
  void _updateIndexInBackground(String path) {
    Future.microtask(() async {
      await _searchViewModel.updateSearchIndex(path);
    });
  }

  @override
  void dispose() {
    _searchViewModel.dispose();
    super.dispose();
  }
}
