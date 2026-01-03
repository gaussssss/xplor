import '../entities/search_result.dart';
import '../entities/file_index.dart';

abstract class SearchRepository {
  /// Construit l'index du répertoire jusqu'à une profondeur spécifiée (par défaut 2)
  Future<void> buildIndex(String rootPath, {int maxDepth = 2});

  /// Met à jour l'index (ajout/suppression/modification)
  Future<void> updateIndex(String rootPath);

  /// Recherche dans l'index
  Future<List<SearchResult>> search(
    String query, {
    String? rootPath,
    int maxResults = 50,
    bool searchDirectoriesOnly = false,
    bool searchFilesOnly = false,
  });

  /// Obtient l'index complet
  Future<FileIndexNode?> getIndex(String rootPath);

  /// Nettoie l'index
  Future<void> clearIndex();

  /// Vérifie si l'index existe et est à jour
  Future<bool> isIndexUpToDate(String rootPath);

  /// Obtient le statut de l'indexation
  Future<IndexStatus> getIndexStatus(String rootPath);
}

class IndexStatus {
  final bool isIndexed;
  final DateTime? lastIndexedAt;
  final int fileCount;
  final String rootPath;

  IndexStatus({
    required this.isIndexed,
    required this.lastIndexedAt,
    required this.fileCount,
    required this.rootPath,
  });

  bool get isOutOfDate {
    if (!isIndexed || lastIndexedAt == null) return true;
    return DateTime.now().difference(lastIndexedAt!).inHours > 1;
  }
}
