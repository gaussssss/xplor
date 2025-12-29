import '../entities/file_entry.dart';
import '../repositories/file_system_repository.dart';

class RenameEntry {
  const RenameEntry(this.repository);

  final FileSystemRepository repository;

  Future<FileEntry> call(FileEntry entry, String newName) {
    return repository.renameEntry(entry, newName);
  }
}
