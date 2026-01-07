import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/entities/file_entry.dart';
import '../viewmodels/explorer_view_model.dart';

class FileEntryTile extends StatelessWidget {
  const FileEntryTile({
    super.key,
    required this.entry,
    this.viewMode = ExplorerViewMode.list,
    this.onOpen,
    this.onToggleSelection,
    this.onContextMenu,
    this.isSelected = false,
    this.selectionMode = false,
    this.enableDrop = true,
  });

  final FileEntry entry;
  final ExplorerViewMode viewMode;
  final VoidCallback? onOpen;
  final VoidCallback? onToggleSelection;
  final void Function(Offset globalPosition)? onContextMenu;
  final bool isSelected;
  final bool selectionMode;
  final bool enableDrop;

  @override
  Widget build(BuildContext context) {
    return viewMode == ExplorerViewMode.list
        ? _ListEntry(
            entry: entry,
            onOpen: onOpen,
            onToggleSelection: onToggleSelection,
            onContextMenu: onContextMenu,
            isSelected: isSelected,
            selectionMode: selectionMode,
            enableDrop: enableDrop,
          )
        : _GridEntry(
            entry: entry,
            onOpen: onOpen,
            onToggleSelection: onToggleSelection,
            onContextMenu: onContextMenu,
            isSelected: isSelected,
            selectionMode: selectionMode,
            enableDrop: enableDrop,
          );
  }
}

class _ListEntry extends StatefulWidget {
  const _ListEntry({
    required this.entry,
    this.onOpen,
    this.onToggleSelection,
    this.onContextMenu,
    required this.isSelected,
    required this.selectionMode,
    required this.enableDrop,
  });

  final FileEntry entry;
  final VoidCallback? onOpen;
  final VoidCallback? onToggleSelection;
  final void Function(Offset globalPosition)? onContextMenu;
  final bool isSelected;
  final bool selectionMode;
  final bool enableDrop;

  @override
  State<_ListEntry> createState() => _ListEntryState();
}

class _ListEntryState extends State<_ListEntry> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final isLight = themeProvider.isLight;

    final iconColor = widget.entry.isDirectory
        ? colorScheme.primary
        : (widget.entry.isApplication ? colorScheme.secondary : colorScheme.primary.withValues(alpha: 0.8));
    final iconData = widget.entry.isDirectory
        ? LucideIcons.folder
        : (widget.entry.isApplication ? LucideIcons.appWindow : LucideIcons.file);
    final modifiedLabel =
        widget.entry.lastModified != null ? _formatDate(widget.entry.lastModified!) : '—';

    final leadingWidget = widget.selectionMode
        ? Checkbox(
            value: widget.isSelected,
            onChanged: (_) => widget.onToggleSelection?.call(),
          )
        : _EntryIcon(
            entry: widget.entry,
            icon: iconData,
            color: iconColor,
            size: DesignTokens.iconSizeSmall,
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onToggleSelection,
        onDoubleTap: widget.onOpen,
        onSecondaryTapDown: (details) => widget.onContextMenu?.call(details.globalPosition),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: DesignTokens.fileEntryTileHeight,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMD,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? colorScheme.primary.withValues(alpha: 0.12)
                : (_isHovered
                    ? (isLight
                        ? Colors.black.withValues(alpha: 0.04)
                        : Colors.white.withValues(alpha: 0.06))
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              SizedBox(
                width: DesignTokens.iconSizeMedium,
                child: IconTheme(
                  data: IconThemeData(size: DesignTokens.iconSizeSmall),
                  child: leadingWidget,
                ),
              ),
              SizedBox(width: DesignTokens.spacingMD),
              Expanded(
                flex: 3,
                child: Text(
                  widget.entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
              ),
              SizedBox(width: DesignTokens.spacingLG),
              Expanded(
                flex: 2,
                child: Text(
                  'Modifié le $modifiedLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(width: DesignTokens.spacingLG),
              SizedBox(
                width: 80,
                child: Text(
                  _formatSize(widget.entry.size),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridEntry extends StatefulWidget {
  const _GridEntry({
    required this.entry,
    this.onOpen,
    this.onToggleSelection,
    this.onContextMenu,
    required this.isSelected,
    required this.selectionMode,
    required this.enableDrop,
  });

  final FileEntry entry;
  final VoidCallback? onOpen;
  final VoidCallback? onToggleSelection;
  final void Function(Offset globalPosition)? onContextMenu;
  final bool isSelected;
  final bool selectionMode;
  final bool enableDrop;

  @override
  State<_GridEntry> createState() => _GridEntryState();
}

class _GridEntryState extends State<_GridEntry> {
  bool _isHovered = false;
  bool _isDragTarget = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final isLight = themeProvider.isLight;

    final iconColor = widget.entry.isDirectory
        ? colorScheme.primary
        : (widget.entry.isApplication
            ? colorScheme.secondary
            : colorScheme.onSurface.withValues(alpha: 0.7));

    final baseWidget = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onToggleSelection,
        onDoubleTap: widget.onOpen,
        onSecondaryTapDown: (details) => widget.onContextMenu?.call(details.globalPosition),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: widget.isSelected
                ? colorScheme.primary.withValues(alpha: 0.12)
                : (_isDragTarget
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : (_isHovered
                        ? (isLight
                            ? Colors.black.withValues(alpha: 0.04)
                            : Colors.white.withValues(alpha: 0.06))
                        : Colors.transparent)),
            border: widget.isSelected
                ? Border.all(color: colorScheme.primary.withValues(alpha: 0.3), width: 1.5)
                : (_isDragTarget
                    ? Border.all(color: colorScheme.primary, width: 2)
                    : (_isHovered
                        ? Border.all(
                            color: isLight
                                ? Colors.black.withValues(alpha: 0.1)
                                : Colors.white.withValues(alpha: 0.15),
                            width: 1)
                        : null)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Preview/Icon - BEAUCOUP PLUS GRAND
              Stack(
                children: [
                  _buildPreview(context, iconColor),
                  // Checkbox en haut à droite si sélection mode
                  if (widget.selectionMode)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Checkbox(
                        value: widget.isSelected,
                        onChanged: (_) => widget.onToggleSelection?.call(),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Nom du fichier
              Text(
                widget.entry.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isLight ? Colors.black87 : Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 2),
              // Taille
              Text(
                _formatSize(widget.entry.size),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isLight ? Colors.black.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.55),
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        ),
      ),
    );

    // Wrapper avec Draggable pour drag vers Finder
    final draggableWidget = Draggable<FileEntry>(
      data: widget.entry,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.primary, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.entry.isDirectory ? LucideIcons.folder : LucideIcons.file,
                size: 32,
                color: iconColor,
              ),
              const SizedBox(height: 8),
              Text(
                widget.entry.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: baseWidget,
      ),
      child: baseWidget,
    );

    // Wrapper avec DropTarget si c'est un dossier
    if (widget.entry.isDirectory && widget.enableDrop) {
      return DropTarget(
        onDragEntered: (details) {
          setState(() => _isDragTarget = true);
        },
        onDragExited: (details) {
          setState(() => _isDragTarget = false);
        },
        onDragDone: (details) async {
          setState(() => _isDragTarget = false);

          // Copier les fichiers dans ce dossier
          try {
            for (final file in details.files) {
              final sourcePath = file.path;
              final fileName = sourcePath.split(Platform.pathSeparator).last;
              final targetPath = '${widget.entry.path}${Platform.pathSeparator}$fileName';

              final source = FileSystemEntity.typeSync(sourcePath);
              if (source == FileSystemEntityType.directory) {
                await _copyDirectory(sourcePath, targetPath);
              } else {
                await File(sourcePath).copy(targetPath);
              }
            }
          } catch (e) {
            debugPrint('Erreur lors de la copie: $e');
          }
        },
        child: draggableWidget,
      );
    }

    return draggableWidget;
  }

  // Helper pour copier un dossier récursivement
  Future<void> _copyDirectory(String sourcePath, String targetPath) async {
    final sourceDir = Directory(sourcePath);
    final targetDir = Directory(targetPath);

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    await for (final entity in sourceDir.list(recursive: false)) {
      final fileName = entity.path.split(Platform.pathSeparator).last;
      final newPath = '${targetDir.path}${Platform.pathSeparator}$fileName';

      if (entity is Directory) {
        await _copyDirectory(entity.path, newPath);
      } else if (entity is File) {
        await entity.copy(newPath);
      }
    }
  }

  Widget _buildPreview(BuildContext context, Color iconColor) {
    final ext = widget.entry.name.toLowerCase().split('.').last;
    final isImage = ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'svg'].contains(ext);
    final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv'].contains(ext);
    final isAudio = ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a', 'wma'].contains(ext);

    // Preview d'image
    if (isImage && widget.entry.path.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(widget.entry.path),
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultIcon(context, iconColor),
        ),
      );
    }

    // Preview vidéo (icône play sur fond)
    if (isVideo) {
      return Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(LucideIcons.video, color: iconColor, size: 48),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'VIDEO',
                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Preview audio (pochette)
    if (isAudio) {
      return Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(LucideIcons.disc3, color: iconColor, size: 48),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'AUDIO',
                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Icône par défaut (applications, dossiers, fichiers)
    return _buildDefaultIcon(context, iconColor);
  }

  Widget _buildDefaultIcon(BuildContext context, Color iconColor) {
    IconData iconData;

    if (widget.entry.isDirectory) {
      iconData = LucideIcons.folder;
    } else if (widget.entry.isApplication) {
      iconData = LucideIcons.appWindow;
    } else {
      iconData = LucideIcons.file;
    }

    // Si c'est une application avec un icône personnalisé
    if (widget.entry.iconPath != null && widget.entry.iconPath!.toLowerCase().endsWith('.png')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(widget.entry.iconPath!),
        width: 96,
        height: 96,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconData, color: iconColor, size: 56),
          ),
        ),
      );
    }

    // Icône par défaut
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 56),
    );
  }
}

class _EntryIcon extends StatelessWidget {
  const _EntryIcon({
    required this.entry,
    required this.icon,
    required this.color,
    required this.size,
  });

  final FileEntry entry;
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconPath = entry.iconPath;
    if (iconPath != null && iconPath.toLowerCase().endsWith('.png')) {
      return ClipRRect(
        borderRadius: DesignTokens.borderRadiusXS,
        child: Image.file(
          File(iconPath),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Icon(icon, color: color, size: size),
        ),
      );
    }
    return Icon(icon, color: color, size: size);
  }
}

String _formatSize(int? sizeInBytes) {
  if (sizeInBytes == null || sizeInBytes <= 0) return '—';

  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  double value = sizeInBytes.toDouble();
  var unitIndex = 0;

  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  final precision = value >= 10 ? 0 : 1;
  return '${value.toStringAsFixed(precision)} ${units[unitIndex]}';
}

String _formatDate(DateTime date) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)} '
      '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
}
