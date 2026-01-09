import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:id3/id3.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/special_locations.dart';
import '../../domain/entities/duplicate_action.dart';
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

part 'explorer/archive.dart';
part 'explorer/clipboard.dart';
part 'explorer/file_ops.dart';
part 'explorer/lock.dart';
part 'explorer/navigation.dart';
part 'explorer/platform.dart';
part 'explorer/preferences.dart';
part 'explorer/search.dart';
part 'explorer/selection.dart';

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
    this.pendingOpenPath,
    this.pendingOpenLabel,
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
  final String? pendingOpenPath;
  final String? pendingOpenLabel;
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
      pendingOpenPath: null,
      pendingOpenLabel: null,
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
    String? pendingOpenPath,
    String? pendingOpenLabel,
    String? error,
    String? statusMessage,
    bool clearError = false,
    bool clearStatus = false,
    bool clearArchive = false,
    bool clearPendingOpen = false,
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
      archiveRootPath: clearArchive
          ? null
          : (archiveRootPath ?? this.archiveRootPath),
      pendingOpenPath: clearPendingOpen
          ? null
          : (pendingOpenPath ?? this.pendingOpenPath),
      pendingOpenLabel: clearPendingOpen
          ? null
          : (pendingOpenLabel ?? this.pendingOpenLabel),
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
  bool _multiSelectionEnabled = false;
  final List<String> _backStack = [];
  final List<String> _forwardStack = [];
  List<String> _recentPaths = [];
  final List<String> _stagedArchiveRoots = [];
  final Map<String, String?> _defaultAppIconCache = {};
  final Map<String, String?> _defaultAppPathCache = {};
  final Map<String, String?> _previewCache = {};
  final Map<String, String?> _mediaPreviewCache = {};
  final Map<String, Uint8List?> _audioArtCache = {};
  final Map<String, String> _entryTags = {};

  ExplorerViewState get state => _state;
  bool get isArchiveView => _state.isArchiveView;
  Set<String> get selectedTags => _state.selectedTags;
  Set<String> get selectedTypes => _state.selectedTypes;
  List<String> get recentPaths => _state.recentPaths;
  List<FileEntry> get clipboardEntries => List.unmodifiable(_clipboard);
  String? tagForPath(String path) => _entryTags[path];

  void clearStatus() {
    if (_state.statusMessage == null) return;
    _state = _state.copyWith(statusMessage: null);
    notifyListeners();
  }

  void clearPendingOpenPath() {
    if (_state.pendingOpenPath == null) return;
    _state = _state.copyWith(clearPendingOpen: true);
    notifyListeners();
  }

  @override
  void dispose() {
    _searchViewModel.dispose();
    super.dispose();
  }
}

class OpenWithApp {
  const OpenWithApp({required this.name, required this.path});

  final String name;
  final String path;
}
