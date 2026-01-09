part of '../explorer_view_model.dart';

const String _recentKey = 'recent_paths';
const String _lastPathKey = 'last_opened_path';

extension ExplorerPreferencesOps on ExplorerViewModel {
  void setViewMode(ExplorerViewMode mode) async {
    if (_state.viewMode == mode) return;
    _state = _state.copyWith(viewMode: mode);
    notifyListeners();

    // Sauvegarder le mode de vue
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'view_mode',
        mode == ExplorerViewMode.list ? 'list' : 'grid',
      );
    } catch (_) {
      // Ignorer les erreurs de sauvegarde
    }
  }

  Future<void> bootstrap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _recentPaths = prefs.getStringList(_recentKey) ?? [];

      // Charger le mode de vue sauvegarde
      final savedViewMode = prefs.getString('view_mode');
      final viewMode = savedViewMode == 'list'
          ? ExplorerViewMode.list
          : ExplorerViewMode.grid;

      _state = _state.copyWith(
        recentPaths: List.unmodifiable(_recentPaths),
        viewMode: viewMode,
      );
      notifyListeners();

      // Initialiser l'index de recherche de maniere asynchrone
      _initializeSearchIndex();
    } catch (_) {
      // ignore prefs errors
    }
  }

  Future<String> resolveStartupPath(String fallbackPath) async {
    try {
      if (fallbackPath == SpecialLocations.disks) {
        return fallbackPath;
      }
      final prefs = await SharedPreferences.getInstance();
      final lastPath = prefs.getString(_lastPathKey);
      if (lastPath == null || lastPath.trim().isEmpty) {
        return fallbackPath;
      }
      if (SpecialLocations.isSpecialLocation(lastPath)) {
        return lastPath;
      }
      final type = FileSystemEntity.typeSync(lastPath);
      if (type != FileSystemEntityType.notFound) {
        return lastPath;
      }
    } catch (_) {
      // ignore prefs errors
    }
    return fallbackPath;
  }

  Future<void> _initializeSearchIndex() async {
    try {
      // Mettre a jour l'index en arriere-plan
      await updateSearchIndex();
    } catch (_) {
      // Ignorer les erreurs d'indexation
    }
  }

  Future<void> _recordRecent(String path) async {
    if (path.isEmpty) return;
    _recentPaths.remove(path);
    _recentPaths.insert(0, path);
    if (_recentPaths.length > 15) {
      _recentPaths = _recentPaths.sublist(0, 15);
    }
    _state = _state.copyWith(recentPaths: List.unmodifiable(_recentPaths));
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentKey, _recentPaths);
    } catch (_) {
      // ignore persistence errors
    }
  }

  Future<void> _recordLastPath(String path) async {
    if (path.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastPathKey, path);
    } catch (_) {
      // ignore persistence errors
    }
  }
}
