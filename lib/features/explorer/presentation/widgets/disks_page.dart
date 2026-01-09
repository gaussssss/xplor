import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;

import '../../../../core/constants/assets.dart';
import '../services/volume_info_service.dart';

final Map<String, Future<bool>> _diskAssetPresenceCache = {};

class DisksPage extends StatelessWidget {
  const DisksPage({
    super.key,
    required this.volumes,
    required this.onNavigate,
    this.onRefresh,
  });

  final List<VolumeInfo> volumes;
  final void Function(String path) onNavigate;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final onSurface = theme.colorScheme.onSurface;
    final headerText = onSurface.withValues(alpha: isLight ? 0.9 : 0.95);
    final subtitleText = onSurface.withValues(alpha: isLight ? 0.6 : 0.7);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Icon(
                  lucide.LucideIcons.hardDrive,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tous les disques',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: headerText,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stockage local et services cloud',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtitleText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  tooltip: 'Actualiser',
                  onPressed: onRefresh,
                  icon: const Icon(lucide.LucideIcons.refreshCcw),
                  color: headerText,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: volumes.isEmpty
                ? _EmptyVolumes(onRefresh: onRefresh)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width >= 1020
                          ? 3
                          : (width >= 660 ? 2 : 1);
                      return GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 4.1,
                        ),
                        itemCount: volumes.length,
                        itemBuilder: (context, index) {
                          final volume = volumes[index];
                          final percent =
                              (volume.usage * 100).clamp(0, 100).round();
                          return _DiskTile(
                            volume: volume,
                            percent: percent,
                            headerText: headerText,
                            subtitleText: subtitleText,
                            primary: theme.colorScheme.primary,
                            onSurface: onSurface,
                            onTap: () => onNavigate(volume.path),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

}

Widget _buildVolumeIcon(VolumeInfo volume, Color primary, Color onSurface) {
  final logo = _cloudLogoFor(volume);
  final bg = logo != null
      ? onSurface.withValues(alpha: 0.06)
      : primary.withValues(alpha: 0.1);
  return Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(7),
    ),
    alignment: Alignment.center,
    child: logo != null
        ? FutureBuilder<bool>(
            future: _assetAvailable(logo),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Icon(
                  lucide.LucideIcons.hardDrive,
                  color: primary,
                  size: 16,
                );
              }
              if (snapshot.data == true) {
                return Image.asset(logo, width: 18, height: 18);
              }
              return Icon(
                lucide.LucideIcons.hardDrive,
                color: primary,
                size: 16,
              );
            },
          )
        : Icon(lucide.LucideIcons.hardDrive, color: primary, size: 16),
  );
}

String? _cloudLogoFor(VolumeInfo volume) {
  final label = volume.label.toLowerCase();
  final path = volume.path.toLowerCase();

  bool match(List<String> needles) {
    for (final needle in needles) {
      final n = needle.toLowerCase();
      if (label.contains(n) || path.contains(n)) return true;
    }
    return false;
  }

  if (match([
    'icloud',
    'clouddocs',
    'mobile documents',
    'cloudstorage/icloud',
  ])) {
    return AppAssets.iCloud_logo;
  }

  if (match([
    'google drive',
    'googledrive',
    'cloudstorage/googledrive',
    'drivefs',
  ])) {
    return AppAssets.google_Drive_logo;
  }

  if (match(['onedrive', 'cloudstorage/onedrive'])) {
    return AppAssets.oneDrive_logo;
  }

  return null;
}

Future<bool> _assetAvailable(String asset) {
  return _diskAssetPresenceCache.putIfAbsent(asset, () async {
    try {
      await rootBundle.load(asset);
      return true;
    } catch (_) {
      return false;
    }
  });
}

class _DiskTile extends StatelessWidget {
  const _DiskTile({
    required this.volume,
    required this.percent,
    required this.headerText,
    required this.subtitleText,
    required this.primary,
    required this.onSurface,
    required this.onTap,
  });

  final VolumeInfo volume;
  final int percent;
  final Color headerText;
  final Color subtitleText;
  final Color primary;
  final Color onSurface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final tileBg = isLight
        ? onSurface.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.05);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: onSurface.withValues(alpha: isLight ? 0.06 : 0.1),
                ),
              ),
              child: Row(
                children: [
                  _buildVolumeIcon(volume, primary, onSurface),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          volume.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: headerText,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          volume.path,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: subtitleText,
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: volume.usage.clamp(0, 1),
                            minHeight: 3,
                            backgroundColor:
                                onSurface.withValues(alpha: 0.08),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$percent%',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: headerText,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatBytes(volume.totalBytes),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtitleText,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '—';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    final precision = value >= 10 ? 0 : 1;
    return '${value.toStringAsFixed(precision)} ${units[unitIndex]}';
  }
}

class _EmptyVolumes extends StatelessWidget {
  const _EmptyVolumes({this.onRefresh});

  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              lucide.LucideIcons.hardDrive,
              size: 48,
              color: onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun disque détecté',
              style: theme.textTheme.titleMedium?.copyWith(
                color: onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Branchez un disque ou vérifiez vos services cloud.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(lucide.LucideIcons.refreshCcw),
                label: const Text('Actualiser'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
