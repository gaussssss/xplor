abstract class LocalSearchDatabase {
  Future<void> initialize();
  Future<void> createIndex(List<Map<String, dynamic>> nodes);
  Future<List<Map<String, dynamic>>> queryIndex(String rootPath, {required String query});
  Future<void> deleteIndex(String rootPath);
  Future<DateTime?> getLastIndexTime(String rootPath);
  Future<void> setLastIndexTime(String rootPath, DateTime time);
  Future<int> getFileCount(String rootPath);
}
