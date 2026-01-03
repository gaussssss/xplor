import 'package:flutter/foundation.dart';

import '../../../domain/entities/file_entry.dart';
import '../explorer_view_model.dart';

/// Mixin pour gérer la recherche et le filtrage des fichiers
mixin SearchFilterMixin on ChangeNotifier {
  // Accesseurs abstraits que le ViewModel doit fournir
  ExplorerViewState get state;
  set state(ExplorerViewState value);

  /// Extensions par tag
  static const Map<String, List<String>> tagExtensions = {
    'Rouge': ['.jpg', '.jpeg', '.png', '.gif', '.webp'],
    'Orange': ['.mp4', '.mov', '.mkv', '.avi'],
    'Jaune': ['.pdf'],
    'Vert': ['.txt', '.md', '.rtf'],
    'Bleu': ['.doc', '.docx', '.ppt', '.pptx', '.xls', '.xlsx'],
    'Violet': ['.zip', '.tar', '.gz', '.rar', '.7z'],
    'Gris': ['*'],
  };

  /// Extensions par type
  static const Map<String, List<String>> typeExtensions = {
    'Docs': ['.pdf', '.doc', '.docx', '.ppt', '.pptx', '.xls', '.xlsx', '.txt', '.md'],
    'Media': ['.mp4', '.mov', '.mkv', '.avi', '.mp3', '.wav', '.flac', '.jpg', '.jpeg', '.png', '.gif', '.webp'],
    'Archives': ['.zip', '.tar', '.gz', '.rar', '.7z'],
    'Code': ['.dart', '.js', '.ts', '.jsx', '.tsx', '.java', '.kt', '.swift', '.py', '.rb', '.go', '.c', '.cpp', '.rs'],
    'Apps': ['.app', '.exe', '.pkg', '.dmg'],
  };

  /// Met à jour la requête de recherche
  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
    notifyListeners();
  }

  /// Définit un filtre par tag unique
  void setTagFilter(String? tag) {
    state = state.copyWith(selectedTags: tag == null ? <String>{} : {tag});
    notifyListeners();
  }

  /// Bascule un tag dans la sélection
  void toggleTag(String tag) {
    final updated = <String>{...state.selectedTags};
    if (updated.contains(tag)) {
      updated.remove(tag);
    } else {
      updated.add(tag);
    }
    state = state.copyWith(selectedTags: updated);
    notifyListeners();
  }

  /// Bascule un type dans la sélection
  void toggleType(String type) {
    final updated = <String>{...state.selectedTypes};
    if (updated.contains(type)) {
      updated.remove(type);
    } else {
      updated.add(type);
    }
    state = state.copyWith(selectedTypes: updated);
    notifyListeners();
  }

  /// Efface tous les filtres
  void clearFilters() {
    state = state.copyWith(selectedTags: <String>{}, selectedTypes: <String>{});
    notifyListeners();
  }

  /// Vérifie si une entrée correspond aux tags sélectionnés
  bool matchesTag(FileEntry entry) {
    final tags = state.selectedTags;
    if (tags.isEmpty) return true;
    final lower = entry.name.toLowerCase();
    for (final tag in tags) {
      final extensions = tagExtensions[tag] ?? [];
      if (extensions.contains('*')) return true;
      if (extensions.any((ext) => lower.endsWith(ext))) {
        return true;
      }
    }
    return false;
  }

  /// Vérifie si une entrée correspond aux types sélectionnés
  bool matchesType(FileEntry entry) {
    final filters = state.selectedTypes;
    if (filters.isEmpty) return true;
    final lower = entry.name.toLowerCase();
    for (final type in filters) {
      final extensions = typeExtensions[type] ?? [];
      if (extensions.contains('*')) return true;
      if (extensions.any((ext) => lower.endsWith(ext))) {
        return true;
      }
    }
    return false;
  }
}
