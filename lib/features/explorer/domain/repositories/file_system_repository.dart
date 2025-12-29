import '../entities/file_entry.dart';

abstract class FileSystemRepository {
  Future<List<FileEntry>> listDirectory(String path);
  Future<void> createDirectory(String parentPath, String name);
  Future<void> deleteEntries(List<FileEntry> entries);
  Future<FileEntry> renameEntry(FileEntry entry, String newName);
  Future<void> moveEntries(List<FileEntry> entries, String destinationPath);
  Future<void> copyEntries(List<FileEntry> entries, String destinationPath);
  Future<void> duplicateEntries(List<FileEntry> entries);
}
