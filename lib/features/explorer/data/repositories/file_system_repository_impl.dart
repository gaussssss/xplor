import '../../domain/entities/file_entry.dart';
import '../../domain/repositories/file_system_repository.dart';
import '../datasources/file_system_data_source.dart';
import '../models/file_entry_model.dart';

class FileSystemRepositoryImpl implements FileSystemRepository {
  FileSystemRepositoryImpl(this.dataSource);

  final FileSystemDataSource dataSource;

  @override
  Future<List<FileEntry>> listDirectory(String path) {
    return dataSource.listDirectory(path);
  }

  @override
  Future<void> createDirectory(String parentPath, String name) {
    return dataSource.createDirectory(parentPath, name);
  }

  @override
  Future<void> deleteEntries(List<FileEntry> entries) {
    final models = entries
        .map((entry) => FileEntryModel(
              name: entry.name,
              path: entry.path,
              isDirectory: entry.isDirectory,
              size: entry.size,
              lastModified: entry.lastModified,
            ))
        .toList();
    return dataSource.deleteEntries(models);
  }

  @override
  Future<FileEntry> renameEntry(FileEntry entry, String newName) {
    final model = FileEntryModel(
      name: entry.name,
      path: entry.path,
      isDirectory: entry.isDirectory,
      size: entry.size,
      lastModified: entry.lastModified,
    );
    return dataSource.renameEntry(model, newName);
  }

  @override
  Future<void> moveEntries(List<FileEntry> entries, String destinationPath) {
    final models = entries
        .map((entry) => FileEntryModel(
              name: entry.name,
              path: entry.path,
              isDirectory: entry.isDirectory,
              size: entry.size,
              lastModified: entry.lastModified,
            ))
        .toList();
    return dataSource.moveEntries(models, destinationPath);
  }

  @override
  Future<void> copyEntries(List<FileEntry> entries, String destinationPath) {
    final models = entries
        .map((entry) => FileEntryModel(
              name: entry.name,
              path: entry.path,
              isDirectory: entry.isDirectory,
              size: entry.size,
              lastModified: entry.lastModified,
            ))
        .toList();
    return dataSource.copyEntries(models, destinationPath);
  }

  @override
  Future<void> duplicateEntries(List<FileEntry> entries) {
    final models = entries
        .map((entry) => FileEntryModel(
              name: entry.name,
              path: entry.path,
              isDirectory: entry.isDirectory,
              size: entry.size,
              lastModified: entry.lastModified,
            ))
        .toList();
    return dataSource.duplicateEntries(models);
  }
}
