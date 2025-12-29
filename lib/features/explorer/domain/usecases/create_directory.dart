import '../repositories/file_system_repository.dart';

class CreateDirectory {
  const CreateDirectory(this.repository);

  final FileSystemRepository repository;

  Future<void> call(String parentPath, String name) {
    return repository.createDirectory(parentPath, name);
  }
}
