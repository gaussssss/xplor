import '../repositories/search_repository.dart';

class GetIndexStatus {
  final SearchRepository repository;

  GetIndexStatus(this.repository);

  Future<IndexStatus> call(String rootPath) =>
      repository.getIndexStatus(rootPath);
}
