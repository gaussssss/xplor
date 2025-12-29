import '../entities/file_entry.dart';
import '../repositories/file_system_repository.dart';

class CopyEntries {
  const CopyEntries(this.repository);

  final FileSystemRepository repository;

  Future<void> call(List<FileEntry> entries, String destinationPath) {
    return repository.copyEntries(entries, destinationPath);
  }
}
