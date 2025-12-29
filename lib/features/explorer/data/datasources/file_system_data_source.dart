import '../models/file_entry_model.dart';

abstract class FileSystemDataSource {
  Future<List<FileEntryModel>> listDirectory(String path);
  Future<void> createDirectory(String parentPath, String name);
  Future<void> deleteEntries(List<FileEntryModel> entries);
  Future<FileEntryModel> renameEntry(FileEntryModel entry, String newName);
  Future<void> moveEntries(List<FileEntryModel> entries, String destinationPath);
  Future<void> copyEntries(List<FileEntryModel> entries, String destinationPath);
  Future<void> duplicateEntries(List<FileEntryModel> entries);
}
