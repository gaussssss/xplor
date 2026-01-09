part of '../explorer_view_model.dart';

const List<String> _archiveExtensions = [
  '.zip',
  '.zipx',
  '.jar',
  '.war',
  '.ear',
  '.apk',
  '.ipa',
  '.xpi',
  '.crx',
  '.whl',
  '.nupkg',
  '.vsix',
  '.appx',
  '.msix',
  '.docx',
  '.xlsx',
  '.pptx',
  '.odt',
  '.ods',
  '.odp',
  '.epub',
  '.pages',
  '.numbers',
  '.key',
  '.sketch',
  '.7z',
  '.rar',
  '.r00',
  '.r01',
  '.r02',
  '.cab',
  '.xar',
  '.iso',
  '.dmg',
  '.cpio',
  '.ar',
  '.deb',
  '.rpm',
  '.tar',
  '.tgz',
  '.tar.gz',
  '.tar.bz2',
  '.tbz',
  '.tbz2',
  '.tar.xz',
  '.txz',
  '.tar.zst',
  '.tzst',
  '.tar.lz',
  '.tar.lzma',
  '.tar.z',
  '.gz',
  '.gzip',
  '.bz2',
  '.xz',
  '.lzma',
  '.zst',
  '.lz4',
  '.z',
  '.br',
  '.cbz',
  '.cbr',
  '.cb7',
  '.cbt',
];

final RegExp _rarPartRegex = RegExp(r'\.part\d+\.rar$');
final RegExp _sevenZipPartRegex = RegExp(r'\.7z\.\d{3}$');

extension ExplorerArchiveOps on ExplorerViewModel {
  String get displayPath => _formatDisplayPath(_state.currentPath);

  String resolveInputPath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    if (!_state.isArchiveView ||
        _state.archivePath == null ||
        _state.archiveRootPath == null) {
      return trimmed;
    }
    final archivePath = p.normalize(_state.archivePath!);
    final inputPath = p.normalize(trimmed);
    if (p.equals(inputPath, archivePath)) {
      return _state.archiveRootPath!;
    }
    if (p.isWithin(archivePath, inputPath)) {
      final relative = p.relative(inputPath, from: archivePath);
      return p.join(_state.archiveRootPath!, relative);
    }
    return trimmed;
  }

  String _formatDisplayPath(String currentPath) {
    if (!_state.isArchiveView ||
        _state.archivePath == null ||
        _state.archiveRootPath == null) {
      return currentPath;
    }
    final root = p.normalize(_state.archiveRootPath!);
    final current = p.normalize(currentPath);
    if (!p.isWithin(root, current) && !p.equals(root, current)) {
      return currentPath;
    }
    final relative = p.relative(current, from: root);
    if (relative.isEmpty || relative == '.') {
      return _state.archivePath!;
    }
    return p.join(_state.archivePath!, relative);
  }

  bool _isArchivePath(String path) {
    final lower = path.toLowerCase();
    if (_archiveExtensions.any((ext) => lower.endsWith(ext))) {
      return true;
    }
    if (_rarPartRegex.hasMatch(lower) || _sevenZipPartRegex.hasMatch(lower)) {
      return true;
    }
    return false;
  }

  bool _isWithinArchive(String path) {
    if (!_state.isArchiveView || _state.archiveRootPath == null) {
      return false;
    }
    final root = p.normalize(_state.archiveRootPath!);
    final target = p.normalize(path);
    return p.equals(root, target) || p.isWithin(root, target);
  }

  bool _isWithinRoot(String rootPath, String targetPath) {
    final root = p.normalize(rootPath);
    final target = p.normalize(targetPath);
    return p.equals(root, target) || p.isWithin(root, target);
  }

  bool _clipboardReferencesRoot(String rootPath) {
    return _clipboard.any((entry) => _isWithinRoot(rootPath, entry.path));
  }

  Future<void> _cleanupStagedArchiveRoots() async {
    if (_stagedArchiveRoots.isEmpty) return;
    final remaining = <String>[];
    for (final root in _stagedArchiveRoots) {
      if (_clipboardReferencesRoot(root)) {
        remaining.add(root);
        continue;
      }
      try {
        final dir = Directory(root);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (_) {
        remaining.add(root);
      }
    }
    _stagedArchiveRoots
      ..clear()
      ..addAll(remaining);
  }

  Future<void> openArchive(FileEntry entry, {bool pushHistory = true}) async {
    final archivePath = entry.path;
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
      selectedPaths: <String>{},
    );
    notifyListeners();
    try {
      if (_state.isArchiveView && !_isWithinArchive(archivePath)) {
        await _closeArchiveSession(notify: false);
      }
      final extractedRoot = await _prepareArchiveExtraction(archivePath);
      _state = _state.copyWith(
        isArchiveView: true,
        archivePath: archivePath,
        archiveRootPath: extractedRoot,
      );
      await loadDirectory(extractedRoot, pushHistory: pushHistory);
    } catch (error) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Impossible d ouvrir l archive.',
      );
      notifyListeners();
    }
  }

  Future<void> exitArchiveView() async {
    if (!_state.isArchiveView || _state.archivePath == null) return;
    final parentPath = Directory(_state.archivePath!).parent.path;
    await loadDirectory(parentPath);
  }

  Future<void> extractArchiveTo(
    String destinationPath, {
    Map<String, DuplicateAction>? duplicateActions,
  }) async {
    if (!_state.isArchiveView || _state.archiveRootPath == null) return;
    final target = destinationPath.trim();
    if (target.isEmpty) return;
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );
    notifyListeners();
    try {
      await _copyDirectoryContents(
        _state.archiveRootPath!,
        target,
        duplicateActions: duplicateActions,
      );
      _state = _state.copyWith(
        isLoading: false,
        statusMessage: 'Archive extraite',
        pendingOpenPath: target,
        pendingOpenLabel: 'Ouvrir le dossier extrait ?',
      );
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  Future<void> extractSelectionTo(
    String destinationPath, {
    Map<String, DuplicateAction>? duplicateActions,
  }) async {
    if (!_state.isArchiveView || _state.archiveRootPath == null) return;
    final target = destinationPath.trim();
    if (target.isEmpty) return;
    final entries = _state.entries
        .where((entry) => _state.selectedPaths.contains(entry.path))
        .toList();
    if (entries.isEmpty) return;
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );
    notifyListeners();
    try {
      if (duplicateActions == null) {
        await _copyEntries(entries, target);
      } else {
        await _copyEntriesWithActions(
          entries,
          target,
          duplicateActions: duplicateActions,
        );
      }
      _state = _state.copyWith(
        isLoading: false,
        statusMessage: '${entries.length} element(s) extrait(s)',
        pendingOpenPath: target,
        pendingOpenLabel: 'Ouvrir le dossier extrait ?',
      );
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  Future<String> _prepareArchiveExtraction(String archivePath) async {
    final tempDir = await Directory.systemTemp.createTemp('xplor_archive_');
    await _extractArchive(archivePath, tempDir.path);
    return tempDir.path;
  }

  Future<void> _closeArchiveSession({bool notify = true}) async {
    final root = _state.archiveRootPath;
    _state = _state.copyWith(isArchiveView: false, clearArchive: true);
    if (notify) {
      notifyListeners();
    }
    if (root == null) return;
    if (_clipboardReferencesRoot(root)) {
      if (!_stagedArchiveRoots.contains(root)) {
        _stagedArchiveRoots.add(root);
      }
      return;
    }
    try {
      final dir = Directory(root);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      if (!_stagedArchiveRoots.contains(root)) {
        _stagedArchiveRoots.add(root);
      }
    }
  }

  Future<void> _extractArchive(
    String archivePath,
    String destinationPath,
  ) async {
    final tools = <({String cmd, List<String> args})>[
      (cmd: 'unrar', args: ['x', '-o+', archivePath, destinationPath]),
      (cmd: '7z', args: ['x', '-y', '-o$destinationPath', archivePath]),
      (
        cmd: 'unar',
        args: ['-quiet', '-output-directory', destinationPath, archivePath],
      ),
      (cmd: 'bsdtar', args: ['-xf', archivePath, '-C', destinationPath]),
      (cmd: 'unzip', args: ['-q', '-o', archivePath, '-d', destinationPath]),
      (cmd: 'tar', args: ['-xf', archivePath, '-C', destinationPath]),
    ];

    String? lastError;
    var attempted = false;
    for (final tool in tools) {
      if (!await _commandExists(tool.cmd)) {
        continue;
      }
      attempted = true;
      final result = await Process.run(tool.cmd, tool.args);
      if (result.exitCode == 0) {
        return;
      }
      final stderrText = result.stderr is String
          ? result.stderr as String
          : result.stderr.toString();
      final stdoutText = result.stdout is String
          ? result.stdout as String
          : result.stdout.toString();
      lastError = stderrText.trim().isNotEmpty
          ? stderrText.trim()
          : stdoutText.trim();
    }
    if (!attempted) {
      throw FileSystemException(
        'Aucun outil d extraction disponible. Installez 7z ou unar.',
        archivePath,
      );
    }
    throw FileSystemException(
      lastError ?? 'Extraction impossible',
      archivePath,
    );
  }

  Future<bool> _commandExists(String command) async {
    final checker = Platform.isWindows ? 'where' : 'which';
    final result = await Process.run(checker, [command]);
    return result.exitCode == 0;
  }

  Future<void> _copyEntriesWithActions(
    List<FileEntry> entries,
    String destinationPath, {
    Map<String, DuplicateAction>? duplicateActions,
  }) async {
    final destinationDir = Directory(destinationPath);
    if (!await destinationDir.exists()) {
      throw FileSystemException('Destination introuvable', destinationPath);
    }

    for (final entry in entries) {
      await _copyEntryWithAction(
        sourcePath: entry.path,
        entryName: entry.name,
        isDirectory: entry.isDirectory,
        destinationPath: destinationDir.path,
        duplicateActions: duplicateActions,
      );
    }
  }

  Future<void> _copyDirectoryContents(
    String sourcePath,
    String destinationPath, {
    Map<String, DuplicateAction>? duplicateActions,
  }) async {
    final sourceDir = Directory(sourcePath);
    if (!await sourceDir.exists()) {
      throw FileSystemException('Source introuvable', sourcePath);
    }
    final destinationDir = Directory(destinationPath);
    if (!await destinationDir.exists()) {
      throw FileSystemException('Destination introuvable', destinationPath);
    }

    await for (final entity in sourceDir.list(
      recursive: false,
      followLinks: false,
    )) {
      if (entity is! File && entity is! Directory) {
        continue;
      }
      final name = p.basename(entity.path);
      await _copyEntryWithAction(
        sourcePath: entity.path,
        entryName: name,
        isDirectory: entity is Directory,
        destinationPath: destinationDir.path,
        duplicateActions: duplicateActions,
      );
    }
  }

  Future<void> _copyEntryWithAction({
    required String sourcePath,
    required String entryName,
    required bool isDirectory,
    required String destinationPath,
    Map<String, DuplicateAction>? duplicateActions,
  }) async {
    String targetName = entryName;
    bool shouldReplace = false;

    if (duplicateActions != null) {
      final action = duplicateActions[entryName];
      if (action != null) {
        switch (action.type) {
          case DuplicateActionType.skip:
            return;
          case DuplicateActionType.replace:
            shouldReplace = true;
            break;
          case DuplicateActionType.duplicate:
            targetName = _resolveDuplicateName(
              action.newName,
              entryName,
              isDirectory,
              destinationPath,
            );
            break;
        }
      } else {
        final existing = FileSystemEntity.typeSync(
          p.join(destinationPath, entryName),
        );
        if (existing != FileSystemEntityType.notFound) {
          return;
        }
      }
    }

    final targetPath = p.join(destinationPath, targetName);
    if (shouldReplace) {
      await _deleteExistingTarget(targetPath);
    }

    if (isDirectory) {
      await _copyDirectory(Directory(sourcePath), Directory(targetPath));
    } else {
      await _copyFile(File(sourcePath), File(targetPath));
    }
  }

  Future<void> _deleteExistingTarget(String targetPath) async {
    final existingType = FileSystemEntity.typeSync(targetPath);
    if (existingType == FileSystemEntityType.notFound) return;
    if (existingType == FileSystemEntityType.directory) {
      await Directory(targetPath).delete(recursive: true);
    } else if (existingType == FileSystemEntityType.file) {
      await File(targetPath).delete();
    } else if (existingType == FileSystemEntityType.link) {
      await Link(targetPath).delete();
    }
  }

  String _resolveDuplicateName(
    String? proposedName,
    String fallbackName,
    bool isDirectory,
    String destinationPath,
  ) {
    final candidate = p.basename((proposedName ?? '').trim());
    final baseName = candidate.isEmpty ? fallbackName : candidate;
    return _uniqueName(destinationPath, baseName, isDirectory);
  }

  String _uniqueName(String parentPath, String originalName, bool isDir) {
    final trimmed = originalName.trim();
    if (trimmed.isEmpty) return originalName;
    final hasExtension = !isDir && trimmed.contains('.');
    String base;
    String ext = '';
    if (hasExtension) {
      final dotIndex = trimmed.lastIndexOf('.');
      base = trimmed.substring(0, dotIndex);
      ext = trimmed.substring(dotIndex);
    } else {
      base = trimmed;
    }

    var candidate = trimmed;
    final separator = Platform.pathSeparator;
    if (FileSystemEntity.typeSync('$parentPath$separator$candidate') ==
        FileSystemEntityType.notFound) {
      return candidate;
    }

    candidate = '$base copie$ext';
    var counter = 2;
    while (FileSystemEntity.typeSync('$parentPath$separator$candidate') !=
        FileSystemEntityType.notFound) {
      candidate = '$base copie $counter$ext';
      counter++;
    }
    return candidate;
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    await for (final entity in source.list(
      recursive: false,
      followLinks: false,
    )) {
      final name = p.basename(entity.path);
      final targetPath = p.join(destination.path, name);
      if (entity is File) {
        await _copyFile(entity, File(targetPath));
      } else if (entity is Directory) {
        await _copyDirectory(Directory(entity.path), Directory(targetPath));
      }
    }
  }

  Future<void> _copyFile(File source, File destination) async {
    await destination.create(recursive: true);
    await source.copy(destination.path);
  }

  bool _blockArchiveWrite(String message) {
    if (!_state.isArchiveView) return false;
    _state = _state.copyWith(statusMessage: message, clearError: true);
    notifyListeners();
    return true;
  }
}
