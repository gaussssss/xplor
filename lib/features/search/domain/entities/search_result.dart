class SearchResult {
  final String path;
  final String name;
  final bool isDirectory;
  final int size;
  final DateTime lastModified;
  final String parentPath;
  final double relevance; // Score de pertinence (0-1)

  SearchResult({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.size,
    required this.lastModified,
    required this.parentPath,
    this.relevance = 1.0,
  });

  @override
  String toString() =>
      'SearchResult(name: $name, path: $path, relevance: $relevance)';
}
