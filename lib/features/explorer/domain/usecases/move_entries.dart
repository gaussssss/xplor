import '../entities/file_entry.dart';
import '../repositories/file_system_repository.dart';

class MoveEntries {
  const MoveEntries(this.repository);

  final FileSystemRepository repository;

  Future<void> call(List<FileEntry> entries, String destinationPath) {
    return repository.moveEntries(entries, destinationPath);
  }
}
