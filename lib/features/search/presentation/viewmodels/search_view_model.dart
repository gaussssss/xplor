import 'package:flutter/foundation.dart';

import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/usecases/build_index.dart';
import '../../domain/usecases/get_index_status.dart';
import '../../domain/usecases/search_files.dart';
import '../../domain/usecases/update_index.dart';

class SearchViewState {
  final List<SearchResult> results;
  final String searchQuery;
  final bool isLoading;
  final bool isIndexing;
  final String? error;
  final IndexStatus? indexStatus;

  const SearchViewState({
    required this.results,
    required this.searchQuery,
    required this.isLoading,
    required this.isIndexing,
    required this.indexStatus,
    this.error,
  });

  factory SearchViewState.initial() {
    return const SearchViewState(
      results: [],
      searchQuery: '',
      isLoading: false,
      isIndexing: false,
      indexStatus: null,
    );
  }

  SearchViewState copyWith({
    List<SearchResult>? results,
    String? searchQuery,
    bool? isLoading,
    bool? isIndexing,
    String? error,
    IndexStatus? indexStatus,
    bool clearError = false,
  }) {
    return SearchViewState(
      results: results ?? this.results,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isIndexing: isIndexing ?? this.isIndexing,
      error: clearError ? null : (error ?? this.error),
      indexStatus: indexStatus ?? this.indexStatus,
    );
  }
}

class SearchViewModel extends ChangeNotifier {
  SearchViewModel({
    required SearchFiles searchFiles,
    required BuildIndex buildIndex,
    required UpdateIndex updateIndex,
    required GetIndexStatus getIndexStatus,
  }) : _searchFiles = searchFiles,
       _buildIndex = buildIndex,
       _updateIndex = updateIndex,
       _getIndexStatus = getIndexStatus,
       _state = SearchViewState.initial();

  final SearchFiles _searchFiles;
  final BuildIndex _buildIndex;
  final UpdateIndex _updateIndex;
  final GetIndexStatus _getIndexStatus;
  SearchViewState _state;

  SearchViewState get state => _state;

  /// Effectue une recherche globale
  Future<void> search(
    String query, {
    String? rootPath,
    int maxResults = 50,
  }) async {
    if (query.trim().isEmpty) {
      _state = _state.copyWith(results: [], searchQuery: '', clearError: true);
      notifyListeners();
      return;
    }

    _state = _state.copyWith(
      isLoading: true,
      searchQuery: query,
      clearError: true,
    );
    notifyListeners();

    try {
      final results = await _searchFiles(
        query,
        rootPath: rootPath,
        maxResults: maxResults,
      );

      _state = _state.copyWith(results: results, isLoading: false);
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la recherche: $e',
      );
    } finally {
      notifyListeners();
    }
  }

  /// Construit l'index pour un chemin donné
  Future<void> buildIndex(String rootPath) async {
    _state = _state.copyWith(isIndexing: true, clearError: true);
    notifyListeners();

    try {
      await _buildIndex(rootPath);

      // Obtenir le statut après indexation
      final status = await _getIndexStatus(rootPath);

      _state = _state.copyWith(isIndexing: false, indexStatus: status);
    } catch (e) {
      _state = _state.copyWith(
        isIndexing: false,
        error: 'Erreur lors de l\'indexation: $e',
      );
    } finally {
      notifyListeners();
    }
  }

  /// Met à jour l'index si nécessaire
  Future<void> updateIndex(String rootPath) async {
    try {
      await _updateIndex(rootPath);

      // Obtenir le statut après mise à jour
      final status = await _getIndexStatus(rootPath);

      _state = _state.copyWith(indexStatus: status, clearError: true);
    } catch (e) {
      _state = _state.copyWith(
        error: 'Erreur lors de la mise à jour de l\'index: $e',
      );
    } finally {
      notifyListeners();
    }
  }

  /// Obtient le statut de l'index
  Future<void> checkIndexStatus(String rootPath) async {
    try {
      final status = await _getIndexStatus(rootPath);

      _state = _state.copyWith(indexStatus: status, clearError: true);
    } catch (e) {
      _state = _state.copyWith(
        error: 'Erreur lors de la vérification du statut: $e',
      );
    } finally {
      notifyListeners();
    }
  }

  /// Vide les résultats de recherche
  void clearResults() {
    _state = _state.copyWith(results: [], searchQuery: '', clearError: true);
    notifyListeners();
  }

  /// Efface le message d'erreur
  void clearError() {
    _state = _state.copyWith(clearError: true);
    notifyListeners();
  }
}
