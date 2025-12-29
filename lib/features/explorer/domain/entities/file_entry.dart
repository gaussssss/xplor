class FileEntry {
  const FileEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
    this.lastModified,
  });

  final String name;
  final String path;
  final bool isDirectory;
  final int? size;
  final DateTime? lastModified;
}
