import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../domain/entities/file_entry.dart';
import '../../../domain/usecases/copy_entries.dart';
import '../../../domain/usecases/move_entries.dart';
import '../explorer_view_model.dart';

/// Mixin pour gérer les opérations de presse-papier (copier, couper, coller)
mixin ClipboardOperationsMixin on ChangeNotifier {
  // Accesseurs abstraits que le ViewModel doit fournir
  ExplorerViewState get state;
  set state(ExplorerViewState value);
  List<FileEntry> get clipboard;
  set clipboard(List<FileEntry> value);
  CopyEntries get copyEntries;
  MoveEntries get moveEntries;

  Future<void> reloadCurrent();

  /// Copie la sélection dans le presse-papier
  void copySelectionToClipboard() {
    if (state.selectedPaths.isEmpty) return;
    clipboard = state.entries
        .where((entry) => state.selectedPaths.contains(entry.path))
        .toList();
    state = state.copyWith(
      clipboardCount: clipboard.length,
      isCutOperation: false,
      statusMessage: 'Copie en memoire',
      clearError: true,
    );
    notifyListeners();
  }

  /// Coupe la sélection dans le presse-papier
  void cutSelectionToClipboard() {
    if (state.selectedPaths.isEmpty) return;
    clipboard = state.entries
        .where((entry) => state.selectedPaths.contains(entry.path))
        .toList();
    state = state.copyWith(
      clipboardCount: clipboard.length,
      isCutOperation: true,
      statusMessage: 'Coupe en memoire',
      clearError: true,
    );
    notifyListeners();
  }

  /// Colle le contenu du presse-papier
  Future<void> pasteClipboard([String? destinationPath]) async {
    if (clipboard.isEmpty) return;
    final targetPath = destinationPath ?? state.currentPath;
    state = state.copyWith(isLoading: true, clearError: true, clearStatus: true);
    notifyListeners();
    try {
      if (state.isCutOperation) {
        await _moveEntriesInternal(clipboard, targetPath);
      } else {
        await _copyEntriesInternal(clipboard, targetPath);
      }
      await reloadCurrent();
      state = state.copyWith(
        statusMessage:
            '${clipboard.length} element(s) ${state.isCutOperation ? 'deplaces' : 'colles'}',
        isLoading: false,
        isCutOperation: false,
        clipboardCount: 0,
      );
      clipboard = [];
    } on FileSystemException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  /// Déplace des entrées vers une destination
  Future<void> moveEntriesTo(List<FileEntry> entries, String destinationPath) async {
    if (entries.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true, clearStatus: true);
    notifyListeners();
    try {
      await _moveEntriesInternal(entries, destinationPath);
      await reloadCurrent();
      state = state.copyWith(
        statusMessage: '${entries.length} element(s) deplace(s)',
        isLoading: false,
      );
    } on FileSystemException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  // Méthodes privées internes
  Future<void> _copyEntriesInternal(List<FileEntry> entries, String destinationPath) async {
    await copyEntries(entries, destinationPath);
  }

  Future<void> _moveEntriesInternal(List<FileEntry> entries, String destinationPath) async {
    await moveEntries(entries, destinationPath);
  }
}
