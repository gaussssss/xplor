class FileEntry {
  const FileEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
    this.lastModified,
    this.isApplication = false,
    this.iconPath,
  });

  final String name;
  final String path;
  final bool isDirectory;
  final int? size;
  final DateTime? lastModified;
  final bool isApplication;
  final String? iconPath;
}
