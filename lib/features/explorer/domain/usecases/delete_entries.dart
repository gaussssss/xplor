import '../entities/file_entry.dart';
import '../repositories/file_system_repository.dart';

class DeleteEntries {
  const DeleteEntries(this.repository);

  final FileSystemRepository repository;

  Future<void> call(List<FileEntry> entries) {
    return repository.deleteEntries(entries);
  }
}
