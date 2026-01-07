import 'dart:io';

class VolumeInfo {
  const VolumeInfo({
    required this.label,
    required this.path,
    required this.usage,
    required this.totalBytes,
  });

  final String label;
  final String path;
  final double usage;
  final int totalBytes;
}

class VolumeInfoService {
  List<VolumeInfo> readVolumes() {
    final physicalPaths = <String>{};
    final cloudPaths = <String>[];

    // 1. Volumes physiques montes dans /Volumes
    final volumesDir = Directory('/Volumes');
    if (volumesDir.existsSync()) {
      for (final entity in volumesDir.listSync()) {
        physicalPaths.add(entity.path);
      }
    }

    // 2. Services cloud - chemins typiques sur macOS
    final home = Platform.environment['HOME'] ?? '';
    if (home.isNotEmpty) {
      final potentialCloudPaths = [
        // iCloud Drive
        '$home/Library/Mobile Documents/com~apple~CloudDocs',
        // Google Drive (nouveau format CloudStorage)
        '$home/Library/CloudStorage',
        // OneDrive (plusieurs variantes)
        '$home/OneDrive',
        '$home/OneDrive - Personal',
        // Dropbox
        '$home/Dropbox',
      ];

      for (final cloudPath in potentialCloudPaths) {
        final dir = Directory(cloudPath);

        // Pour CloudStorage, lister les sous-dossiers (GoogleDrive, OneDrive, etc.)
        if (cloudPath.contains('CloudStorage') && dir.existsSync()) {
          try {
            for (final entity in dir.listSync()) {
              if (entity is Directory) {
                cloudPaths.add(entity.path);
              }
            }
          } catch (_) {
            // Ignorer les erreurs de permission
          }
        } else if (dir.existsSync()) {
          cloudPaths.add(cloudPath);
        }
      }
    }

    final volumes = <VolumeInfo>[];

    // Ajouter les volumes physiques
    for (final path in physicalPaths) {
      final info = _getVolumeInfo(path);
      if (info != null) {
        volumes.add(info);
      }
    }

    // Ajouter les services cloud (avec info simplifiee)
    for (final path in cloudPaths) {
      final info = _getCloudInfo(path);
      if (info != null) {
        volumes.add(info);
      }
    }

    return volumes;
  }

  VolumeInfo? _getVolumeInfo(String path) {
    try {
      final result = Process.runSync('df', ['-Pk', path]);
      if (result.exitCode != 0) return null;
      final lines = (result.stdout as String)
          .trim()
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      if (lines.length < 2) return null;

      // Parse the last line (actual data, skipping header)
      final line = lines.last;
      final parts = line.split(RegExp(r'\s+'));

      // Format: Filesystem | 1024-blocks | Used | Available | Capacity% | Mounted on
      if (parts.length < 6) return null;

      final totalKilobytes = double.tryParse(parts[1]);
      if (totalKilobytes == null || totalKilobytes <= 0) return null;

      // Extract capacity percentage (remove % and parse as double)
      final capacityStr = parts[4];
      final capacityPercent =
          double.tryParse(capacityStr.replaceAll('%', '')) ?? 0;
      final usage = capacityPercent / 100.0; // Convert to 0.0-1.0 range

      // Mount point can have spaces, so join remaining parts
      final mountPoint = parts.sublist(5).join(' ');

      // Extract label from mount point with cloud service detection
      final label = _extractVolumeLabel(mountPoint);

      // totalKilobytes is in 1024-byte blocks (from df -Pk), so multiply by 1024 for bytes
      final totalBytes = (totalKilobytes * 1024).toInt();

      return VolumeInfo(
        label: label,
        path: mountPoint,
        usage: usage,
        totalBytes: totalBytes,
      );
    } catch (_) {
      return null;
    }
  }

  /// Cree une info de volume pour un service cloud
  /// Utilise le disque systeme pour les stats mais avec un label cloud
  VolumeInfo? _getCloudInfo(String path) {
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) return null;

      // Obtenir les infos du disque systeme (les dossiers cloud sont sur le disque local)
      final result = Process.runSync('df', ['-Pk', path]);
      if (result.exitCode != 0) return null;

      final lines = (result.stdout as String)
          .trim()
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      if (lines.length < 2) return null;

      final line = lines.last;
      final parts = line.split(RegExp(r'\s+'));

      if (parts.length < 6) return null;

      final totalKilobytes = double.tryParse(parts[1]);
      if (totalKilobytes == null || totalKilobytes <= 0) return null;

      final capacityStr = parts[4];
      final capacityPercent =
          double.tryParse(capacityStr.replaceAll('%', '')) ?? 0;
      final usage = capacityPercent / 100.0;

      // Utiliser le label cloud au lieu du mount point
      final label = _extractVolumeLabel(path);
      final totalBytes = (totalKilobytes * 1024).toInt();

      return VolumeInfo(
        label: label,
        path: path, // Utiliser le chemin cloud, pas le mount point systeme
        usage: usage,
        totalBytes: totalBytes,
      );
    } catch (_) {
      return null;
    }
  }

  /// Extrait un nom lisible pour un volume ou service cloud
  String _extractVolumeLabel(String path) {
    final normalized = path.trim();
    if (normalized == '/' || normalized == '/System/Volumes/Data') {
      return 'Racine';
    }
    // Detection des services cloud avec emojis et noms clairs
    if (normalized.contains('com~apple~CloudDocs')) {
      return 'iCloud Drive';
    }
    if (normalized.contains('GoogleDrive')) {
      // Extraire l'email si present: GoogleDrive-email@gmail.com
      final match = RegExp(r'GoogleDrive-(.+?)(?:/|$)').firstMatch(normalized);
      if (match != null) {
        final email = match.group(1) ?? '';
        return 'Google Drive ($email)';
      }
      return 'Google Drive';
    }
    if (normalized.contains('OneDrive')) {
      if (normalized.contains('Personal')) {
        return 'OneDrive Personal';
      } else if (normalized.contains('Business')) {
        return 'OneDrive Business';
      }
      return 'OneDrive';
    }
    if (normalized.contains('Dropbox')) {
      return 'Dropbox';
    }

    // Pour les volumes physiques, extraire le dernier segment du chemin
    final label = normalized
        .split(Platform.pathSeparator)
        .where((p) => p.isNotEmpty)
        .lastWhere((p) => p.isNotEmpty, orElse: () => normalized);

    return label;
  }
}
