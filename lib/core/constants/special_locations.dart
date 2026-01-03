import 'dart:io';

/// Emplacements spéciaux virtuels pour Xplor
class SpecialLocations {
  /// Code pour l'emplacement "Fichiers récents"
  static const String recentFiles = 'xplor://recent';

  /// Code pour l'emplacement "Favoris"
  static const String favorites = 'xplor://favorites';

  /// Code pour l'emplacement "Téléchargements"
  static String get downloads {
    if (Platform.isMacOS) {
      return '${Platform.environment['HOME']}/Downloads';
    } else if (Platform.isWindows) {
      return '${Platform.environment['USERPROFILE']}\\Downloads';
    } else {
      return '${Platform.environment['HOME']}/Downloads';
    }
  }

  /// Code pour l'emplacement "Documents"
  static String get documents {
    if (Platform.isMacOS) {
      return '${Platform.environment['HOME']}/Documents';
    } else if (Platform.isWindows) {
      return '${Platform.environment['USERPROFILE']}\\Documents';
    } else {
      return '${Platform.environment['HOME']}/Documents';
    }
  }

  /// Code pour l'emplacement "Bureau"
  static String get desktop {
    if (Platform.isMacOS) {
      return '${Platform.environment['HOME']}/Desktop';
    } else if (Platform.isWindows) {
      return '${Platform.environment['USERPROFILE']}\\Desktop';
    } else {
      return '${Platform.environment['HOME']}/Desktop';
    }
  }

  /// Code pour l'emplacement "Images"
  static String get pictures {
    if (Platform.isMacOS) {
      return '${Platform.environment['HOME']}/Pictures';
    } else if (Platform.isWindows) {
      return '${Platform.environment['USERPROFILE']}\\Pictures';
    } else {
      return '${Platform.environment['HOME']}/Pictures';
    }
  }

  /// Code pour l'emplacement "Applications"
  static String get applications {
    if (Platform.isMacOS) {
      return '/Applications';
    } else if (Platform.isWindows) {
      return Platform.environment['PROGRAMFILES'] ?? 'C:\\\\Program Files';
    } else {
      // Point de chute raisonnable pour Linux/Unix
      return '/usr/share/applications';
    }
  }

  /// Vérifie si un chemin est un emplacement spécial
  static bool isSpecialLocation(String path) {
    return path.startsWith('xplor://');
  }

  /// Obtient le libellé d'affichage pour un emplacement spécial
  static String getDisplayName(String path) {
    switch (path) {
      case recentFiles:
        return 'Récemment consulté';
      case favorites:
        return 'Favoris';
      default:
        // Pour les chemins système, extraire le nom du dernier segment
        final segments = path.split(Platform.pathSeparator);
        return segments.isNotEmpty ? segments.last : path;
    }
  }

  /// Résout un chemin système vers son chemin réel (sans sandbox)
  static String resolveSystemPath(String path) {
    // Si c'est un chemin sandbox (containers), essayer de trouver le vrai chemin
    if (path.contains('/Containers/') && Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        // Remplacer le chemin sandbox par le vrai chemin home
        if (path.contains('/Documents')) {
          return '$home/Documents';
        } else if (path.contains('/Downloads')) {
          return '$home/Downloads';
        } else if (path.contains('/Desktop')) {
          return '$home/Desktop';
        } else if (path.contains('/Pictures')) {
          return '$home/Pictures';
        }
      }
    }
    return path;
  }

  /// Obtient tous les emplacements spéciaux disponibles
  static List<SpecialLocationInfo> getAllSpecialLocations() {
    return [
      SpecialLocationInfo(
        code: recentFiles,
        displayName: 'Fichiers récents',
        isVirtual: true,
      ),
      SpecialLocationInfo(
        code: downloads,
        displayName: 'Téléchargements',
        isVirtual: false,
      ),
      SpecialLocationInfo(
        code: documents,
        displayName: 'Documents',
        isVirtual: false,
      ),
      SpecialLocationInfo(
        code: desktop,
        displayName: 'Bureau',
        isVirtual: false,
      ),
      SpecialLocationInfo(
        code: pictures,
        displayName: 'Images',
        isVirtual: false,
      ),
      SpecialLocationInfo(
        code: applications,
        displayName: 'Applications',
        isVirtual: false,
      ),
    ];
  }
}

/// Information sur un emplacement spécial
class SpecialLocationInfo {
  const SpecialLocationInfo({
    required this.code,
    required this.displayName,
    required this.isVirtual,
  });

  final String code;
  final String displayName;
  final bool isVirtual;
}
