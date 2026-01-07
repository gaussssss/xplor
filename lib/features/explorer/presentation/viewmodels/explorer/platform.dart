part of '../explorer_view_model.dart';

extension ExplorerPlatformOps on ExplorerViewModel {
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
      _state = _state.copyWith(
        statusMessage: 'Impossible d ouvrir le fichier',
      );
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
}
