import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer l'état de l'onboarding
class OnboardingService {
  static const String _onboardingKey = 'onboarding_completed';
  static const String _preferredRootKey = 'preferred_root_path';
  static const String _preferredRootsKey = 'preferred_root_paths';

  /// Vérifie si l'onboarding a été complété
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  /// Marque l'onboarding comme complété
  static Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, completed);
  }

  /// Réinitialise l'onboarding (pour le debug)
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
  }

  static Future<String?> getPreferredRootPath() async {
    final prefs = await SharedPreferences.getInstance();
    final single = prefs.getString(_preferredRootKey);
    if (single != null && single.trim().isNotEmpty) {
      return single.trim();
    }
    final list = prefs.getStringList(_preferredRootsKey);
    if (list != null) {
      for (final path in list) {
        if (path.trim().isNotEmpty) return path.trim();
      }
    }
    return null;
  }

  static Future<void> setPreferredRootPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.trim().isEmpty) {
      await prefs.remove(_preferredRootKey);
      await prefs.remove(_preferredRootsKey);
      return;
    }
    final trimmed = path.trim();
    await prefs.setString(_preferredRootKey, trimmed);
    await prefs.setStringList(_preferredRootsKey, [trimmed]);
  }

  static Future<List<String>> getPreferredRootPaths() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_preferredRootsKey);
    if (list != null && list.isNotEmpty) {
      return list.map((value) => value.trim()).where((value) => value.isNotEmpty).toList();
    }
    final single = prefs.getString(_preferredRootKey);
    if (single != null && single.trim().isNotEmpty) {
      return [single.trim()];
    }
    return [];
  }

  static Future<void> setPreferredRootPaths(List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = paths
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    if (normalized.isEmpty) {
      await prefs.remove(_preferredRootsKey);
      await prefs.remove(_preferredRootKey);
      return;
    }
    await prefs.setStringList(_preferredRootsKey, normalized);
    await prefs.setString(_preferredRootKey, normalized.first);
  }
}
