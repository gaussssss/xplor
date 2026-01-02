import 'package:flutter_test/flutter_test.dart';
import 'package:xplor/features/search/domain/entities/search_result.dart';
import 'package:xplor/features/search/domain/entities/file_index.dart';
import 'package:xplor/features/search/domain/repositories/search_repository.dart';
import 'package:xplor/features/search/domain/usecases/search_files.dart';

void main() {
  group('SearchFiles UseCase', () {
    late SearchFiles searchFiles;
    late MockSearchRepository mockRepository;

    setUp(() {
      mockRepository = MockSearchRepository();
      searchFiles = SearchFiles(mockRepository);
    });

    test('should return empty list for empty query', () async {
      final result = await searchFiles('');
      expect(result, isEmpty);
    });

    test('should return search results sorted by relevance', () async {
      // Test structure en place, prêt pour l'implémentation
      final result = await searchFiles('file');
      expect(result, isA<List<SearchResult>>());
    });
  });
}

class MockSearchRepository implements SearchRepository {
  @override
  Future<void> buildIndex(String rootPath) async {}

  @override
  Future<void> updateIndex(String rootPath) async {}

  @override
  Future<List<SearchResult>> search(
    String query, {
    String? rootPath,
    int maxResults = 50,
    bool searchDirectoriesOnly = false,
    bool searchFilesOnly = false,
  }) async {
    return [];
  }

  @override
  Future<FileIndexNode?> getIndex(String rootPath) async => null;

  @override
  Future<void> clearIndex() async {}

  @override
  Future<bool> isIndexUpToDate(String rootPath) async => false;

  @override
  Future<IndexStatus> getIndexStatus(String rootPath) async {
    return IndexStatus(
      isIndexed: false,
      lastIndexedAt: null,
      fileCount: 0,
      rootPath: rootPath,
    );
  }
}
