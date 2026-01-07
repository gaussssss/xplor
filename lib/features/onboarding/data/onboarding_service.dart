import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer l'état de l'onboarding
class OnboardingService {
  static const String _onboardingKey = 'onboarding_completed';
  static const String _preferredRootKey = 'preferred_root_path';

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
    return prefs.getString(_preferredRootKey);
  }

  static Future<void> setPreferredRootPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.trim().isEmpty) {
      await prefs.remove(_preferredRootKey);
      return;
    }
    await prefs.setString(_preferredRootKey, path.trim());
  }
}
