import '../repositories/search_repository.dart';

class UpdateIndex {
  final SearchRepository repository;

  UpdateIndex(this.repository);

  Future<void> call(String rootPath) => repository.updateIndex(rootPath);
}
