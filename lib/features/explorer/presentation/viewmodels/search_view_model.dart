import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../search/domain/entities/search_result.dart';
import '../../../search/domain/usecases/search_files_progressive.dart';
import '../../../search/domain/usecases/build_index.dart';
import '../../../search/domain/usecases/update_index.dart';

/// ViewModel dédié à la gestion de la recherche
class SearchViewModel extends ChangeNotifier {
  final SearchFilesProgressive _searchFilesProgressive;
  final BuildIndex _buildIndex;
  final UpdateIndex _updateIndex;

  List<SearchResult> _globalSearchResults = [];
  Timer? _searchDebounceTimer;

  SearchViewModel({
    required SearchFilesProgressive searchFilesProgressive,
    required BuildIndex buildIndex,
    required UpdateIndex updateIndex,
  })  : _searchFilesProgressive = searchFilesProgressive,
        _buildIndex = buildIndex,
        _updateIndex = updateIndex;

  /// Retourne les résultats de recherche globale
  List<SearchResult> get globalSearchResults => _globalSearchResults;

  /// Effectue une recherche globale dans les sous-répertoires avec affichage progressif
  Future<void> globalSearch(
    String query, {
    required String rootPath,
    required VoidCallback onUpdate,
  }) async {
    if (query.trim().isEmpty) {
      _globalSearchResults = [];
      onUpdate();
      return;
    }

    _globalSearchResults = [];
    onUpdate();

    try {
      await _searchFilesProgressive(
        query,
        rootPath: rootPath,
        maxResults: 100,
        onResultFound: (result) {
          // Ajouter le résultat immédiatement à la liste
          _globalSearchResults.add(result);
          // Notifier immédiatement pour afficher progressivement
          onUpdate();
        },
      );
    } catch (_) {
      _globalSearchResults = [];
      onUpdate();
    }
  }

  /// Construit l'index du répertoire courant
  Future<void> buildSearchIndex(String path) async {
    try {
      await _buildIndex(path);
    } catch (_) {
      // Ignorer les erreurs
    }
  }

  /// Met à jour l'index si nécessaire
  Future<void> updateSearchIndex(String path) async {
    try {
      await _updateIndex(path);
    } catch (_) {
      // Ignorer les erreurs
    }
  }

  /// Lance une recherche avec debounce
  void updateSearch(
    String query, {
    required String currentPath,
    required VoidCallback onUpdate,
  }) {
    // Vider les résultats précédents immédiatement
    _globalSearchResults = [];
    onUpdate();

    // Annuler le timer précédent
    _searchDebounceTimer?.cancel();

    // Déclencher la recherche globale si la requête n'est pas vide
    if (query.trim().isNotEmpty) {
      // Attendre 1000ms (1 seconde) avant de lancer la recherche
      _searchDebounceTimer = Timer(const Duration(milliseconds: 1000), () {
        globalSearch(
          query,
          rootPath: currentPath,
          onUpdate: onUpdate,
        );
      });
    }
  }

  /// Efface les résultats de recherche
  void clearSearchResults() {
    _globalSearchResults = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}
