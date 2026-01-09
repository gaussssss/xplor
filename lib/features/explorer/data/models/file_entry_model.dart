import 'dart:io';

import '../../domain/entities/file_entry.dart';

class FileEntryModel extends FileEntry {
  const FileEntryModel({
    required super.name,
    required super.path,
    required super.isDirectory,
    super.size,
    super.lastModified,
    super.created,
    super.accessed,
    super.mode,
    super.isApplication = false,
    super.iconPath,
  });

  factory FileEntryModel.fromEntity(FileSystemEntity entity, FileStat stat) {
    final segments =
        entity.uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    final name = segments.isNotEmpty ? segments.last : entity.path;
    final isAppBundle =
        stat.type == FileSystemEntityType.directory && name.toLowerCase().endsWith('.app');
    return FileEntryModel(
      name: name,
      path: entity.path,
      isDirectory: stat.type == FileSystemEntityType.directory,
      size: stat.size,
      lastModified: stat.modified,
      created: stat.changed,
      accessed: stat.accessed,
      mode: stat.mode,
      isApplication: isAppBundle,
      iconPath: isAppBundle ? _findAppIcon(entity.path) : null,
    );
  }

  static String? _findAppIcon(String appPath) {
    final resourcesDir = Directory('$appPath/Contents/Resources');
    if (!resourcesDir.existsSync()) return null;
    final png = resourcesDir
        .listSync()
        .whereType<File>()
        .firstWhere(
          (file) => file.path.toLowerCase().endsWith('.png'),
          orElse: () => File(''),
        );
    if (png.path.isNotEmpty) return png.path;
    final icns = resourcesDir
        .listSync()
        .whereType<File>()
        .firstWhere(
          (file) => file.path.toLowerCase().endsWith('.icns'),
          orElse: () => File(''),
        );
    if (icns.path.isEmpty) return null;
    return _convertIcnsToPng(icns);
  }

  static String? _convertIcnsToPng(File icnsFile) {
    try {
      final tmpDir = Directory.systemTemp.createTempSync('xplor_appicon');
      final target = '${tmpDir.path}/${icnsFile.uri.pathSegments.last}.png';
      final result = Process.runSync(
        'sips',
        ['-s', 'format', 'png', icnsFile.path, '--out', target],
      );
      if (result.exitCode == 0 && File(target).existsSync()) {
        return target;
      }
    } catch (_) {}
    return null;
  }
}
