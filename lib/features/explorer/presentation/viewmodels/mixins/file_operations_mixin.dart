import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../domain/usecases/create_directory.dart';
import '../../../domain/usecases/delete_entries.dart';
import '../../../domain/usecases/duplicate_entries.dart';
import '../../../domain/usecases/move_entries.dart';
import '../../../domain/usecases/rename_entry.dart';
import '../explorer_view_model.dart';

/// Mixin pour gérer les opérations sur les fichiers et dossiers
/// (création, suppression, renommage, duplication, déplacement)
mixin FileOperationsMixin on ChangeNotifier {
  // Accesseurs abstraits que le ViewModel doit fournir
  ExplorerViewState get state;
  set state(ExplorerViewState value);
  CreateDirectory get createDirectory;
  DeleteEntries get deleteEntries;
  DuplicateEntries get duplicateEntries;
  MoveEntries get moveEntries;
  RenameEntry get renameEntry;

  Future<void> reloadCurrent();

  /// Crée un nouveau dossier
  Future<void> createFolder(String name) async {
    state = state.copyWith(isLoading: true, clearError: true, clearStatus: true);
    notifyListeners();
    try {
      await createDirectory(state.currentPath, name);
      await reloadCurrent();
      state = state.copyWith(
        statusMessage: 'Dossier cree',
        clearError: true,
        isLoading: false,
      );
    } on FileSystemException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  /// Supprime les éléments sélectionnés
  Future<void> deleteSelected() async {
    if (state.selectedPaths.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true, clearStatus: true);
    notifyListeners();
    try {
      final toDelete = state.entries
          .where((entry) => state.selectedPaths.contains(entry.path))
          .toList();
      await deleteEntries(toDelete);
      await reloadCurrent();
      state = state.copyWith(
        statusMessage: '${toDelete.length} element(s) supprime(s)',
        isLoading: false,
      );
    } on FileSystemException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  /// Déplace les éléments sélectionnés
  Future<void> moveSelected(String destinationPath) async {
    if (state.selectedPaths.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true, clearStatus: true);
    notifyListeners();
    try {
      final toMove = state.entries
          .where((entry) => state.selectedPaths.contains(entry.path))
          .toList();
      await moveEntries(toMove, destinationPath);
      await reloadCurrent();
      state = state.copyWith(
        statusMessage: '${toMove.length} element(s) deplace(s)',
        isLoading: false,
      );
    } on FileSystemException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  /// Renomme l'élément sélectionné
  Future<void> renameSelected(String newName) async {
    if (state.selectedPaths.length != 1) return;
    final entry = state.entries
        .firstWhere((e) => state.selectedPaths.contains(e.path));
    state = state.copyWith(isLoading: true, clearError: true, clearStatus: true);
    notifyListeners();
    try {
      await renameEntry(entry, newName);
      await reloadCurrent();
      state = state.copyWith(
        statusMessage: 'Renomme avec succes',
        isLoading: false,
      );
    } on FileSystemException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }

  /// Duplique les éléments sélectionnés
  Future<void> duplicateSelected() async {
    if (state.selectedPaths.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true, clearStatus: true);
    notifyListeners();
    try {
      final toDuplicate = state.entries
          .where((entry) => state.selectedPaths.contains(entry.path))
          .toList();
      await duplicateEntries(toDuplicate);
      await reloadCurrent();
      state = state.copyWith(
        statusMessage: '${toDuplicate.length} element(s) dupliques',
        isLoading: false,
      );
    } on FileSystemException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
    } finally {
      notifyListeners();
    }
  }
}
