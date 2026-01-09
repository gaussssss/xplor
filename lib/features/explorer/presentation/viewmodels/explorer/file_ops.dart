part of '../explorer_view_model.dart';

extension ExplorerFileOps on ExplorerViewModel {
  Future<void> createFolder(String name) async {
    if (_blockArchiveWrite('Impossible de creer un dossier dans une archive')) {
      return;
    }
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );
    notifyListeners();
    try {
      await _createDirectory(_state.currentPath, name);
      await _reloadCurrent();
      _state = _state.copyWith(
        statusMessage: 'Dossier cree',
        clearError: true,
        isLoading: false,
      );
      // Mettre a jour l'index
      _updateIndexInBackground(_state.currentPath);
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteSelected() async {
    if (_state.selectedPaths.isEmpty) return;
    if (_blockArchiveWrite('Suppression non supportee dans une archive')) {
      return;
    }
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );
    notifyListeners();
    try {
      final toDelete = _state.entries
          .where((entry) => _state.selectedPaths.contains(entry.path))
          .toList();
      if (_state.currentPath == SpecialLocations.trash) {
        await _deleteEntries(toDelete);
        _state = _state.copyWith(
          statusMessage: '${toDelete.length} element(s) supprime(s)',
          isLoading: false,
        );
        await _reloadCurrent();
        notifyListeners();
        return;
      }
      if (Platform.isMacOS) {
        await _moveEntriesToTrash(toDelete);
      } else {
        await _deleteEntries(toDelete);
      }
      await _reloadCurrent();
      _state = _state.copyWith(
        statusMessage: '${toDelete.length} element(s) supprime(s)',
        isLoading: false,
      );
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  Future<List<String>> restoreSelectedFromTrash() async {
    if (_state.selectedPaths.isEmpty) return [];
    if (_state.currentPath != SpecialLocations.trash) return [];
    final restoredPaths = <String>[];
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );
    notifyListeners();
    try {
      final toRestore = _state.entries
          .where((entry) => _state.selectedPaths.contains(entry.path))
          .toList();
      debugPrint('[Trash] Restore requested: ${toRestore.length} item(s)');
      if (!Platform.isMacOS) {
        _state = _state.copyWith(
          isLoading: false,
          error: 'Restauration non supportee sur cette plateforme.',
        );
        return restoredPaths;
      }
      for (final entry in toRestore) {
        debugPrint('[Trash] Restoring: ${entry.path}');
        final restoredPath = await _putBackFromTrash(entry.path);
        if (restoredPath != null) {
          restoredPaths.add(restoredPath);
        }
      }
      await _reloadCurrent();
      _state = _state.copyWith(
        statusMessage: '${toRestore.length} element(s) restaure(s)',
        isLoading: false,
      );
      return restoredPaths;
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } catch (_) {
      _state = _state.copyWith(
        isLoading: false,
        error: 'Impossible de restaurer les elements.',
      );
    } finally {
      notifyListeners();
    }
    return restoredPaths;
  }

  Future<void> _moveEntriesToTrash(List<FileEntry> entries) async {
    for (final entry in entries) {
      debugPrint('[Trash] Moving to trash: ${entry.path}');
      final script = 'tell application "Finder" to delete POSIX file "${_escapeAppleScriptPath(entry.path)}"';
      final result = await Process.run('osascript', ['-e', script]);
      if (result.exitCode != 0) {
        debugPrint('[Trash] Move failed: ${result.stderr}');
        throw FileSystemException(
          'Echec de suppression vers la corbeille',
          entry.path,
        );
      }
    }
  }

  Future<String?> _putBackFromTrash(String path) async {
    // Essayer d'abord avec put back (nécessite les métadonnées macOS)
    try {
      final escaped = _escapeAppleScriptPath(path);
      final script = '''
tell application "Finder"
  set restoredItem to put back (POSIX file "$escaped")
  return POSIX path of (restoredItem as alias)
end tell
''';
      debugPrint('[Trash] Restore script: $script');
      final result = await Process.run('osascript', ['-e', script]);
      if (result.exitCode == 0) {
        debugPrint('[Trash] Successfully restored via put back');
        final restoredPath = (result.stdout ?? '').toString().trim();
        return restoredPath.isEmpty ? null : restoredPath;
      }
      debugPrint('[Trash] Put back failed: ${result.stderr}');
    } catch (e) {
      debugPrint('[Trash] Put back exception: $e');
    }

    // Si put back échoue, essayer de restaurer dans le dossier Home de l'utilisateur
    debugPrint(
        '[Trash] Falling back to manual restore to home directory (metadata lost)');
    final fileName = path.split('/').last;
    final homeDir = Platform.environment['HOME'] ?? '/Users';
    final targetPath = '$homeDir/$fileName';

    // Utiliser mv pour déplacer le fichier
    final mvResult = await Process.run('mv', [path, targetPath]);
    if (mvResult.exitCode != 0) {
      debugPrint('[Trash] Manual restore failed: ${mvResult.stderr}');
      throw FileSystemException(
        'Impossible de restaurer: métadonnées perdues. Fichier déplacé manuellement vers: $targetPath',
        path,
      );
    }
    debugPrint('[Trash] File restored to: $targetPath');
    return targetPath;
  }

  String _escapeAppleScriptPath(String path) {
    return path.replaceAll('"', '\\"');
  }

  Future<void> moveSelected(String destinationPath) async {
    if (_state.selectedPaths.isEmpty) return;
    if (_blockArchiveWrite('Deplacement non supporte dans une archive')) {
      return;
    }
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );
    notifyListeners();
    try {
      final toMove = _state.entries
          .where((entry) => _state.selectedPaths.contains(entry.path))
          .toList();
      await _moveEntries(toMove, destinationPath);
      await _reloadCurrent();
      _state = _state.copyWith(
        statusMessage: '${toMove.length} element(s) deplace(s)',
        isLoading: false,
      );
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  Future<void> renameSelected(String newName) async {
    if (_state.selectedPaths.length != 1) return;
    if (_blockArchiveWrite('Renommage non supporte dans une archive')) {
      return;
    }
    final entry = _state.entries.firstWhere(
      (e) => _state.selectedPaths.contains(e.path),
    );
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );
    notifyListeners();
    try {
      await _renameEntry(entry, newName);
      await _reloadCurrent();
      _state = _state.copyWith(
        statusMessage: 'Renomme avec succes',
        isLoading: false,
      );
      // Mettre a jour l'index
      _updateIndexInBackground(_state.currentPath);
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  Future<void> duplicateSelected() async {
    if (_state.selectedPaths.isEmpty) return;
    if (_blockArchiveWrite('Duplication non supportee dans une archive')) {
      return;
    }
    _state = _state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatus: true,
    );
    notifyListeners();
    try {
      final toDuplicate = _state.entries
          .where((entry) => _state.selectedPaths.contains(entry.path))
          .toList();
      await _duplicateEntries(toDuplicate);
      await _reloadCurrent();
      _state = _state.copyWith(
        statusMessage: '${toDuplicate.length} element(s) dupliques',
        isLoading: false,
      );
    } on FileSystemException catch (error) {
      _state = _state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }
}
