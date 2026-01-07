part of '../explorer_view_model.dart';

const Map<String, List<String>> _tagExtensions = {
  'Rouge': ['.jpg', '.jpeg', '.png', '.gif', '.webp'],
  'Orange': ['.mp4', '.mov', '.mkv', '.avi'],
  'Jaune': ['.pdf'],
  'Vert': ['.txt', '.md', '.rtf'],
  'Bleu': ['.doc', '.docx', '.ppt', '.pptx', '.xls', '.xlsx'],
  'Violet': ['.zip', '.tar', '.gz', '.rar', '.7z'],
  'Gris': ['*'],
};

const Map<String, List<String>> _typeExtensions = {
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

extension ExplorerSearchOps on ExplorerViewModel {
  List<FileEntry> get visibleEntries {
    final query = _state.searchQuery.trim().toLowerCase();
    Iterable<FileEntry> filtered = _state.entries;
    // Si une recherche globale est en cours, afficher les resultats globaux
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

  /// Retourne les resultats de recherche globale
  List<SearchResult> get globalSearchResults =>
      _searchViewModel.globalSearchResults;

  /// Effectue une recherche globale dans les sous-repertoires avec affichage progressif
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

  /// Construit l'index du repertoire courant
  Future<void> buildSearchIndex() async {
    await _searchViewModel.buildSearchIndex(_state.currentPath);
  }

  /// Met a jour l'index si necessaire
  Future<void> updateSearchIndex() async {
    await _searchViewModel.updateSearchIndex(_state.currentPath);
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

  /// Met a jour l'index d'un repertoire en arriere-plan
  void _updateIndexInBackground(String path) {
    Future.microtask(() async {
      await _searchViewModel.updateSearchIndex(path);
    });
  }
}
