import '../repositories/search_repository.dart';

class BuildIndex {
  final SearchRepository repository;

  BuildIndex(this.repository);

  Future<void> call(String rootPath) => repository.buildIndex(rootPath);
}
