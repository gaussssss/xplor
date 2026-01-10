import 'dart:io';
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    this.isLocked = false,
    this.appIconFuture,
    this.previewFuture,
    this.audioArtFuture,
    this.enableDrop = true,
    this.tagColor,
  });

  final FileEntry entry;
  final ExplorerViewMode viewMode;
  final VoidCallback? onOpen;
  final VoidCallback? onToggleSelection;
  final void Function(Offset globalPosition)? onContextMenu;
  final bool isSelected;
  final bool selectionMode;
  final bool isLocked;
  final Future<String?>? appIconFuture;
  final Future<String?>? previewFuture;
  final Future<Uint8List?>? audioArtFuture;
  final bool enableDrop;
  final Color? tagColor;

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
            isLocked: isLocked,
            appIconFuture: appIconFuture,
            audioArtFuture: audioArtFuture,
            enableDrop: enableDrop,
            tagColor: tagColor,
          )
        : _GridEntry(
            entry: entry,
            onOpen: onOpen,
            onToggleSelection: onToggleSelection,
            onContextMenu: onContextMenu,
            isSelected: isSelected,
            selectionMode: selectionMode,
            isLocked: isLocked,
            appIconFuture: appIconFuture,
            previewFuture: previewFuture,
            audioArtFuture: audioArtFuture,
            enableDrop: enableDrop,
            tagColor: tagColor,
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
    required this.isLocked,
    this.appIconFuture,
    this.audioArtFuture,
    required this.enableDrop,
    this.tagColor,
  });

  final FileEntry entry;
  final VoidCallback? onOpen;
  final VoidCallback? onToggleSelection;
  final void Function(Offset globalPosition)? onContextMenu;
  final bool isSelected;
  final bool selectionMode;
  final bool isLocked;
  final Future<String?>? appIconFuture;
  final Future<Uint8List?>? audioArtFuture;
  final bool enableDrop;
  final Color? tagColor;

  @override
  State<_ListEntry> createState() => _ListEntryState();
}

class _ListEntryState extends State<_ListEntry> {
  bool _isHovered = false;
  Future<String?>? _appIconFuture;

  @override
  void initState() {
    super.initState();
    _appIconFuture = widget.appIconFuture;
  }

  @override
  void didUpdateWidget(covariant _ListEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.path != widget.entry.path ||
        oldWidget.appIconFuture != widget.appIconFuture) {
      _appIconFuture = widget.appIconFuture;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final isLight = themeProvider.isLight;

    final iconColor = widget.entry.isDirectory
        ? colorScheme.primary
        : (widget.entry.isApplication
              ? colorScheme.secondary
              : colorScheme.primary.withValues(alpha: 0.8));
    final iconData = _iconForEntry(widget.entry);
    final modifiedLabel = widget.entry.lastModified != null
        ? _formatDate(widget.entry.lastModified!)
        : '—';

    Widget leadingWidget = widget.selectionMode
        ? Checkbox(
            value: widget.isSelected,
            onChanged: (_) => widget.onToggleSelection?.call(),
          )
        : _EntryIconWithBadge(
            entry: widget.entry,
            icon: iconData,
            color: iconColor,
            size: DesignTokens.iconSizeSmall,
            showLock: widget.isLocked,
            tagColor: widget.tagColor,
          );

    if (!widget.selectionMode && !widget.entry.isDirectory) {
      leadingWidget = FutureBuilder<String?>(
        future: _appIconFuture,
        builder: (context, snapshot) {
          final appIconPath = snapshot.data;
          if (appIconPath == null || appIconPath.isEmpty) {
            return _EntryIconWithBadge(
              entry: widget.entry,
              icon: iconData,
              color: iconColor,
              size: DesignTokens.iconSizeSmall,
              showLock: widget.isLocked,
            );
          }
          return _AppIconWithBadge(
            iconPath: appIconPath,
            size: DesignTokens.iconSizeSmall,
            showLock: widget.isLocked,
          );
        },
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onToggleSelection,
        onDoubleTap: widget.onOpen,
        onSecondaryTapDown: (details) =>
            _isModifierPressed()
                ? widget.onToggleSelection?.call()
                : widget.onContextMenu?.call(details.globalPosition),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: DesignTokens.fileEntryTileHeight,
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingMD),
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
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
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

  bool _isModifierPressed() {
    return HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.metaLeft) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.metaRight) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.meta) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.controlLeft) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.controlRight) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.control);
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
    required this.isLocked,
    this.appIconFuture,
    this.previewFuture,
    this.audioArtFuture,
    required this.enableDrop,
    this.tagColor,
  });

  final FileEntry entry;
  final VoidCallback? onOpen;
  final VoidCallback? onToggleSelection;
  final void Function(Offset globalPosition)? onContextMenu;
  final bool isSelected;
  final bool selectionMode;
  final bool isLocked;
  final Future<String?>? appIconFuture;
  final Future<String?>? previewFuture;
  final Future<Uint8List?>? audioArtFuture;
  final bool enableDrop;
  final Color? tagColor;

  @override
  State<_GridEntry> createState() => _GridEntryState();
}

class _GridEntryState extends State<_GridEntry> {
  bool _isHovered = false;
  bool _isDragTarget = false;
  Future<String?>? _appIconFuture;
  Future<String?>? _previewFuture;

  @override
  void initState() {
    super.initState();
    _appIconFuture = widget.appIconFuture;
    _previewFuture = widget.previewFuture;
  }

  @override
  void didUpdateWidget(covariant _GridEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.path != widget.entry.path ||
        oldWidget.appIconFuture != widget.appIconFuture ||
        oldWidget.previewFuture != widget.previewFuture) {
      _appIconFuture = widget.appIconFuture;
      _previewFuture = widget.previewFuture;
    }
  }

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
    final isAudio = _isAudioFile(widget.entry);

    final fallbackPreview = _buildPreview(context, iconColor);
    final previewWidget = _previewFuture == null
        ? fallbackPreview
        : FutureBuilder<String?>(
            future: _previewFuture,
            builder: (context, snapshot) {
              final previewPath = snapshot.data;
              if (previewPath == null || previewPath.isEmpty) {
                return fallbackPreview;
              }
              final file = File(previewPath);
              if (!file.existsSync()) return fallbackPreview;
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  file,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => fallbackPreview,
                ),
              );
            },
          );

    final baseWidget = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onToggleSelection,
        onDoubleTap: widget.onOpen,
        onSecondaryTapDown: (details) =>
            _isModifierPressed()
                ? widget.onToggleSelection?.call()
                : widget.onContextMenu?.call(details.globalPosition),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
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
                ? Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  )
                : (_isDragTarget
                      ? Border.all(color: colorScheme.primary, width: 2)
                      : (_isHovered
                            ? Border.all(
                                color: isLight
                                    ? Colors.black.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              )
                            : null)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Preview/Icon - BEAUCOUP PLUS GRAND
                  Stack(
                    children: [
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: previewWidget,
                      ),
                      if (widget.tagColor != null)
                        Positioned(
                          top: -2,
                          left: -2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.tagColor,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      if (!widget.entry.isDirectory)
                        Positioned(
                          left: -2,
                          bottom: -2,
                          child: FutureBuilder<String?>(
                            future: _appIconFuture,
                            builder: (context, snapshot) {
                              final appIconPath = snapshot.data;
                              if (appIconPath == null || appIconPath.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return _AppIconBadge(iconPath: appIconPath, size: 16);
                            },
                          ),
                        ),
                      if (isAudio)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -2,
                      child: Center(child: _AudioBadge(size: 14)),
                    ),
                  if (widget.isLocked)
                    const Positioned(
                      right: -2,
                      bottom: -2,
                      child: _LockBadge(size: 16),
                    ),
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
              const SizedBox(height: 2),
              // Nom du fichier
              Text(
                widget.entry.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isLight
                      ? Colors.black87
                      : Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              // Taille
              Text(
                _formatSize(widget.entry.size),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isLight
                      ? Colors.black.withValues(alpha: 0.55)
                      : Colors.white.withValues(alpha: 0.55),
                  fontSize: 10,
                ),
              ),
                ],
              );
            },
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
                widget.entry.isDirectory
                    ? LucideIcons.folder
                    : LucideIcons.file,
                size: 32,
                color: iconColor,
              ),
              const SizedBox(height: 8),
              Text(
                widget.entry.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: baseWidget),
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
              final targetPath =
                  '${widget.entry.path}${Platform.pathSeparator}$fileName';

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
    final isSvg = ext == 'svg';
    final isImage = ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'].contains(ext);
    final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv'].contains(ext);
    final isAudio = [
      'mp3',
      'wav',
      'aac',
      'flac',
      'ogg',
      'm4a',
      'wma',
    ].contains(ext);

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

    if (isSvg && widget.entry.path.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SvgPicture.file(
          File(widget.entry.path),
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => _buildDefaultIcon(context, iconColor),
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Preview audio (pochette)
    if (isAudio) {
      final artFuture = widget.audioArtFuture;
      if (artFuture != null) {
        return FutureBuilder<Uint8List?>(
          future: artFuture,
          builder: (context, snapshot) {
            final art = snapshot.data;
            if (art == null || art.isEmpty) {
              return _buildAudioFallback(iconColor);
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                art,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildAudioFallback(iconColor),
              ),
            );
          },
        );
      }
      return _buildAudioFallback(iconColor);
    }

    // Icône par défaut (applications, dossiers, fichiers)
    return _buildDefaultIcon(context, iconColor);
  }

  Widget _buildDefaultIcon(BuildContext context, Color iconColor) {
    final iconData = _iconForEntry(widget.entry);

    // Si c'est une application avec un icône personnalisé
    if (widget.entry.iconPath != null &&
        widget.entry.iconPath!.toLowerCase().endsWith('.png')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(widget.entry.iconPath!),
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconData, color: iconColor, size: 52),
          ),
        ),
      );
    }

    // Icône par défaut
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 52),
    );
  }

  Widget _buildAudioFallback(Color iconColor) {
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isModifierPressed() {
    return HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.metaLeft) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.metaRight) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.meta) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.controlLeft) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.controlRight) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.control);
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
          errorBuilder: (_, __, ___) => Icon(icon, color: color, size: size),
        ),
      );
    }
    return Icon(icon, color: color, size: size);
  }
}

class _AppIconWithBadge extends StatelessWidget {
  const _AppIconWithBadge({
    required this.iconPath,
    required this.size,
    required this.showLock,
  });

  final String iconPath;
  final double size;
  final bool showLock;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: DesignTokens.borderRadiusXS,
              child: Image.file(
                File(iconPath),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  LucideIcons.file,
                  size: size,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (showLock)
            Positioned(
              right: -2,
              bottom: -2,
              child: _LockBadge(
                size: (size * 0.6).clamp(10.0, 16.0).toDouble(),
              ),
            ),
        ],
      ),
    );
  }
}

class _EntryIconWithBadge extends StatelessWidget {
  const _EntryIconWithBadge({
    required this.entry,
    required this.icon,
    required this.color,
    required this.size,
    required this.showLock,
    this.tagColor,
  });

  final FileEntry entry;
  final IconData icon;
  final Color color;
  final double size;
  final bool showLock;
  final Color? tagColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: _EntryIcon(
              entry: entry,
              icon: icon,
              color: color,
              size: size,
            ),
          ),
          if (tagColor != null)
            Positioned(
              top: -2,
              left: -2,
              child: Container(
                width: (size * 0.35).clamp(8.0, 12.0),
                height: (size * 0.35).clamp(8.0, 12.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tagColor,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          if (showLock)
            Positioned(
              right: -2,
              bottom: -2,
              child: _LockBadge(
                size: (size * 0.6).clamp(10.0, 16.0).toDouble(),
              ),
            ),
        ],
      ),
    );
  }
}

class _AppIconBadge extends StatelessWidget {
  const _AppIconBadge({required this.iconPath, required this.size});

  final String iconPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: surface.withValues(alpha: 0.9),
        border: Border.all(color: surface.withValues(alpha: 0.9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.file(
          File(iconPath),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            LucideIcons.appWindow,
            size: size * 0.6,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _LockBadge extends StatelessWidget {
  const _LockBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surface = theme.colorScheme.surface;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primary,
        border: Border.all(color: surface.withValues(alpha: 0.85), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          LucideIcons.lock,
          size: size * 0.58,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _AudioBadge extends StatelessWidget {
  const _AudioBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: surface.withValues(alpha: 0.9),
        border: Border.all(color: surface.withValues(alpha: 0.9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        LucideIcons.music,
        size: size * 0.6,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

IconData _iconForEntry(FileEntry entry) {
  if (entry.isDirectory) return LucideIcons.folder;
  if (entry.isApplication) return LucideIcons.appWindow;
  final ext = entry.name.toLowerCase().split('.').last;
  switch (ext) {
    case 'pdf':
      return LucideIcons.fileText;
    case 'doc':
    case 'docx':
    case 'rtf':
    case 'odt':
      return LucideIcons.fileText;
    case 'ppt':
    case 'pptx':
    case 'key':
      return LucideIcons.presentation;
    case 'xls':
    case 'xlsx':
    case 'csv':
      return LucideIcons.fileSpreadsheet;
    case 'txt':
    case 'md':
    case 'json':
    case 'xml':
    case 'yaml':
    case 'yml':
      return LucideIcons.fileCode2;
    case 'zip':
    case 'rar':
    case '7z':
    case 'tar':
    case 'gz':
      return LucideIcons.fileArchive;
    case 'mp3':
    case 'wav':
    case 'aac':
    case 'flac':
    case 'ogg':
    case 'm4a':
    case 'wma':
      return LucideIcons.fileAudio;
    case 'mp4':
    case 'mov':
    case 'avi':
    case 'mkv':
    case 'webm':
    case 'flv':
      return LucideIcons.fileVideo;
    case 'png':
    case 'jpg':
    case 'jpeg':
    case 'gif':
    case 'webp':
    case 'bmp':
    case 'svg':
      return LucideIcons.fileImage;
    default:
      return LucideIcons.file;
  }
}

bool _isAudioFile(FileEntry entry) {
  final ext = entry.name.toLowerCase().split('.').last;
  return ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a', 'wma'].contains(ext);
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
