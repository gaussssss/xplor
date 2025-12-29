import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    final iconColor = entry.isDirectory
        ? Colors.amberAccent.shade200
        : (entry.isApplication ? Colors.greenAccent.shade200 : Colors.blueGrey.shade200);
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
            size: 22,
          );

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: onToggleSelection,
      onDoubleTap: onOpen,
      onSecondaryTapDown: (details) => onContextMenu?.call(details.globalPosition),
      child: ListTile(
        leading: IconTheme(
          data: const IconThemeData(size: 22),
          child: leadingWidget,
        ),
        selected: isSelected,
        selectedTileColor: Colors.white.withOpacity(0.05),
        title: Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('Modifie le $modifiedLabel'),
        trailing: Text(_formatSize(entry.size)),
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
        : (entry.isApplication ? Colors.greenAccent.shade200 : Colors.white70);
    final iconData = entry.isDirectory
        ? LucideIcons.folder
        : (entry.isApplication ? LucideIcons.appWindow : LucideIcons.file);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggleSelection,
      onDoubleTap: onOpen,
      onSecondaryTapDown: (details) => onContextMenu?.call(details.globalPosition),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
          color: Theme.of(context)
              .cardColor
              .withOpacity(isSelected ? 1 : 0.85),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _EntryIcon(
                    entry: entry,
                    icon: iconData,
                    color: iconColor,
                    size: 26,
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
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: Colors.white70),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              entry.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              entry.lastModified != null
                  ? 'Modifie le ${_formatDate(entry.lastModified!)}'
                  : 'Date inconnue',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.white70),
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
        borderRadius: BorderRadius.circular(8),
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
