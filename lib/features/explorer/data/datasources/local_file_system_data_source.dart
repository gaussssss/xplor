import 'dart:io';

import '../models/file_entry_model.dart';
import 'file_system_data_source.dart';

class LocalFileSystemDataSource implements FileSystemDataSource {
  @override
  Future<List<FileEntryModel>> listDirectory(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      throw FileSystemException('Directory does not exist', path);
    }

    final entries = <FileEntryModel>[];
    try {
      await for (final entity in directory.list(recursive: false, followLinks: false)) {
        try {
          final stat = await entity.stat();
          if (stat.type == FileSystemEntityType.notFound) continue;
          entries.add(FileEntryModel.fromEntity(entity, stat));
        } on FileSystemException {
          // Si on ne peut pas lire les stats (permissions), créer une entrée par défaut
          try {
            final exists = await entity.exists();
            if (!exists) continue;
          } on FileSystemException {
            // Même entity.exists() échoue (SIP, permissions strictes)
            // On affiche quand même le fichier
          }

          final isDir = entity is Directory;

          // Créer une entrée avec des métadonnées par défaut
          final name = _entityName(entity);
          entries.add(FileEntryModel(
            name: name,
            path: entity.path,
            isDirectory: isDir,
            size: null, // Taille inconnue
            lastModified: null, // Date inconnue
            created: null,
            accessed: null,
            mode: null,
            isApplication: false,
            iconPath: null,
          ));
        }
      }
    } on FileSystemException catch (error) {
      throw FileSystemException(
        error.osError?.message ?? 'Acces refuse au dossier',
        path,
      );
    }

    entries.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return entries;
  }

  @override
  Future<void> createDirectory(String parentPath, String name) async {
    final sanitized = name.trim();
    if (sanitized.isEmpty) {
      throw const FileSystemException('Nom de dossier invalide');
    }
    final newPath = _join(parentPath, sanitized);
    final dir = Directory(newPath);
    if (await dir.exists()) {
      throw FileSystemException('Un dossier avec ce nom existe deja', newPath);
    }
    await dir.create(recursive: false);
  }

  @override
  Future<void> deleteEntries(List<FileEntryModel> entries) async {
    for (final entry in entries) {
      final entity = entry.isDirectory ? Directory(entry.path) : File(entry.path);
      if (await entity.exists()) {
        await entity.delete(recursive: entry.isDirectory);
      }
    }
  }

  @override
  Future<FileEntryModel> renameEntry(FileEntryModel entry, String newName) async {
    final sanitized = newName.trim();
    if (sanitized.isEmpty) {
      throw const FileSystemException('Nom invalide');
    }

    final parentDir = Directory(entry.path).parent.path;
    final newPath = _join(parentDir, sanitized);

    final entity = entry.isDirectory ? Directory(entry.path) : File(entry.path);
    if (!await entity.exists()) {
      throw FileSystemException('Entree introuvable', entry.path);
    }

    final renamed = await entity.rename(newPath);
    final stat = await renamed.stat();
    return FileEntryModel.fromEntity(renamed, stat);
  }

  @override
  Future<void> moveEntries(
    List<FileEntryModel> entries,
    String destinationPath,
  ) async {
    final destination = Directory(destinationPath);
    if (!await destination.exists()) {
      throw FileSystemException('Destination introuvable', destinationPath);
    }

    for (final entry in entries) {
      final fileName = entry.name;
      final targetPath = _join(destinationPath, fileName);
      final targetEntity = FileSystemEntity.typeSync(targetPath);
      if (targetEntity != FileSystemEntityType.notFound) {
        throw FileSystemException('Un element du meme nom existe deja', targetPath);
      }
      final entity = entry.isDirectory ? Directory(entry.path) : File(entry.path);
      if (!await entity.exists()) {
        throw FileSystemException('Entree introuvable', entry.path);
      }
      await entity.rename(targetPath);
    }
  }

  @override
  Future<void> copyEntries(
    List<FileEntryModel> entries,
    String destinationPath,
  ) async {
    final destination = Directory(destinationPath);
    if (!await destination.exists()) {
      throw FileSystemException('Destination introuvable', destinationPath);
    }

    for (final entry in entries) {
      final targetPath = _join(destinationPath, entry.name);
      final targetType = FileSystemEntity.typeSync(targetPath);
      if (targetType != FileSystemEntityType.notFound) {
        throw FileSystemException('Un element du meme nom existe deja', targetPath);
      }

      if (entry.isDirectory) {
        await _copyDirectory(Directory(entry.path), Directory(targetPath));
      } else {
        await _copyFile(File(entry.path), File(targetPath));
      }
    }
  }

  @override
  Future<void> duplicateEntries(List<FileEntryModel> entries) async {
    for (final entry in entries) {
      final parent = Directory(entry.path).parent.path;
      final newName = await _uniqueName(parent, entry.name, entry.isDirectory);
      final targetPath = _join(parent, newName);
      if (entry.isDirectory) {
        await _copyDirectory(Directory(entry.path), Directory(targetPath));
      } else {
        await _copyFile(File(entry.path), File(targetPath));
      }
    }
  }

  String _join(String base, String name) {
    if (base.endsWith(Platform.pathSeparator)) return '$base$name';
    return '$base${Platform.pathSeparator}$name';
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    await for (final entity in source.list(recursive: false, followLinks: false)) {
      final name = _entityName(entity);
      if (entity is File) {
        final newFile = File(_join(destination.path, name));
        await _copyFile(entity, newFile);
      } else if (entity is Directory) {
        final newDir = Directory(_join(destination.path, name));
        await _copyDirectory(entity, newDir);
      }
    }
  }

  Future<void> _copyFile(File source, File destination) async {
    await destination.create(recursive: true);
    await source.copy(destination.path);
  }

  String _entityName(FileSystemEntity entity) {
    final segments =
        entity.uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    return segments.isNotEmpty ? segments.last : entity.path;
  }

  Future<String> _uniqueName(String parentPath, String originalName, bool isDir) async {
    final separator = Platform.pathSeparator;
    final hasExtension = !isDir && originalName.contains('.');
    String base;
    String ext = '';
    if (hasExtension) {
      final dotIndex = originalName.lastIndexOf('.');
      base = originalName.substring(0, dotIndex);
      ext = originalName.substring(dotIndex);
    } else {
      base = originalName;
    }

    String candidate = '$base copie$ext';
    int counter = 2;
    while (await FileSystemEntity.typeSync('$parentPath$separator$candidate') !=
        FileSystemEntityType.notFound) {
      candidate = '$base copie $counter$ext';
      counter++;
    }
    return candidate;
  }
}
