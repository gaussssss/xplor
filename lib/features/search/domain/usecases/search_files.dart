import '../entities/search_result.dart';
import '../repositories/search_repository.dart';

class SearchFiles {
  final SearchRepository repository;

  SearchFiles(this.repository);

  Future<List<SearchResult>> call(
    String query, {
    String? rootPath,
    int maxResults = 50,
    bool searchDirectoriesOnly = false,
    bool searchFilesOnly = false,
  }) async {
    if (query.trim().isEmpty) return [];

    final results = await repository.search(
      query,
      rootPath: rootPath,
      maxResults: maxResults,
      searchDirectoriesOnly: searchDirectoriesOnly,
      searchFilesOnly: searchFilesOnly,
    );

    // Trier par pertinence
    results.sort((a, b) => b.relevance.compareTo(a.relevance));
    return results;
  }
}
