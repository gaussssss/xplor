import '../entities/file_entry.dart';
import '../repositories/file_system_repository.dart';

class ListDirectoryEntries {
  const ListDirectoryEntries(this.repository);

  final FileSystemRepository repository;

  Future<List<FileEntry>> call(String path) {
    return repository.listDirectory(path);
  }
}
