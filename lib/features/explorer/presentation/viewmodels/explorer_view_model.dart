import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
import 'mixins/clipboard_operations_mixin.dart';
import 'mixins/file_operations_mixin.dart';
import 'mixins/platform_operations_mixin.dart';
import 'mixins/search_filter_mixin.dart';
import '../../../search/domain/usecases/search_files_progressive.dart';
import '../../../search/domain/usecases/build_index.dart';
import '../../../search/domain/usecases/update_index.dart';
import '../../../search/domain/usecases/get_index_status.dart';
import '../../../search/domain/entities/search_result.dart';
import 'search_view_model.dart';

// Réexporter les enums et classes d'état
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
    required this.isMultiSelectionMode,
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
  final bool isMultiSelectionMode;
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
      isMultiSelectionMode: false,
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
    bool? isMultiSelectionMode,
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
      isMultiSelectionMode: isMultiSelectionMode ?? this.isMultiSelectionMode,
      error: clearError ? null : (error ?? this.error),
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
    );
  }
}

/// ViewModel principal de l'explorateur de fichiers
/// Utilise des mixins pour organiser les responsabilités
class ExplorerViewModel extends ChangeNotifier
    with
        FileOperationsMixin,
        ClipboardOperationsMixin,
        PlatformOperationsMixin,
        SearchFilterMixin {
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

  // Use cases
  final ListDirectoryEntries _listDirectoryEntries;
  final CreateDirectory _createDirectory;
  final DeleteEntries _deleteEntries;
  final MoveEntries _moveEntries;
  final CopyEntries _copyEntries;
  final DuplicateEntries _duplicateEntries;
  final RenameEntry _renameEntry;
<<<<<<< HEAD

  // État
=======
  late final SearchViewModel _searchViewModel;
>>>>>>> Florian
  ExplorerViewState _state;
  List<FileEntry> _clipboard = [];
  List<String> _recentPaths = [];
  final List<String> _backHistory = [];
  final List<String> _forwardHistory = [];

  // Getters publics
  bool get isAtRoot => _state.currentPath == '/' || _state.currentPath == Platform.environment['HOME'];
  bool isSelected(FileEntry entry) => _state.selectedPaths.contains(entry.path);

  // Getters pour les entrées visibles (avec filtres appliqués)
  List<FileEntry> get visibleEntries {
    var entries = _state.entries;

    // Appliquer la recherche
    if (_state.searchQuery.isNotEmpty) {
      entries = entries.where((e) =>
        e.name.toLowerCase().contains(_state.searchQuery.toLowerCase())
      ).toList();
    }

    // Appliquer les filtres par tag et type
    entries = entries.where((e) => matchesTag(e) && matchesType(e)).toList();

    return entries;
  }

  // Getters pour l'historique de navigation
  bool get canGoBack => _backHistory.isNotEmpty;
  bool get canGoForward => _forwardHistory.isNotEmpty;

  // Getter pour le presse-papier
  bool get canPaste => _clipboard.isNotEmpty;

  // Getters pour les filtres (expose les valeurs de state pour l'UI)
  Set<String> get selectedTags => _state.selectedTags;
  Set<String> get selectedTypes => _state.selectedTypes;

  // Implémentation des getters/setters requis par les mixins
  @override
  ExplorerViewState get state => _state;

<<<<<<< HEAD
  @override
  set state(ExplorerViewState value) {
    _state = value;
  }

  @override
  List<FileEntry> get clipboard => _clipboard;
=======
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
>>>>>>> Florian

  @override
  set clipboard(List<FileEntry> value) {
    _clipboard = value;
  }

  @override
  CopyEntries get copyEntries => _copyEntries;

  @override
  MoveEntries get moveEntries => _moveEntries;

  @override
  CreateDirectory get createDirectory => _createDirectory;

  @override
  DeleteEntries get deleteEntries => _deleteEntries;

  @override
  DuplicateEntries get duplicateEntries => _duplicateEntries;

  @override
  RenameEntry get renameEntry => _renameEntry;

  @override
  Future<void> reloadCurrent() => _reloadCurrent();

  // Navigation et chargement de répertoires
  Future<void> loadDirectory(String path, {bool recordHistory = true}) async {
    if (SpecialLocations.isSpecialLocation(path)) {
      await _loadSpecialLocation(path, recordHistory: recordHistory);
      return;
    }

    _state = _state.copyWith(isLoading: true, clearError: true, clearStatus: true);
    notifyListeners();

    try {
      final entries = await _listDirectoryEntries(path);
      _state = _state.copyWith(
        currentPath: path,
        entries: entries,
        isLoading: false,
        selectedPaths: <String>{},
      );
<<<<<<< HEAD
      if (recordHistory) {
        _recordRecent(path);
=======
      await _recordRecent(targetPath);

      // Mettre à jour l'index en arrière-plan (au lieu de rebuilder)
      _updateIndexInBackground(targetPath);
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
>>>>>>> Florian
      }
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement: $e',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> _loadSpecialLocation(String location, {bool recordHistory = true}) async {
    String? resolvedPath;
    if (location == SpecialLocations.recentFiles || location == SpecialLocations.favorites) {
      // Ces emplacements sont virtuels et nécessitent une gestion spéciale
      // Pour l'instant, on navigue vers Home
      resolvedPath = Platform.environment['HOME'];
    } else if (location == SpecialLocations.desktop) {
      resolvedPath = SpecialLocations.desktop;
    } else if (location == SpecialLocations.documents) {
      resolvedPath = SpecialLocations.documents;
    } else if (location == SpecialLocations.downloads) {
      resolvedPath = SpecialLocations.downloads;
    } else {
      resolvedPath = Platform.environment['HOME'];
    }

    if (resolvedPath != null) {
      await loadDirectory(resolvedPath, recordHistory: recordHistory);
    }
  }

  Future<void> refresh() => loadDirectory(_state.currentPath, recordHistory: false);

  Future<void> open(FileEntry entry) {
    if (entry.isDirectory) {
      return loadDirectory(entry.path);
    }
    return Future.value();
  }

  Future<void> goToParent() async {
    final current = Directory(_state.currentPath);
    final parent = current.parent;
    if (parent.path != _state.currentPath) {
      await loadDirectory(parent.path);
    }
  }

  // Gestion de la sélection
  void toggleSelection(FileEntry entry) {
    final updated = <String>{..._state.selectedPaths};
    if (updated.contains(entry.path)) {
      updated.remove(entry.path);
    } else {
      updated.add(entry.path);
    }

    if (!_state.isMultiSelectionMode && updated.length > 1) {
      _state = _state.copyWith(
        selectedPaths: {entry.path},
        isMultiSelectionMode: true,
      );
    } else {
      _state = _state.copyWith(selectedPaths: updated);
    }
    notifyListeners();
  }

  void clearSelection() {
    if (_state.selectedPaths.isEmpty) return;
    _state = _state.copyWith(selectedPaths: <String>{});
    notifyListeners();
  }

  void selectSingle(FileEntry entry) {
    if (_state.selectedPaths.contains(entry.path) && _state.selectedPaths.length == 1) {
      return;
    }
<<<<<<< HEAD
    _state = _state.copyWith(selectedPaths: {entry.path});
=======
    _state = _state.copyWith(selectedPaths: {entry.path}, clearStatus: true);
    notifyListeners();
  }

  bool isSelected(FileEntry entry) => _state.selectedPaths.contains(entry.path);

  Future<void> createFolder(String name) async {
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
>>>>>>> Florian
    notifyListeners();
  }

  // Mode de vue
  void setViewMode(ExplorerViewMode mode) async {
    if (_state.viewMode == mode) return;
    _state = _state.copyWith(viewMode: mode);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
<<<<<<< HEAD
      await prefs.setString('view_mode', mode == ExplorerViewMode.grid ? 'grid' : 'list');
    } catch (_) {}
=======
      await prefs.setString(
        'view_mode',
        mode == ExplorerViewMode.list ? 'list' : 'grid',
      );
    } catch (_) {
      // Ignorer les erreurs de sauvegarde
    }
>>>>>>> Florian
  }

  Future<void> toggleMultiSelectionMode() async {
    final newMode = !_state.isMultiSelectionMode;
    _state = _state.copyWith(
      isMultiSelectionMode: newMode,
      selectedPaths: newMode ? _state.selectedPaths : <String>{},
    );
    notifyListeners();
  }

<<<<<<< HEAD
=======
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

>>>>>>> Florian
  void clearStatus() {
    if (_state.statusMessage == null) return;
    _state = _state.copyWith(statusMessage: null);
    notifyListeners();
  }

  // Navigation historique
  Future<void> goBack() async {
    if (_backHistory.isEmpty) return;
    _forwardHistory.add(_state.currentPath);
    final previous = _backHistory.removeLast();
    await loadDirectory(previous, recordHistory: false);
  }

  Future<void> goForward() async {
    if (_forwardHistory.isEmpty) return;
    _backHistory.add(_state.currentPath);
    final next = _forwardHistory.removeLast();
    await loadDirectory(next, recordHistory: false);
  }

  Future<void> goToLastVisited() async {
<<<<<<< HEAD
    if (_recentPaths.isEmpty) return;
    final last = _recentPaths.first;
    if (last != _state.currentPath) {
      await loadDirectory(last);
    }
  }

  // Méthode pour ouvrir un package comme répertoire (requis par PlatformOperationsMixin)
  @override
  Future<void> openPackageAsFolder(FileEntry entry) => loadDirectory(entry.path);
=======
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

  Future<void> duplicateSelected() async {
    if (_state.selectedPaths.isEmpty) return;
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
>>>>>>> Florian

  // Initialisation et préférences
  Future<void> bootstrap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _recentPaths = prefs.getStringList('recent_paths') ?? [];

      final savedViewMode = prefs.getString('view_mode');
      if (savedViewMode != null) {
        _state = _state.copyWith(
          viewMode: savedViewMode == 'grid' ? ExplorerViewMode.grid : ExplorerViewMode.list,
        );
      }

<<<<<<< HEAD
      await loadDirectory(_state.currentPath);
    } catch (e) {
      debugPrint('Error in bootstrap: $e');
    }
  }

  Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedViewMode = prefs.getString('view_mode');
      if (savedViewMode != null) {
        _state = _state.copyWith(
          viewMode: savedViewMode == 'grid' ? ExplorerViewMode.grid : ExplorerViewMode.list,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
=======
      _state = _state.copyWith(
        recentPaths: List.unmodifiable(_recentPaths),
        viewMode: viewMode,
      );
      notifyListeners();

      // Initialiser l'index de recherche de manière asynchrone
      _initializeSearchIndex();
    } catch (_) {
      // ignore prefs errors
>>>>>>> Florian
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
    try {
      _recentPaths.remove(path);
      _recentPaths.insert(0, path);
      if (_recentPaths.length > 10) {
        _recentPaths = _recentPaths.sublist(0, 10);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_paths', _recentPaths);

      _state = _state.copyWith(recentPaths: List.from(_recentPaths));
    } catch (_) {}
  }

  Future<void> _reloadCurrent() => loadDirectory(_state.currentPath, recordHistory: false);

<<<<<<< HEAD
  Future<Uri?> getQuickLookUrl(FileEntry entry) async => null;

  @override
  void dispose() {
    super.dispose();
=======
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
>>>>>>> Florian
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
