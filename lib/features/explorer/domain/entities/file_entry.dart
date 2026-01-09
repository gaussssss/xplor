class FileEntry {
  const FileEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
    this.lastModified,
    this.created,
    this.accessed,
    this.mode,
    this.isApplication = false,
    this.iconPath,
    this.tag,
  });

  final String name;
  final String path;
  final bool isDirectory;
  final int? size;
  final DateTime? lastModified;
  final DateTime? created;
  final DateTime? accessed;
  final int? mode;
  final bool isApplication;
  final String? iconPath;
  final String? tag; // tag label (persisted)
}
