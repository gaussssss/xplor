import 'dart:io';

import '../../domain/entities/file_index.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/local_search_database.dart';
import '../models/file_index_model.dart';

class SearchRepositoryImpl implements SearchRepository {
  final LocalSearchDatabase database;
  bool _initialized = false;

  SearchRepositoryImpl(this.database);

  /// S'assurer que la base de données est initialisée
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      try {
        await database.initialize();
        _initialized = true;
      } catch (_) {
        // Ignorer les erreurs d'initialisation
      }
    }
  }

  @override
  Future<void> buildIndex(String rootPath, {int maxDepth = 2}) async {
    await _ensureInitialized();

    // Nettoyer l'index précédent
    await database.deleteIndex(rootPath);

    // Construire l'arbre de fichiers jusqu'à maxDepth niveaux
    final nodes = <Map<String, dynamic>>[];
    await _buildFileTree(rootPath, nodes, currentDepth: 0, maxDepth: maxDepth);

    // Sauvegarder dans la base de données
    if (nodes.isNotEmpty) {
      await database.createIndex(nodes);
    }

    // Enregistrer le timestamp
    await database.setLastIndexTime(rootPath, DateTime.now());
  }

  Future<void> _buildFileTree(
    String rootPath,
    List<Map<String, dynamic>> nodes, {
    required int currentDepth,
    required int maxDepth,
  }) async {
    // Arrêter la récursion si on a atteint la profondeur max
    if (currentDepth > maxDepth) return;

    try {
      final dir = Directory(rootPath);

      if (!await dir.exists()) return;

      final entities = await dir.list(recursive: false).toList();

      for (final entity in entities) {
        try {
          final stat = await entity.stat();
          final name = entity.path.split(Platform.pathSeparator).last;

          final model = FileIndexModel(
            path: entity.path,
            name: name,
            nameLower: name.toLowerCase(),
            parentPath: rootPath,
            isDirectory: entity is Directory,
            size: stat.size,
            lastModified: stat.modified.millisecondsSinceEpoch,
            indexedAt: DateTime.now().millisecondsSinceEpoch,
          );

          nodes.add(model.toMap());

          // Récursion pour les répertoires si on n'a pas atteint maxDepth
          if (entity is Directory && currentDepth < maxDepth) {
            await _buildFileTree(
              entity.path,
              nodes,
              currentDepth: currentDepth + 1,
              maxDepth: maxDepth,
            );
          }
        } catch (_) {
          // Ignorer les fichiers inaccessibles
        }
      }
    } catch (_) {
      // Ignorer les erreurs d'accès
    }
  }

  @override
  Future<List<SearchResult>> search(
    String query, {
    String? rootPath,
    int maxResults = 50,
    bool searchDirectoriesOnly = false,
    bool searchFilesOnly = false,
  }) async {
    if (query.trim().isEmpty) return [];

    await _ensureInitialized();

    final normalizedRoot = rootPath ?? '/';
    final queryLower = query.toLowerCase();
    final results = <SearchResult>[];
    final resultPaths = <String>{};

    try {
      // 1. Chercher dans l'index (BD) et retourner immédiatement
      final indexedResults = await _searchInDatabase(
        normalizedRoot,
        queryLower,
        searchDirectoriesOnly,
        searchFilesOnly,
      );

      // Ajouter les résultats BD et tracker les paths
      for (final result in indexedResults) {
        results.add(result);
        resultPaths.add(result.path);
      }

      // 2. Chercher en raw search et ajouter progressivement
      final rawResults = <SearchResult>[];
      await _searchInDirectory(
        normalizedRoot,
        queryLower,
        rawResults,
        searchDirectoriesOnly,
        searchFilesOnly,
        maxResults,
      );

      // 3. Ajouter les résultats raw en filtrant les doublons
      final newResults = <SearchResult>[];
      for (final result in rawResults) {
        if (!resultPaths.contains(result.path)) {
          results.add(result);
          resultPaths.add(result.path);
          newResults.add(result);
        }
      }

      // 4. Indexer les nouveaux résultats au passage (asynchrone)
      if (newResults.isNotEmpty) {
        _indexSearchResults(newResults, normalizedRoot);
      }
    } catch (_) {
      // Ignorer les erreurs d'accès
    }

    // Trier par pertinence et limiter aux résultats demandés
    results.sort((a, b) => b.relevance.compareTo(a.relevance));

    return results.take(maxResults).toList();
  }

  /// Cherche en raw et appelle le callback pour chaque résultat trouvé
  Future<List<SearchResult>> searchProgressive(
    String query, {
    String? rootPath,
    int maxResults = 50,
    bool searchDirectoriesOnly = false,
    bool searchFilesOnly = false,
    required void Function(SearchResult) onResultFound,
  }) async {
    if (query.trim().isEmpty) return [];

    await _ensureInitialized();

    final normalizedRoot = rootPath ?? '/';
    final queryLower = query.toLowerCase();
    final results = <SearchResult>[];
    final resultPaths = <String>{};

    try {
      // 1. Chercher dans l'index (BD) et notifier immédiatement
      final indexedResults = await _searchInDatabase(
        normalizedRoot,
        queryLower,
        searchDirectoriesOnly,
        searchFilesOnly,
      );

      // Ajouter les résultats BD et notifier
      for (final result in indexedResults) {
        results.add(result);
        resultPaths.add(result.path);
        onResultFound(result);
      }

      // 2. Chercher en raw search progressivement
      final newResults = <SearchResult>[];
      await _searchInDirectoryProgressive(
        normalizedRoot,
        queryLower,
        results,
        resultPaths,
        searchDirectoriesOnly,
        searchFilesOnly,
        maxResults,
        onResultFound,
      );

      // 3. Indexer les nouveaux résultats au passage
      if (newResults.isNotEmpty) {
        _indexSearchResults(newResults, normalizedRoot);
      }
    } catch (_) {
      // Ignorer les erreurs d'accès
    }

    // Trier par pertinence
    results.sort((a, b) => b.relevance.compareTo(a.relevance));

    return results.take(maxResults).toList();
  }

  /// Cherche en raw et appelle le callback pour chaque résultat trouvé
  Future<void> _searchInDirectoryProgressive(
    String dirPath,
    String queryLower,
    List<SearchResult> results,
    Set<String> resultPaths,
    bool searchDirectoriesOnly,
    bool searchFilesOnly,
    int maxResults,
    void Function(SearchResult) onResultFound,
  ) async {
    if (results.length >= maxResults) return;

    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return;

      final entities = await dir.list(recursive: false).toList();

      for (final entity in entities) {
        if (results.length >= maxResults) break;

        try {
          final name = entity.path.split(Platform.pathSeparator).last;
          final nameLower = name.toLowerCase();

          // Vérifier si le nom contient la requête
          if (nameLower.contains(queryLower)) {
            final stat = await entity.stat();
            final isDir = entity is Directory;

            // Appliquer les filtres
            if (searchDirectoriesOnly && !isDir) continue;
            if (searchFilesOnly && isDir) continue;

            // Vérifier les doublons
            if (!resultPaths.contains(entity.path)) {
              final result = SearchResult(
                path: entity.path,
                name: name,
                isDirectory: isDir,
                size: stat.size,
                lastModified: stat.modified,
                parentPath: dirPath,
                relevance: _calculateRelevance(nameLower, queryLower),
              );

              results.add(result);
              resultPaths.add(entity.path);
              // Notifier immédiatement du nouveau résultat
              onResultFound(result);

              // Indexer ce résultat immédiatement
              _indexSingleResult(result);
            }
          }

          // Récursion pour les répertoires
          if (entity is Directory && results.length < maxResults) {
            await _searchInDirectoryProgressive(
              entity.path,
              queryLower,
              results,
              resultPaths,
              searchDirectoriesOnly,
              searchFilesOnly,
              maxResults,
              onResultFound,
            );
          }
        } catch (_) {
          // Ignorer les fichiers inaccessibles
        }
      }
    } catch (_) {
      // Ignorer les erreurs d'accès
    }
  }

  /// Indexe un résultat unique immédiatement
  void _indexSingleResult(SearchResult result) {
    Future.microtask(() async {
      try {
        final stat = await File(result.path).stat();

        final model = FileIndexModel(
          path: result.path,
          name: result.name,
          nameLower: result.name.toLowerCase(),
          parentPath: result.parentPath,
          isDirectory: result.isDirectory,
          size: stat.size,
          lastModified: stat.modified.millisecondsSinceEpoch,
          indexedAt: DateTime.now().millisecondsSinceEpoch,
        );

        await database.createIndex([model.toMap()]);
      } catch (_) {
        // Ignorer les erreurs d'indexation silencieusement
      }
    });
  }

  /// Indexe les résultats trouvés en raw search dans la base de données
  void _indexSearchResults(List<SearchResult> results, String rootPath) {
    Future.microtask(() async {
      try {
        final nodes = <Map<String, dynamic>>[];

        for (final result in results) {
          try {
            final stat = await File(result.path).stat();

            final model = FileIndexModel(
              path: result.path,
              name: result.name,
              nameLower: result.name.toLowerCase(),
              parentPath: result.parentPath,
              isDirectory: result.isDirectory,
              size: stat.size,
              lastModified: stat.modified.millisecondsSinceEpoch,
              indexedAt: DateTime.now().millisecondsSinceEpoch,
            );

            nodes.add(model.toMap());
          } catch (_) {
            // Ignorer les fichiers inaccessibles
          }
        }

        // Ajouter les nœuds à l'index
        if (nodes.isNotEmpty) {
          await database.createIndex(nodes);
        }
      } catch (_) {
        // Ignorer les erreurs d'indexation silencieusement
      }
    });
  }

  /// Cherche dans l'index de la base de données
  Future<List<SearchResult>> _searchInDatabase(
    String rootPath,
    String queryLower,
    bool searchDirectoriesOnly,
    bool searchFilesOnly,
  ) async {
    final results = <SearchResult>[];

    try {
      final rows = await database.queryIndex(rootPath, query: queryLower);

      for (final row in rows) {
        final isDir = row['is_directory'] == 1;

        // Appliquer les filtres
        if (searchDirectoriesOnly && !isDir) continue;
        if (searchFilesOnly && isDir) continue;

        final name = row['name'] as String;
        final path = row['path'] as String;

        results.add(
          SearchResult(
            path: path,
            name: name,
            isDirectory: isDir,
            size: row['size'] as int? ?? 0,
            lastModified: DateTime.fromMillisecondsSinceEpoch(
              row['last_modified'] as int? ?? 0,
            ),
            parentPath: row['parent_path'] as String? ?? '',
            relevance: _calculateRelevance(name.toLowerCase(), queryLower),
          ),
        );
      }
    } catch (_) {
      // Ignorer les erreurs de base de données
    }

    return results;
  }

  Future<void> _searchInDirectory(
    String dirPath,
    String queryLower,
    List<SearchResult> results,
    bool searchDirectoriesOnly,
    bool searchFilesOnly,
    int maxResults,
  ) async {
    if (results.length >= maxResults) return;

    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return;

      final entities = await dir.list(recursive: false).toList();

      for (final entity in entities) {
        if (results.length >= maxResults) break;

        try {
          final name = entity.path.split(Platform.pathSeparator).last;
          final nameLower = name.toLowerCase();

          // Vérifier si le nom contient la requête
          if (nameLower.contains(queryLower)) {
            final stat = await entity.stat();
            final isDir = entity is Directory;

            // Appliquer les filtres
            if (searchDirectoriesOnly && !isDir) continue;
            if (searchFilesOnly && isDir) continue;

            results.add(
              SearchResult(
                path: entity.path,
                name: name,
                isDirectory: isDir,
                size: stat.size,
                lastModified: stat.modified,
                parentPath: dirPath,
                relevance: _calculateRelevance(nameLower, queryLower),
              ),
            );
          }

          // Récursion pour les répertoires
          if (entity is Directory && results.length < maxResults) {
            await _searchInDirectory(
              entity.path,
              queryLower,
              results,
              searchDirectoriesOnly,
              searchFilesOnly,
              maxResults,
            );
          }
        } catch (_) {
          // Ignorer les fichiers inaccessibles
        }
      }
    } catch (_) {
      // Ignorer les erreurs d'accès
    }
  }

  double _calculateRelevance(String name, String query) {
    final nameLower = name.toLowerCase();
    final queryLower = query.toLowerCase();

    // Correspondance exacte
    if (nameLower == queryLower) return 1.0;

    // Commence par la requête
    if (nameLower.startsWith(queryLower)) return 0.9;

    // Contient la requête entière
    if (nameLower.contains(queryLower)) return 0.7;

    // Contient les mots individuels (pour les requêtes multi-mots)
    final queryWords = queryLower.split(' ');
    final matchingWords = queryWords
        .where((word) => nameLower.contains(word))
        .length;

    return 0.5 + (matchingWords / queryWords.length) * 0.2;
  }

  @override
  Future<void> updateIndex(String rootPath) async {
    await _ensureInitialized();

    final status = await getIndexStatus(rootPath);

    // Si l'index est à jour (moins d'1 heure), ne rien faire
    if (status.isIndexed && !status.isOutOfDate) {
      return;
    }

    // Sinon, reconstruire
    await buildIndex(rootPath);
  }

  @override
  Future<FileIndexNode?> getIndex(String rootPath) async {
    // Non implémenté pour le moment
    return null;
  }

  @override
  Future<void> clearIndex() async {
    // Non implémenté pour le moment
  }

  @override
  Future<bool> isIndexUpToDate(String rootPath) async {
    final status = await getIndexStatus(rootPath);
    return status.isIndexed && !status.isOutOfDate;
  }

  @override
  Future<IndexStatus> getIndexStatus(String rootPath) async {
    await _ensureInitialized();

    final lastIndexTime = await database.getLastIndexTime(rootPath);
    final fileCount = await database.getFileCount(rootPath);

    return IndexStatus(
      isIndexed: lastIndexTime != null,
      lastIndexedAt: lastIndexTime,
      fileCount: fileCount,
      rootPath: rootPath,
    );
  }
}
