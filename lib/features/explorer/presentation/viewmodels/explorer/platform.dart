part of '../explorer_view_model.dart';

extension ExplorerPlatformOps on ExplorerViewModel {
  bool isAudioFile(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return _isAudioExt(ext);
  }

  bool isVideoFile(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return _isVideoExt(ext);
  }

  bool canPreviewPath(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return _isImageExt(ext) ||
        _isAudioExt(ext) ||
        _isVideoExt(ext) ||
        shouldGeneratePreview(filePath);
  }

  Future<List<OpenWithApp>> resolveOpenWithApps(String filePath) async {
    if (!Platform.isMacOS) return const [];
    final fromSystem = await _resolveAppsFromSystem(filePath);
    if (fromSystem.isNotEmpty) return fromSystem;
    final ext = p.extension(filePath).toLowerCase();
    final candidates = _candidateAppsForExtension(ext);
    return _resolveAppsFromCandidates(candidates);
  }

  Future<Uint8List?> resolveAudioArtwork(String filePath) async {
    if (_audioArtCache.containsKey(filePath)) {
      return _audioArtCache[filePath];
    }
    final source = File(filePath);
    if (!await source.exists()) {
      _audioArtCache[filePath] = null;
      return null;
    }
    final ext = p.extension(filePath).toLowerCase();
    try {
      if (Platform.isMacOS && _isAudioExt(ext)) {
        final previewPath = await _createQuickLookThumbnail(
          filePath,
          size: 240,
        );
        if (previewPath != null) {
          final previewFile = File(previewPath);
          if (await previewFile.exists()) {
            final bytes = await previewFile.readAsBytes();
            if (bytes.isNotEmpty) {
              final result = Uint8List.fromList(bytes);
              _audioArtCache[filePath] = result;
              return result;
            }
          }
        }
      }
      if (ext == '.mp3') {
        final bytes = await source.readAsBytes();
        final parser = MP3Instance(bytes);
        final hasTags = parser.parseTagsSync();
        if (hasTags) {
          final apic = parser.metaTags['APIC'];
          if (apic is Map && apic['base64'] is String) {
            final coverBytes = base64.decode(apic['base64'] as String);
            final result = Uint8List.fromList(coverBytes);
            _audioArtCache[filePath] = result;
            return result;
          }
        }
      }
    } catch (_) {}
    _audioArtCache[filePath] = null;
    return null;
  }

  bool shouldGeneratePreview(String filePath) {
    if (!Platform.isMacOS) return false;
    final ext = p.extension(filePath).toLowerCase();
    return _previewExts.contains(ext);
  }

  Future<String?> resolveDefaultAppIconPath(String filePath) async {
    if (!Platform.isMacOS) return null;
    final ext = p.extension(filePath).toLowerCase();
    final cacheKey = ext.isEmpty ? '__noext__' : ext;
    if (_defaultAppIconCache.containsKey(cacheKey)) {
      return _defaultAppIconCache[cacheKey];
    }
    final appPath = await _resolveDefaultAppPath(filePath);
    if (appPath == null || appPath.trim().isEmpty) {
      _defaultAppIconCache[cacheKey] = null;
      return null;
    }
    final iconPath = _findAppIcon(appPath);
    _defaultAppIconCache[cacheKey] = iconPath;
    return iconPath;
  }

  String? _resolveAppBundlePath(String appName) {
    final normalized = appName.endsWith('.app') ? appName : '$appName.app';
    final candidates = [
      '/Applications/$normalized',
      '/System/Applications/$normalized',
      '/System/Applications/Utilities/$normalized',
      '${Platform.environment['HOME']}/Applications/$normalized',
    ];
    for (final path in candidates) {
      if (path.isEmpty) continue;
      if (Directory(path).existsSync()) {
        return path;
      }
    }
    return null;
  }

  Future<List<OpenWithApp>> _resolveAppsFromSystem(String filePath) async {
    final workspaceApps = await _resolveAppsFromWorkspace(filePath);
    if (workspaceApps.isNotEmpty) return workspaceApps;
    final uti = await _resolveFileUti(filePath);
    if (uti == null || uti.isEmpty) return const [];
    return _resolveAppsFromUti(uti);
  }

  Future<List<OpenWithApp>> _resolveAppsFromWorkspace(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) return const [];
    final escapedPath = filePath
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"');
    final script = [
      'use framework "AppKit"',
      'use scripting additions',
      'set theFile to POSIX file "$escapedPath"',
      'set fileUrl to (current application\'s NSURL\'s fileURLWithPath:(POSIX path of theFile))',
      'set appUrls to (current application\'s NSWorkspace\'s sharedWorkspace()\'s URLsForApplicationsToOpenURL:fileUrl)',
      'if appUrls is missing value then return ""',
      'set output to ""',
      'repeat with appUrl in appUrls',
      'set output to output & (appUrl\'s path() as text) & linefeed',
      'end repeat',
      'return output',
    ].join('\n');
    try {
      final result = await Process.run('osascript', ['-e', script]);
      if (result.exitCode != 0) return const [];
      final raw = (result.stdout ?? '').toString().trim();
      if (raw.isEmpty) return const [];
      return _pathsToApps(raw);
    } catch (_) {
      return const [];
    }
  }

  Future<String?> _resolveFileUti(String filePath) async {
    try {
      final result = await Process.run('mdls', [
        '-name',
        'kMDItemContentType',
        '-raw',
        filePath,
      ]);
      if (result.exitCode != 0) return null;
      final output = (result.stdout ?? '').toString().trim();
      if (output.isEmpty || output == '(null)') return null;
      return output;
    } catch (_) {
      return null;
    }
  }

  Future<List<OpenWithApp>> _resolveAppsFromUti(String uti) async {
    final script = [
      'use framework "Foundation"',
      'use framework "AppKit"',
      'use framework "LaunchServices"',
      'use scripting additions',
      'set theUti to "$uti"',
      'set handlers to (current application\'s LSCopyAllRoleHandlersForContentType(theUti, current application\'s kLSRolesAll)) as list',
      'set output to ""',
      'repeat with bundleId in handlers',
      'set appUrl to (current application\'s NSWorkspace\'s sharedWorkspace()\'s URLForApplicationWithBundleIdentifier:bundleId)',
      'if appUrl is not missing value then',
      'set output to output & (appUrl\'s path() as text) & linefeed',
      'end if',
      'end repeat',
      'return output',
    ].join('\n');
    try {
      final result = await Process.run('osascript', ['-e', script]);
      if (result.exitCode != 0) return const [];
      final output = (result.stdout ?? '').toString().trim();
      if (output.isEmpty) return const [];
      return _pathsToApps(output);
    } catch (_) {
      return const [];
    }
  }

  List<OpenWithApp> _pathsToApps(String raw) {
    final seen = <String>{};
    final apps = <OpenWithApp>[];
    for (final line in raw.split('\n')) {
      final path = line.trim();
      if (path.isEmpty || seen.contains(path)) continue;
      if (!Directory(path).existsSync()) continue;
      seen.add(path);
      apps.add(OpenWithApp(name: p.basenameWithoutExtension(path), path: path));
    }
    return apps;
  }

  List<OpenWithApp> _resolveAppsFromCandidates(List<String> candidates) {
    final apps = <OpenWithApp>[];
    for (final name in candidates) {
      final path = _resolveAppBundlePath(name);
      if (path != null) {
        apps.add(OpenWithApp(name: name, path: path));
      }
    }
    return apps;
  }

  List<String> _candidateAppsForExtension(String ext) {
    const videoApps = ['QuickTime Player', 'IINA', 'VLC'];
    const audioApps = ['Music', 'IINA', 'VLC', 'QuickTime Player'];
    const imageApps = ['Preview', 'Photos', 'Pixelmator'];
    const pdfApps = ['Preview', 'Adobe Acrobat Reader'];
    const docApps = ['Pages', 'Microsoft Word'];
    const sheetApps = ['Numbers', 'Microsoft Excel'];
    const slideApps = ['Keynote', 'Microsoft PowerPoint'];

    if (_isVideoExt(ext)) return videoApps;
    if (_isAudioExt(ext)) return audioApps;
    if (_isImageExt(ext)) return imageApps;
    if (ext == '.pdf') return pdfApps;
    if (_isDocExt(ext)) return docApps;
    if (_isSheetExt(ext)) return sheetApps;
    if (_isSlideExt(ext)) return slideApps;
    return const ['Preview'];
  }

  bool _isVideoExt(String ext) =>
      const {'.mp4', '.mov', '.avi', '.mkv', '.webm', '.flv'}.contains(ext);

  bool _isAudioExt(String ext) => const {
    '.mp3',
    '.wav',
    '.aac',
    '.flac',
    '.ogg',
    '.m4a',
    '.wma',
  }.contains(ext);

  bool _isImageExt(String ext) => const {
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.webp',
    '.bmp',
    '.svg',
  }.contains(ext);

  bool _isDocExt(String ext) =>
      const {'.doc', '.docx', '.rtf', '.odt'}.contains(ext);

  bool _isSheetExt(String ext) => const {'.xls', '.xlsx', '.csv'}.contains(ext);

  bool _isSlideExt(String ext) => const {'.ppt', '.pptx', '.key'}.contains(ext);

  static const Set<String> _previewExts = {
    '.pdf',
    '.doc',
    '.docx',
    '.ppt',
    '.pptx',
    '.xls',
    '.xlsx',
    '.key',
    '.pages',
    '.numbers',
    '.rtf',
    '.txt',
    '.md',
    '.csv',
    '.json',
    '.xml',
    '.yaml',
    '.yml',
  };

  Future<String?> resolvePreviewThumbnail(String filePath) async {
    if (!Platform.isMacOS) return null;
    if (!shouldGeneratePreview(filePath)) {
      _previewCache[filePath] = null;
      return null;
    }
    if (_previewCache.containsKey(filePath)) {
      return _previewCache[filePath];
    }
    final source = File(filePath);
    if (!source.existsSync()) {
      _previewCache[filePath] = null;
      return null;
    }
    final path = await _createQuickLookThumbnail(filePath, size: 160);
    _previewCache[filePath] = path;
    return path;
  }

  Future<String?> resolveVideoThumbnail(String filePath) async {
    if (!Platform.isMacOS) return null;
    if (!_isVideoExt(p.extension(filePath).toLowerCase())) {
      _mediaPreviewCache[filePath] = null;
      return null;
    }
    if (_mediaPreviewCache.containsKey(filePath)) {
      return _mediaPreviewCache[filePath];
    }
    final source = File(filePath);
    if (!source.existsSync()) {
      _mediaPreviewCache[filePath] = null;
      return null;
    }
    final path = await _createQuickLookThumbnail(filePath, size: 200);
    _mediaPreviewCache[filePath] = path;
    return path;
  }

  Future<String?> _createQuickLookThumbnail(
    String filePath, {
    int size = 160,
  }) async {
    try {
      final tmpDir = await Directory.systemTemp.createTemp('xplor_preview');
      final result = await Process.run('qlmanage', [
        '-t',
        '-s',
        '$size',
        '-o',
        tmpDir.path,
        filePath,
      ]);
      if (result.exitCode != 0) {
        return null;
      }
      final png = tmpDir.listSync().whereType<File>().firstWhere(
        (file) => file.path.toLowerCase().endsWith('.png'),
        orElse: () => File(''),
      );
      if (png.path.isEmpty) return null;
      return png.path;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolveDefaultAppPath(String filePath) async {
    if (!Platform.isMacOS) return null;
    final ext = p.extension(filePath).toLowerCase();
    final cacheKey = ext.isEmpty ? '__noext__' : ext;
    if (_defaultAppPathCache.containsKey(cacheKey)) {
      return _defaultAppPathCache[cacheKey];
    }
    final source = File(filePath);
    if (!source.existsSync()) {
      _defaultAppPathCache[cacheKey] = null;
      return null;
    }
    final escapedPath = filePath
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"');
    final script = [
      'use framework "AppKit"',
      'use scripting additions',
      'set theFile to POSIX file "$escapedPath"',
      'set fileUrl to (current application\'s NSURL\'s fileURLWithPath:(POSIX path of theFile))',
      'set appUrl to (current application\'s NSWorkspace\'s sharedWorkspace()\'s URLForApplicationToOpenURL:fileUrl)',
      'if appUrl is missing value then return ""',
      'return (appUrl\'s path() as text)',
    ].join('\n');
    try {
      final result = await Process.run('osascript', ['-e', script]);
      if (result.exitCode != 0) {
        _defaultAppPathCache[cacheKey] = null;
        return null;
      }
      final output = (result.stdout ?? '').toString().trim();
      if (output.isEmpty) {
        _defaultAppPathCache[cacheKey] = null;
        return null;
      }
      _defaultAppPathCache[cacheKey] = output;
      return output;
    } catch (_) {
      _defaultAppPathCache[cacheKey] = null;
      return null;
    }
  }

  String? _findAppIcon(String appPath) {
    final resourcesDir = Directory('$appPath/Contents/Resources');
    if (!resourcesDir.existsSync()) return null;
    final png = resourcesDir.listSync().whereType<File>().firstWhere(
      (file) => file.path.toLowerCase().endsWith('.png'),
      orElse: () => File(''),
    );
    if (png.path.isNotEmpty) return png.path;
    final icns = resourcesDir.listSync().whereType<File>().firstWhere(
      (file) => file.path.toLowerCase().endsWith('.icns'),
      orElse: () => File(''),
    );
    if (icns.path.isEmpty) return null;
    return _convertIcnsToPng(icns);
  }

  String? _convertIcnsToPng(File icnsFile) {
    try {
      final tmpDir = Directory.systemTemp.createTempSync('xplor_appicon');
      final target = '${tmpDir.path}/${icnsFile.uri.pathSegments.last}.png';
      final result = Process.runSync('sips', [
        '-s',
        'format',
        'png',
        icnsFile.path,
        '--out',
        target,
      ]);
      if (result.exitCode == 0 && File(target).existsSync()) {
        return target;
      }
    } catch (_) {}
    return null;
  }

  Future<void> launchApplication(FileEntry entry) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [entry.path]);
      } else if (Platform.isWindows) {
        await Process.run(entry.path, []);
      } else {
        await Process.run('xdg-open', [entry.path]);
      }
      _state = _state.copyWith(statusMessage: 'Application lancee');
    } catch (_) {
      _state = _state.copyWith(
        statusMessage: 'Impossible de lancer l application',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> openFile(FileEntry entry) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [entry.path]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', entry.path]);
      } else {
        await Process.run('xdg-open', [entry.path]);
      }
      _state = _state.copyWith(statusMessage: 'Fichier ouvert');
    } catch (_) {
      _state = _state.copyWith(statusMessage: 'Impossible d ouvrir le fichier');
    } finally {
      notifyListeners();
    }
  }

  Future<void> openInFinder(FileEntry entry) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', entry.path]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', entry.path]);
      } else {
        await Process.run('xdg-open', [Directory(entry.path).parent.path]);
      }
    } catch (_) {
      _state = _state.copyWith(
        statusMessage: 'Impossible d ouvrir dans Finder',
      );
      notifyListeners();
    }
  }

  Future<void> openTerminalHere([String? path]) async {
    final target = path ?? _state.currentPath;
    try {
      if (Platform.isMacOS) {
        await Process.run('open', ['-a', 'Terminal', target]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', [
          '/C',
          'start',
          'cmd',
          '/K',
          'cd /d "$target"',
        ]);
      } else {
        await Process.run('xdg-open', [target]);
      }
      _state = _state.copyWith(statusMessage: 'Terminal ouvert');
    } catch (_) {
      _state = _state.copyWith(
        statusMessage: 'Impossible d ouvrir le terminal',
      );
    } finally {
      notifyListeners();
    }
  }

  void copyPathToClipboard(String path) {
    Clipboard.setData(ClipboardData(text: path));
    _state = _state.copyWith(statusMessage: 'Chemin copie');
    notifyListeners();
  }

  Future<void> compressSelected() async {
    if (_state.selectedPaths.isEmpty) return;
    if (_blockArchiveWrite('Compression non supportee dans une archive')) {
      return;
    }
    // Best-effort simple zip on macOS/Linux.
    if (Platform.isWindows) {
      _state = _state.copyWith(statusMessage: 'Compression non supportee ici');
      notifyListeners();
      return;
    }
    final entries = _state.entries
        .where((e) => _state.selectedPaths.contains(e.path))
        .toList();
    if (entries.isEmpty) return;

    final archiveName = _uniqueArchiveName();
    _state = _state.copyWith(
      isLoading: true,
      clearStatus: true,
      clearError: true,
    );
    notifyListeners();
    try {
      final args = [
        '-r',
        archiveName,
        ...entries.map((e) => e.path.split(Platform.pathSeparator).last),
      ];
      final result = await Process.run(
        'zip',
        args,
        workingDirectory: _state.currentPath,
      );
      if (result.exitCode != 0) {
        throw Exception(result.stderr);
      }
      await _reloadCurrent();
      _state = _state.copyWith(
        isLoading: false,
        statusMessage: 'Archive creee: $archiveName',
      );
    } catch (_) {
      _state = _state.copyWith(
        isLoading: false,
        statusMessage: 'Echec de la compression',
      );
    } finally {
      notifyListeners();
    }
  }

  String _uniqueArchiveName() {
    var base = 'Archive.zip';
    var counter = 1;
    while (File(
      '${_state.currentPath}${Platform.pathSeparator}$base',
    ).existsSync()) {
      base = 'Archive_$counter.zip';
      counter++;
    }
    return base;
  }

  Future<String?> getNativeTag(String path) async {
    if (!Platform.isMacOS) return null;
    try {
      final tag =
          await _tagChannel.invokeMethod<String>('getTag', {'path': path});
      return tag?.trim().isEmpty ?? true ? null : tag;
    } catch (_) {
      return null;
    }
  }

  Future<void> setNativeTag(String path, String? tag) async {
    if (Platform.isMacOS) {
      try {
        await _tagChannel.invokeMethod('setTag', {
          'path': path,
          'tag': tag ?? '',
        });
      } catch (_) {
        // ignore native failures, still update local state
      }
    }
    await setEntryTag(path, tag);
  }
}
