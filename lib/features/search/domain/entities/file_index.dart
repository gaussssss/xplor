class FileIndexNode {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime lastModified;
  final DateTime indexedAt;
  final List<FileIndexNode> children;

  FileIndexNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.size,
    required this.lastModified,
    required this.indexedAt,
    this.children = const [],
  });

  /// Retourne le nombre total de fichiers dans cet arbre
  int get fileCount {
    int count = isDirectory ? 0 : 1;
    for (final child in children) {
      count += child.fileCount;
    }
    return count;
  }

  @override
  String toString() => 'FileIndexNode(name: $name, fileCount: $fileCount)';
}
