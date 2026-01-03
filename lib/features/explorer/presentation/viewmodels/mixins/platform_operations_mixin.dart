import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/file_entry.dart';
import '../explorer_view_model.dart';

/// Mixin pour gérer les opérations spécifiques à la plateforme
/// (ouvrir dans Finder, lancer une app, ouvrir un terminal, comprimer, etc.)
mixin PlatformOperationsMixin on ChangeNotifier {
  // Accesseurs abstraits que le ViewModel doit fournir
  ExplorerViewState get state;
  set state(ExplorerViewState value);

  Future<void> reloadCurrent();

  /// Ouvre un fichier dans le Finder/Explorer
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
      state = state.copyWith(statusMessage: 'Impossible d ouvrir dans Finder');
      notifyListeners();
    }
  }

  /// Lance une application
  Future<void> launchApplication(FileEntry entry) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [entry.path]);
      } else if (Platform.isWindows) {
        await Process.run(entry.path, []);
      } else {
        await Process.run('xdg-open', [entry.path]);
      }
      state = state.copyWith(statusMessage: 'Application lancee');
    } catch (_) {
      state =
          state.copyWith(statusMessage: 'Impossible de lancer l application');
    } finally {
      notifyListeners();
    }
  }

  /// Ouvre un terminal dans le répertoire spécifié
  Future<void> openTerminalHere([String? path]) async {
    final target = path ?? state.currentPath;
    try {
      if (Platform.isMacOS) {
        await Process.run('open', ['-a', 'Terminal', target]);
      } else if (Platform.isWindows) {
        await Process.run(
          'cmd',
          ['/C', 'start', 'cmd', '/K', 'cd /d "$target"'],
        );
      } else {
        await Process.run('xdg-open', [target]);
      }
      state = state.copyWith(statusMessage: 'Terminal ouvert');
    } catch (_) {
      state = state.copyWith(statusMessage: 'Impossible d ouvrir le terminal');
    } finally {
      notifyListeners();
    }
  }

  /// Copie le chemin dans le presse-papier
  void copyPathToClipboard(String path) {
    Clipboard.setData(ClipboardData(text: path));
    state = state.copyWith(statusMessage: 'Chemin copie');
    notifyListeners();
  }

  /// Compresse les éléments sélectionnés en archive ZIP
  Future<void> compressSelected() async {
    if (state.selectedPaths.isEmpty) return;
    // Best-effort simple zip on macOS/Linux.
    if (Platform.isWindows) {
      state = state.copyWith(statusMessage: 'Compression non supportee ici');
      notifyListeners();
      return;
    }
    final entries = state.entries
        .where((e) => state.selectedPaths.contains(e.path))
        .toList();
    if (entries.isEmpty) return;

    final archiveName = _uniqueArchiveName();
    state = state.copyWith(isLoading: true, clearStatus: true, clearError: true);
    notifyListeners();
    try {
      final args = [
        '-r',
        archiveName,
        ...entries.map((e) => e.path.split(Platform.pathSeparator).last),
      ];
      final result = await Process.run('zip', args, workingDirectory: state.currentPath);
      if (result.exitCode != 0) {
        throw Exception(result.stderr);
      }
      await reloadCurrent();
      state = state.copyWith(
        isLoading: false,
        statusMessage: 'Archive creee: $archiveName',
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        statusMessage: 'Echec de compression',
      );
    } finally {
      notifyListeners();
    }
  }

  /// Ouvre un package .app comme un dossier
  Future<void> openPackageAsFolder(FileEntry entry);

  /// Génère un nom unique pour l'archive
  String _uniqueArchiveName() {
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'Archive_$timestamp.zip';
  }
}
