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
              created: null,
              accessed: null,
              mode: null,
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
    final list = filtered.toList();
    _applySorting(list);
    return list;
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
    final entryTag = entry.tag;
    if (entryTag != null && tags.contains(entryTag)) return true;
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

  void _applySorting(List<FileEntry> entries) {
    final sort = _state.sortConfig;
    int compareStrings(String a, String b) =>
        a.toLowerCase().compareTo(b.toLowerCase());
    entries.sort((a, b) {
      int result = 0;
      switch (sort.column) {
        case FileColumn.name:
          result = compareStrings(a.name, b.name);
          break;
        case FileColumn.size:
          result = (a.size ?? 0).compareTo(b.size ?? 0);
          break;
        case FileColumn.dateModified:
          result = (a.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(
                  b.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0));
          break;
        case FileColumn.kind:
          final aType = a.isDirectory ? 'Dossier' : _getFileType(a.name);
          final bType = b.isDirectory ? 'Dossier' : _getFileType(b.name);
          result = compareStrings(aType, bType);
          break;
        case FileColumn.dateCreated:
          result = (a.created ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(b.created ?? DateTime.fromMillisecondsSinceEpoch(0));
          break;
        case FileColumn.dateAccessed:
          result = (a.accessed ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(b.accessed ?? DateTime.fromMillisecondsSinceEpoch(0));
          break;
        case FileColumn.permissions:
          result = (a.mode ?? 0).compareTo(b.mode ?? 0);
          break;
        case FileColumn.tags:
          result = compareStrings(a.tag ?? '', b.tag ?? '');
          break;
      }

      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return sort.order == SortOrder.ascending ? result : -result;
    });
  }

  String _getFileType(String filename) {
    if (filename.contains('.')) {
      final ext = filename.split('.').last.toUpperCase();
      return 'Fichier $ext';
    }
    return 'Fichier';
  }
}
