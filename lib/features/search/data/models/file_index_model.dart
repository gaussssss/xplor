class FileIndexModel {
  final String path;
  final String name;
  final String nameLower;
  final String? parentPath;
  final bool isDirectory;
  final int size;
  final int lastModified;
  final int indexedAt;

  FileIndexModel({
    required this.path,
    required this.name,
    required this.nameLower,
    required this.parentPath,
    required this.isDirectory,
    required this.size,
    required this.lastModified,
    required this.indexedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'name': name,
      'name_lower': nameLower,
      'parent_path': parentPath,
      'is_directory': isDirectory ? 1 : 0,
      'size': size,
      'last_modified': lastModified,
      'indexed_at': indexedAt,
    };
  }

  factory FileIndexModel.fromMap(Map<String, dynamic> map) {
    return FileIndexModel(
      path: map['path'] as String,
      name: map['name'] as String,
      nameLower: map['name_lower'] as String,
      parentPath: map['parent_path'] as String?,
      isDirectory: (map['is_directory'] as int) == 1,
      size: map['size'] as int? ?? 0,
      lastModified: map['last_modified'] as int? ?? 0,
      indexedAt: map['indexed_at'] as int? ?? 0,
    );
  }
}
