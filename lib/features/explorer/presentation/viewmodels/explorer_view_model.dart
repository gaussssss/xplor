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
  })  : _listDirectoryEntries = listDirectoryEntries,
        _createDirectory = createDirectory,
        _deleteEntries = deleteEntries,
        _moveEntries = moveEntries,
        _copyEntries = copyEntries,
        _duplicateEntries = duplicateEntries,
        _renameEntry = renameEntry,
        _state = ExplorerViewState.initial(initialPath);

  // Use cases
  final ListDirectoryEntries _listDirectoryEntries;
  final CreateDirectory _createDirectory;
  final DeleteEntries _deleteEntries;
  final MoveEntries _moveEntries;
  final CopyEntries _copyEntries;
  final DuplicateEntries _duplicateEntries;
  final RenameEntry _renameEntry;

  // État
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

  @override
  set state(ExplorerViewState value) {
    _state = value;
  }

  @override
  List<FileEntry> get clipboard => _clipboard;

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
      if (recordHistory) {
        _recordRecent(path);
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
    _state = _state.copyWith(selectedPaths: {entry.path});
    notifyListeners();
  }

  // Mode de vue
  void setViewMode(ExplorerViewMode mode) async {
    if (_state.viewMode == mode) return;
    _state = _state.copyWith(viewMode: mode);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('view_mode', mode == ExplorerViewMode.grid ? 'grid' : 'list');
    } catch (_) {}
  }

  Future<void> toggleMultiSelectionMode() async {
    final newMode = !_state.isMultiSelectionMode;
    _state = _state.copyWith(
      isMultiSelectionMode: newMode,
      selectedPaths: newMode ? _state.selectedPaths : <String>{},
    );
    notifyListeners();
  }

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
    if (_recentPaths.isEmpty) return;
    final last = _recentPaths.first;
    if (last != _state.currentPath) {
      await loadDirectory(last);
    }
  }

  // Méthode pour ouvrir un package comme répertoire (requis par PlatformOperationsMixin)
  @override
  Future<void> openPackageAsFolder(FileEntry entry) => loadDirectory(entry.path);

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

  Future<Uri?> getQuickLookUrl(FileEntry entry) async => null;

  @override
  void dispose() {
    super.dispose();
  }
}
