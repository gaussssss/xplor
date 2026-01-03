import '../entities/search_result.dart';
import '../repositories/search_repository.dart';

class SearchFilesProgressive {
  final SearchRepository repository;

  SearchFilesProgressive(this.repository);

  Future<List<SearchResult>> call(
    String query, {
    String? rootPath,
    int maxResults = 50,
    bool searchDirectoriesOnly = false,
    bool searchFilesOnly = false,
    required void Function(SearchResult) onResultFound,
  }) =>
      repository.searchProgressive(
        query,
        rootPath: rootPath,
        maxResults: maxResults,
        searchDirectoriesOnly: searchDirectoriesOnly,
        searchFilesOnly: searchFilesOnly,
        onResultFound: onResultFound,
      );
}
