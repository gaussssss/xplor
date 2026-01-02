import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
  });

  final FileEntry entry;
  final ExplorerViewMode viewMode;
  final VoidCallback? onOpen;
  final VoidCallback? onToggleSelection;
  final void Function(Offset globalPosition)? onContextMenu;
  final bool isSelected;
  final bool selectionMode;

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
          )
        : _GridEntry(
            entry: entry,
            onOpen: onOpen,
            onToggleSelection: onToggleSelection,
            onContextMenu: onContextMenu,
            isSelected: isSelected,
            selectionMode: selectionMode,
          );
  }
}

class _ListEntry extends StatelessWidget {
  const _ListEntry({
    required this.entry,
    this.onOpen,
    this.onToggleSelection,
    this.onContextMenu,
    required this.isSelected,
    required this.selectionMode,
  });

  final FileEntry entry;
  final VoidCallback? onOpen;
  final VoidCallback? onToggleSelection;
  final void Function(Offset globalPosition)? onContextMenu;
  final bool isSelected;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = entry.isDirectory
        ? colorScheme.primary
        : (entry.isApplication ? colorScheme.secondary : colorScheme.primary.withValues(alpha: 0.8));
    final iconData = entry.isDirectory
        ? LucideIcons.folder
        : (entry.isApplication ? LucideIcons.appWindow : LucideIcons.file);
    final modifiedLabel =
        entry.lastModified != null ? _formatDate(entry.lastModified!) : '—';

    final leadingWidget = selectionMode
        ? Checkbox(
            value: isSelected,
            onChanged: (_) => onToggleSelection?.call(),
          )
        : _EntryIcon(
            entry: entry,
            icon: iconData,
            color: iconColor,
            size: DesignTokens.iconSizeSmall,
          );

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: onToggleSelection,
      onDoubleTap: onOpen,
      onSecondaryTapDown: (details) => onContextMenu?.call(details.globalPosition),
      child: Container(
        height: DesignTokens.fileEntryTileHeight,
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingMD,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
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
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.9),
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
              ),
            ),
            SizedBox(width: DesignTokens.spacingLG),
            SizedBox(
              width: 80,
              child: Text(
                _formatSize(entry.size),
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridEntry extends StatelessWidget {
  const _GridEntry({
    required this.entry,
    this.onOpen,
    this.onToggleSelection,
    this.onContextMenu,
    required this.isSelected,
    required this.selectionMode,
  });

  final FileEntry entry;
  final VoidCallback? onOpen;
  final VoidCallback? onToggleSelection;
  final void Function(Offset globalPosition)? onContextMenu;
  final bool isSelected;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = entry.isDirectory
        ? colorScheme.primary
        : (entry.isApplication
            ? colorScheme.secondary
            : colorScheme.onSurface.withValues(alpha: 0.7));
    final iconData = entry.isDirectory
        ? LucideIcons.folder
        : (entry.isApplication ? LucideIcons.appWindow : LucideIcons.file);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggleSelection,
      onDoubleTap: onOpen,
      onSecondaryTapDown: (details) => onContextMenu?.call(details.globalPosition),
      child: Container(
        padding: EdgeInsets.all(DesignTokens.paddingMD),
        decoration: BoxDecoration(
          borderRadius: DesignTokens.borderRadiusXS,
          // Pas de border - trop chargé
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(DesignTokens.paddingMD),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: DesignTokens.borderRadiusXS,
                  ),
                child: _EntryIcon(
                  entry: entry,
                  icon: iconData,
                  color: iconColor,
                  size: DesignTokens.iconSizeXLarge,
                ),
                ),
                const Spacer(),
                if (selectionMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggleSelection?.call(),
                  )
                else
                  Text(
                    _formatSize(entry.size),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                          fontSize: 11,
                        ),
                  ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingMD),
            Text(
              entry.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            SizedBox(height: DesignTokens.spacingXS),
            Text(
              entry.lastModified != null
                  ? 'Modifié le ${_formatDate(entry.lastModified!)}'
                  : 'Date inconnue',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
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
