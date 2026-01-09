import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../domain/entities/file_entry.dart';

/// Colonne disponible pour la vue liste
enum FileColumn {
  name,
  size,
  dateModified,
  kind,
  dateCreated,
  dateAccessed,
  permissions,
  tags,
}

/// Configuration d'une colonne
class ColumnConfig {
  const ColumnConfig({
    required this.column,
    required this.label,
    required this.width,
    this.minWidth = 80,
    this.maxWidth = 500,
  });

  final FileColumn column;
  final String label;
  final double width;
  final double minWidth;
  final double maxWidth;
}

/// Ordre de tri
enum SortOrder {
  ascending,
  descending,
}

/// Configuration de tri
class SortConfig {
  const SortConfig({
    required this.column,
    required this.order,
  });

  final FileColumn column;
  final SortOrder order;

  SortConfig toggle() {
    return SortConfig(
      column: column,
      order: order == SortOrder.ascending
          ? SortOrder.descending
          : SortOrder.ascending,
    );
  }
}

/// Vue liste avec colonnes configurables
class ListViewTable extends StatefulWidget {
  const ListViewTable({
    super.key,
    required this.entries,
    required this.onEntryTap,
    required this.onEntryDoubleTap,
    required this.onEntrySecondaryTap,
    required this.isSelected,
    this.selectionMode = false,
    this.scrollController,
  });

  final List<FileEntry> entries;
  final void Function(FileEntry) onEntryTap;
  final void Function(FileEntry) onEntryDoubleTap;
  final void Function(FileEntry, Offset) onEntrySecondaryTap;
  final bool Function(FileEntry) isSelected;
  final bool selectionMode;
  final ScrollController? scrollController;

  @override
  State<ListViewTable> createState() => _ListViewTableState();
}

class _ListViewTableState extends State<ListViewTable> {
  // Colonnes par défaut
  List<ColumnConfig> _columns = [
    const ColumnConfig(column: FileColumn.name, label: 'Nom', width: 300),
    const ColumnConfig(column: FileColumn.dateModified, label: 'Date de modification', width: 180),
    const ColumnConfig(column: FileColumn.kind, label: 'Type', width: 120),
    const ColumnConfig(column: FileColumn.size, label: 'Taille', width: 100),
  ];

  SortConfig? _sortConfig;
  final Set<String> _hoveredRows = {};

  @override
  void initState() {
    super.initState();
    _loadColumnPreferences();
    _loadSortPreferences();
  }

  Future<void> _loadColumnPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final columnsData = prefs.getStringList('list_view_columns');
      final widthsData = prefs.getStringList('list_view_column_widths');

      if (columnsData != null && widthsData != null && columnsData.length == widthsData.length) {
        final loadedColumns = <ColumnConfig>[];
        for (int i = 0; i < columnsData.length; i++) {
          final columnName = columnsData[i];
          final width = double.tryParse(widthsData[i]) ?? 100.0;
          final column = FileColumn.values.firstWhere(
            (c) => c.name == columnName,
            orElse: () => FileColumn.name,
          );
          final config = _getColumnConfig(column, width);
          if (config != null) loadedColumns.add(config);
        }

        if (loadedColumns.isNotEmpty && mounted) {
          setState(() {
            _columns = loadedColumns;
          });
        }
      }
    } catch (_) {
      // Ignorer les erreurs de chargement, utiliser les colonnes par défaut
    }
  }

  ColumnConfig? _getColumnConfig(FileColumn column, double width) {
    switch (column) {
      case FileColumn.name:
        return ColumnConfig(column: column, label: 'Nom', width: width);
      case FileColumn.size:
        return ColumnConfig(column: column, label: 'Taille', width: width);
      case FileColumn.dateModified:
        return ColumnConfig(column: column, label: 'Date de modification', width: width);
      case FileColumn.kind:
        return ColumnConfig(column: column, label: 'Type', width: width);
      case FileColumn.dateCreated:
        return ColumnConfig(column: column, label: 'Date de création', width: width);
      case FileColumn.dateAccessed:
        return ColumnConfig(column: column, label: 'Dernier accès', width: width);
      case FileColumn.permissions:
        return ColumnConfig(column: column, label: 'Permissions', width: width);
      case FileColumn.tags:
        return ColumnConfig(column: column, label: 'Tags', width: width);
    }
  }

  Future<void> _loadSortPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sortColumnName = prefs.getString('list_view_sort_column');
      final sortOrderName = prefs.getString('list_view_sort_order');
      if (sortColumnName == null || sortOrderName == null) return;
      final column = FileColumn.values.firstWhere(
        (c) => c.name == sortColumnName,
        orElse: () => FileColumn.name,
      );
      final order = SortOrder.values.firstWhere(
        (o) => o.name == sortOrderName,
        orElse: () => SortOrder.ascending,
      );
      if (!mounted) return;
      setState(() {
        _sortConfig = SortConfig(column: column, order: order);
      });
    } catch (_) {
      // Ignorer les erreurs de chargement
    }
  }

  Future<void> _saveColumnPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final columnNames = _columns.map((c) => c.column.name).toList();
      final columnWidths = _columns.map((c) => c.width.toString()).toList();
      await prefs.setStringList('list_view_columns', columnNames);
      await prefs.setStringList('list_view_column_widths', columnWidths);
    } catch (_) {
      // Ignorer les erreurs de sauvegarde
    }
  }

  Future<void> _saveSortPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_sortConfig == null) {
        await prefs.remove('list_view_sort_column');
        await prefs.remove('list_view_sort_order');
        return;
      }
      await prefs.setString('list_view_sort_column', _sortConfig!.column.name);
      await prefs.setString('list_view_sort_order', _sortConfig!.order.name);
    } catch (_) {
      // Ignorer les erreurs de sauvegarde
    }
  }

  // Colonnes disponibles mais non affichées
  static const _availableColumns = [
    ColumnConfig(column: FileColumn.dateCreated, label: 'Date de création', width: 180),
    ColumnConfig(column: FileColumn.dateAccessed, label: 'Dernier accès', width: 180),
    ColumnConfig(column: FileColumn.permissions, label: 'Permissions', width: 100),
    ColumnConfig(column: FileColumn.tags, label: 'Tags', width: 120),
  ];

  List<FileEntry> get _sortedEntries {
    if (_sortConfig == null) return widget.entries;

    final sorted = List<FileEntry>.from(widget.entries);
    sorted.sort((a, b) {
      int comparison = 0;

      switch (_sortConfig!.column) {
        case FileColumn.name:
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case FileColumn.size:
          comparison = (a.size ?? 0).compareTo(b.size ?? 0);
          break;
        case FileColumn.dateModified:
          comparison = (a.lastModified ?? DateTime(1970))
              .compareTo(b.lastModified ?? DateTime(1970));
          break;
        case FileColumn.kind:
          final aType = a.isDirectory ? 'Dossier' : _getFileType(a.name);
          final bType = b.isDirectory ? 'Dossier' : _getFileType(b.name);
          comparison = aType.compareTo(bType);
          break;
        case FileColumn.dateCreated:
          comparison = (a.created ?? DateTime(1970))
              .compareTo(b.created ?? DateTime(1970));
          break;
        case FileColumn.dateAccessed:
          comparison = (a.accessed ?? DateTime(1970))
              .compareTo(b.accessed ?? DateTime(1970));
          break;
        case FileColumn.permissions:
          comparison = (a.mode ?? 0).compareTo(b.mode ?? 0);
          break;
        case FileColumn.tags:
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        default:
          comparison = 0;
      }

      // Toujours afficher les dossiers en premier
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;

      return _sortConfig!.order == SortOrder.ascending ? comparison : -comparison;
    });

    return sorted;
  }

  void _toggleSort(FileColumn column) {
    setState(() {
      if (_sortConfig?.column == column) {
        _sortConfig = _sortConfig!.toggle();
      } else {
        _sortConfig = SortConfig(column: column, order: SortOrder.ascending);
      }
    });
    _saveSortPreferences();
  }

  void _resizeColumn(int index, double delta) {
    setState(() {
      final column = _columns[index];
      final newWidth = (column.width + delta)
          .clamp(column.minWidth, column.maxWidth);
      _columns[index] = ColumnConfig(
        column: column.column,
        label: column.label,
        width: newWidth,
        minWidth: column.minWidth,
        maxWidth: column.maxWidth,
      );
    });
    _saveColumnPreferences();
  }

  void _showColumnSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ColumnSelectorDialog(
        visibleColumns: _columns,
        availableColumns: _availableColumns,
        onColumnsChanged: (newColumns) {
          setState(() {
            _columns = newColumns;
          });
          _saveColumnPreferences();
        },
      ),
    );
  }

  String _getFileType(String filename) {
    if (filename.contains('.')) {
      final ext = filename.split('.').last.toUpperCase();
      return 'Fichier $ext';
    }
    return 'Fichier';
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '—';
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} Go';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    if (dateDay == today) {
      return "Aujourd'hui $hour:$minute";
    } else if (dateDay == today.subtract(const Duration(days: 1))) {
      return 'Hier $hour:$minute';
    } else {
      return '$day/$month/$year $hour:$minute';
    }
  }

  String _formatPermissions(int? mode) {
    if (mode == null) return '—';
    final perms = mode & 0x1FF;
    String triplet(int shift) {
      final r = ((perms >> shift) & 0x4) != 0 ? 'r' : '-';
      final w = ((perms >> shift) & 0x2) != 0 ? 'w' : '-';
      final x = ((perms >> shift) & 0x1) != 0 ? 'x' : '-';
      return '$r$w$x';
    }
    return '${triplet(6)}${triplet(3)}${triplet(0)}';
  }

  String _getCellValue(FileEntry entry, FileColumn column) {
    switch (column) {
      case FileColumn.name:
        return entry.name;
      case FileColumn.size:
        return entry.isDirectory ? '—' : _formatSize(entry.size);
      case FileColumn.dateModified:
        return _formatDate(entry.lastModified);
      case FileColumn.kind:
        return entry.isDirectory ? 'Dossier' : _getFileType(entry.name);
      case FileColumn.dateCreated:
        return _formatDate(entry.created);
      case FileColumn.dateAccessed:
        return _formatDate(entry.accessed);
      case FileColumn.permissions:
        return _formatPermissions(entry.mode);
      case FileColumn.tags:
        return '—';
      default:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedEntries = _sortedEntries;
    final themeProvider = context.watch<ThemeProvider>();
    final isLight = themeProvider.isLight;

    // Calculer la largeur totale: checkbox (40) + colonnes + bouton sélecteur (40)
    final totalWidth = 40.0 + _columns.fold(0.0, (sum, col) => sum + col.width) + 40.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              maxWidth: totalWidth > constraints.maxWidth ? totalWidth : constraints.maxWidth,
            ),
            child: Column(
              children: [
                // Header
                _buildHeader(),
                // Rows
                Expanded(
                  child: ListView.builder(
                    controller: widget.scrollController,
                    itemCount: sortedEntries.length,
                    itemBuilder: (context, index) {
                      final entry = sortedEntries[index];
                      return _buildRow(entry, isLight);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Selection checkbox column
          SizedBox(
            width: 40,
            child: widget.selectionMode
                ? const Icon(
                    lucide.LucideIcons.check,
                    size: 16,
                    color: Colors.transparent,
                  )
                : null,
          ),
          // Data columns
          ..._columns.asMap().entries.map((entry) {
            final index = entry.key;
            final column = entry.value;
            return _buildHeaderCell(column, index);
          }),
          // Column selector button
          SizedBox(
            width: 40,
            child: IconButton(
              icon: Icon(
                lucide.LucideIcons.layoutGrid,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              tooltip: 'Gérer les colonnes',
              onPressed: () => _showColumnSelector(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(ColumnConfig column, int index) {
    final isSorted = _sortConfig?.column == column.column;
    final isAscending = _sortConfig?.order == SortOrder.ascending;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      width: column.width,
      child: Stack(
        children: [
          // Header label with sort indicator
          InkWell(
            onTap: () => _toggleSort(column.column),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      column.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: onSurface.withValues(alpha: 0.72),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSorted)
                    Icon(
                      isAscending
                          ? lucide.LucideIcons.arrowUp
                          : lucide.LucideIcons.arrowDown,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
          // Resize handle
          if (index < _columns.length - 1)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    _resizeColumn(index, details.delta.dx);
                  },
                  child: Container(
                    width: 8,
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(FileEntry entry, bool isLight) {
    final isSelected = widget.isSelected(entry);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isHovering = _hoveredRows.contains(entry.path);
    final hoverColor = isLight
        ? Colors.black.withValues(alpha: 0.035)
        : Colors.white.withValues(alpha: 0.05);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredRows.add(entry.path)),
      onExit: (_) => setState(() => _hoveredRows.remove(entry.path)),
      child: InkWell(
        onTap: () => widget.onEntryTap(entry),
        onDoubleTap: () => widget.onEntryDoubleTap(entry),
        onSecondaryTapDown: (details) {
          widget.onEntrySecondaryTap(entry, details.globalPosition);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                : (isHovering ? hoverColor : Colors.transparent),
            border: Border(
              bottom: BorderSide(
                color: onSurface.withValues(alpha: 0.04),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Selection checkbox
              SizedBox(
                width: 40,
                child: widget.selectionMode && isSelected
                    ? Icon(
                        lucide.LucideIcons.check,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
              // Data cells
              ..._columns.map((column) => _buildCell(entry, column, isLight)),
              // Spacer for column selector button
              const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(FileEntry entry, ColumnConfig column, bool isLight) {
    return SizedBox(
      width: column.width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          _getCellValue(entry, column.column),
          style: TextStyle(
            fontSize: 13,
            color: isLight ? Colors.black87 : Colors.white.withValues(alpha: 0.85),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Dialog pour sélectionner les colonnes visibles
class _ColumnSelectorDialog extends StatefulWidget {
  const _ColumnSelectorDialog({
    required this.visibleColumns,
    required this.availableColumns,
    required this.onColumnsChanged,
  });

  final List<ColumnConfig> visibleColumns;
  final List<ColumnConfig> availableColumns;
  final void Function(List<ColumnConfig>) onColumnsChanged;

  @override
  State<_ColumnSelectorDialog> createState() => _ColumnSelectorDialogState();
}

class _ColumnSelectorDialogState extends State<_ColumnSelectorDialog> {
  late List<ColumnConfig> _selected;
  late List<ColumnConfig> _available;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.visibleColumns);
    _available = widget.availableColumns
        .where((col) => !_selected.any((s) => s.column == col.column))
        .toList();
  }

  void _toggleColumn(ColumnConfig column) {
    setState(() {
      final isSelected = _selected.any((c) => c.column == column.column);
      if (isSelected) {
        // Ne pas permettre de retirer la colonne Nom
        if (column.column == FileColumn.name) return;
        _selected.removeWhere((c) => c.column == column.column);
        _available.add(column);
      } else {
        _selected.add(column);
        _available.removeWhere((c) => c.column == column.column);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allColumns = [..._selected, ..._available];
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final onSurface = theme.colorScheme.onSurface;
    final bg = isLight
        ? theme.colorScheme.surface.withValues(alpha: 0.75)
        : theme.colorScheme.surface.withValues(alpha: 0.9);
    final border = onSurface.withValues(alpha: 0.08);
    final titleColor = onSurface.withValues(alpha: 0.9);
    final subtitleColor = onSurface.withValues(alpha: 0.6);

    return Dialog(
      backgroundColor: Colors.transparent,
      alignment: Alignment.center,
      insetPadding: EdgeInsets.symmetric(
        horizontal: Platform.isMacOS ? 80 : 40,
        vertical: 40,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      lucide.LucideIcons.layoutGrid,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Gérer les colonnes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Sélectionnez les colonnes à afficher',
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 16),
                ...allColumns.map((column) {
                  final isSelected = _selected.any((c) => c.column == column.column);
                  final isName = column.column == FileColumn.name;

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: isName ? null : (_) => _toggleColumn(column),
                    title: Text(
                      column.label,
                      style: TextStyle(
                        color: isName
                            ? onSurface.withValues(alpha: 0.55)
                            : onSurface.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    subtitle: isName
                        ? Text(
                            'Obligatoire',
                            style: TextStyle(
                              fontSize: 11,
                              color: onSurface.withValues(alpha: 0.5),
                            ),
                          )
                        : null,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: theme.colorScheme.primary,
                    checkColor: isLight ? Colors.white : Colors.black,
                  );
                }),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: onSurface.withValues(alpha: 0.7),
                      ),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        widget.onColumnsChanged(_selected);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Appliquer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
