import 'dart:io';

import '../../domain/entities/file_index.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/local_search_database.dart';
import '../models/file_index_model.dart';

class SearchRepositoryImpl implements SearchRepository {
  final LocalSearchDatabase database;

  SearchRepositoryImpl(this.database);

  @override
  Future<void> buildIndex(String rootPath) async {
    // Nettoyer l'index précédent
    await database.deleteIndex(rootPath);

    // Construire l'arbre de fichiers
    final nodes = <Map<String, dynamic>>[];
    await _buildFileTree(rootPath, nodes);

    // Sauvegarder dans la base de données
    if (nodes.isNotEmpty) {
      await database.createIndex(nodes);
    }

    // Enregistrer le timestamp
    await database.setLastIndexTime(rootPath, DateTime.now());
  }

  Future<void> _buildFileTree(
    String rootPath,
    List<Map<String, dynamic>> nodes,
  ) async {
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

          // Récursion pour les répertoires
          if (entity is Directory) {
            await _buildFileTree(entity.path, nodes);
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

    final normalizedRoot = rootPath ?? '/';
    final results = <SearchResult>[];
    final queryLower = query.toLowerCase();

    try {
      await _searchInDirectory(
        normalizedRoot,
        queryLower,
        results,
        searchDirectoriesOnly,
        searchFilesOnly,
        maxResults,
      );
    } catch (_) {
      // Ignorer les erreurs d'accès
    }

    // Trier par pertinence
    results.sort((a, b) => b.relevance.compareTo(a.relevance));

    return results.take(maxResults).toList();
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
