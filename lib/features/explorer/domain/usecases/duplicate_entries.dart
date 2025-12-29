import '../entities/file_entry.dart';
import '../repositories/file_system_repository.dart';

class DuplicateEntries {
  const DuplicateEntries(this.repository);

  final FileSystemRepository repository;

  Future<void> call(List<FileEntry> entries) {
    return repository.duplicateEntries(entries);
  }
}
