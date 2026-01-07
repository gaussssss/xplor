import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';


enum MiniExplorerPickerMode { file, directory }

class MiniExplorerDialog extends StatefulWidget {
  const MiniExplorerDialog({
    super.key,
    required this.title,
    required this.mode,
    this.initialPath,
    this.allowedExtensions,
    this.confirmLabel,
    this.showHidden = false,
    this.showFiles,
  });

  final String title;
  final MiniExplorerPickerMode mode;
  final String? initialPath;
  final List<String>? allowedExtensions;
  final String? confirmLabel;
  final bool showHidden;
  final bool? showFiles;

  @override
  State<MiniExplorerDialog> createState() => _MiniExplorerDialogState();
}

class _MiniExplorerDialogState extends State<MiniExplorerDialog> {
  static const String _lastPathKey = 'mini_explorer_last_path';
  static const String _lastSelectionKey = 'mini_explorer_last_selection';

  late String _currentPath;
  String? _selectedPath;
  bool _isLoading = true;
  String? _error;
  List<_ExplorerEntry> _entries = const [];
  final List<String> _backStack = [];
  final List<String> _forwardStack = [];
  late TextEditingController _pathController;

  @override
  void initState() {
    super.initState();
    _currentPath = _homeDirectory();
    _pathController = TextEditingController();
    _initialize();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final lastPath = await _loadLastPath();
    final lastSelection = await _loadLastSelection();
    final resolved = _resolveInitialPath(
      widget.initialPath,
      fallback: lastPath,
      lastSelection: lastSelection,
      allowFileSelection: widget.mode == MiniExplorerPickerMode.file,
    );
    if (!mounted) return;
    _currentPath = resolved.path;
    _selectedPath = resolved.selectedPath;
    _pathController.text = _currentPath;
    await _loadDirectory(
      _currentPath,
      pushHistory: false,
      selectedPath: _selectedPath,
    );
  }

  _InitialPath _resolveInitialPath(
    String? initial, {
    required String? fallback,
    required String? lastSelection,
    required bool allowFileSelection,
  }) {
    final candidates = [
      initial,
      lastSelection,
      fallback,
      _homeDirectory(),
    ];
    for (final candidate in candidates) {
      if (candidate == null || candidate.trim().isEmpty) {
        continue;
      }
      final normalized = p.normalize(candidate.trim());
      final type = FileSystemEntity.typeSync(normalized);
      if (type == FileSystemEntityType.directory) {
        return _InitialPath(path: normalized);
      }
      if (type == FileSystemEntityType.file) {
        return _InitialPath(
          path: Directory(normalized).parent.path,
          selectedPath: allowFileSelection ? normalized : null,
        );
      }
    }
    return _InitialPath(path: _homeDirectory());
  }

  String _homeDirectory() {
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'] ?? Directory.current.path;
    }
    return Platform.environment['HOME'] ?? Directory.current.path;
  }

  Future<void> _loadDirectory(
    String path, {
    bool pushHistory = true,
    String? selectedPath,
  }) async {
    final target = p.normalize(path);
    if (pushHistory && target == _currentPath) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final directory = Directory(target);
      if (!await directory.exists()) {
        throw FileSystemException('Dossier introuvable', target);
      }

      final showFiles = widget.showFiles ?? widget.mode == MiniExplorerPickerMode.file;
      final allowed = widget.allowedExtensions
          ?.map((ext) => ext.toLowerCase().replaceAll('.', ''))
          .toSet();
      final entries = <_ExplorerEntry>[];

      await for (final entity
          in directory.list(recursive: false, followLinks: false)) {
        final name = p.basename(entity.path);
        if (!widget.showHidden && name.startsWith('.')) {
          continue;
        }
        final isDir = entity is Directory;
        if (!showFiles && !isDir) {
          continue;
        }
        if (!isDir && allowed != null && allowed.isNotEmpty) {
          final ext = p.extension(name).toLowerCase().replaceAll('.', '');
          if (!allowed.contains(ext)) {
            continue;
          }
        }
        entries.add(_ExplorerEntry(
          name: name,
          path: entity.path,
          isDirectory: isDir,
        ));
      }

      entries.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      if (pushHistory) {
        _backStack.add(_currentPath);
        _forwardStack.clear();
      }

      await _saveLastPath(target);
      setState(() {
        _currentPath = target;
        _pathController.text = target;
        _selectedPath = _isSelectionInDirectory(selectedPath, target)
            ? selectedPath
            : null;
        _entries = entries;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error is FileSystemException
            ? (error.message.isNotEmpty
                ? error.message
                : 'Acces au dossier refuse.')
            : 'Impossible de charger ce dossier.';
        _isLoading = false;
      });
    }
  }

  void _navigateUp() {
    final parent = Directory(_currentPath).parent.path;
    if (parent == _currentPath) return;
    _loadDirectory(parent);
  }

  void _goBack() {
    if (_backStack.isEmpty) return;
    final target = _backStack.removeLast();
    _forwardStack.add(_currentPath);
    _loadDirectory(target, pushHistory: false);
  }

  void _goForward() {
    if (_forwardStack.isEmpty) return;
    final target = _forwardStack.removeLast();
    _backStack.add(_currentPath);
    _loadDirectory(target, pushHistory: false);
  }

  void _onEntryTap(_ExplorerEntry entry) {
    final matchesMode = widget.mode == MiniExplorerPickerMode.directory
        ? entry.isDirectory
        : !entry.isDirectory;
    setState(() {
      _selectedPath = matchesMode ? entry.path : null;
    });
    if (matchesMode) {
      _saveLastSelection(entry.path);
    }
  }

  void _onEntryDoubleTap(_ExplorerEntry entry) {
    if (entry.isDirectory) {
      _loadDirectory(entry.path);
      return;
    }
    if (widget.mode == MiniExplorerPickerMode.file) {
      _saveLastSelection(entry.path);
      Navigator.of(context).pop(entry.path);
    }
  }

  void _confirmSelection() {
    if (widget.mode == MiniExplorerPickerMode.directory) {
      final selection = _selectedPath ?? _currentPath;
      _saveLastSelection(selection);
      Navigator.of(context).pop(selection);
      return;
    }
    if (_selectedPath == null) return;
    _saveLastSelection(_selectedPath!);
    Navigator.of(context).pop(_selectedPath);
  }

  bool _isSelectionInDirectory(String? selection, String directory) {
    if (selection == null || selection.trim().isEmpty) return false;
    final normalizedSelection = p.normalize(selection);
    return p.dirname(normalizedSelection) == directory;
  }

  Future<String?> _loadLastPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastPathKey);
  }

  Future<String?> _loadLastSelection() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSelectionKey);
  }

  Future<void> _saveLastPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPathKey, path);
  }

  Future<void> _saveLastSelection(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSelectionKey, path);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bgColor = isLight
        ? Colors.white.withValues(alpha: 0.98)
        : Colors.black.withValues(alpha: 0.8);
    final borderColor = colorScheme.onSurface.withValues(alpha: 0.08);
    final selectionColor = colorScheme.primary.withValues(alpha: 0.12);
    final hoverColor = colorScheme.onSurface.withValues(alpha: 0.06);
    final dividerColor = colorScheme.onSurface.withValues(alpha: 0.08);
    final confirmText =
        widget.confirmLabel ?? (widget.mode == MiniExplorerPickerMode.file
            ? 'Choisir'
            : 'Choisir ce dossier');

    final isConfirmEnabled = widget.mode == MiniExplorerPickerMode.directory
        ? !_isLoading
        : !_isLoading && _selectedPath != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: Platform.isMacOS ? 80 : 40,
        vertical: 40,
      ),
      child: Container(
        width: 720,
        height: 520,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              blurRadius: 24,
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(LucideIcons.folderOpen, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x, size: 18),
                    tooltip: 'Fermer',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _backStack.isEmpty ? null : _goBack,
                    icon: const Icon(LucideIcons.arrowLeft, size: 16),
                    tooltip: 'Precedent',
                  ),
                  IconButton(
                    onPressed: _forwardStack.isEmpty ? null : _goForward,
                    icon: const Icon(LucideIcons.arrowRight, size: 16),
                    tooltip: 'Suivant',
                  ),
                  IconButton(
                    onPressed: _navigateUp,
                    icon: const Icon(LucideIcons.arrowUp, size: 16),
                    tooltip: 'Dossier parent',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _pathController,
                      onSubmitted: (value) => _loadDirectory(value),
                      style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        hintText: 'Chemin du dossier',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        filled: true,
                        fillColor: colorScheme.surface.withValues(alpha: 0.6),
                        suffixIcon: IconButton(
                          onPressed: () => _loadDirectory(_pathController.text),
                          icon: const Icon(LucideIcons.arrowRight, size: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: dividerColor),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: colorScheme.error),
                          ),
                        )
                      : _entries.isEmpty
                          ? Center(
                              child: Text(
                                'Dossier vide',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          : ListView.separated(
                              itemCount: _entries.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: dividerColor,
                              ),
                              itemBuilder: (context, index) {
                                final entry = _entries[index];
                                final isSelected = _selectedPath == entry.path;
                                final icon = entry.isDirectory
                                    ? LucideIcons.folder
                                    : LucideIcons.file;
                                final matchesMode = widget.mode ==
                                        MiniExplorerPickerMode.directory
                                    ? entry.isDirectory
                                    : !entry.isDirectory;
                                return InkWell(
                                  onTap: () => _onEntryTap(entry),
                                  onDoubleTap: () => _onEntryDoubleTap(entry),
                                  hoverColor: hoverColor,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 120),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected ? selectionColor : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          icon,
                                          size: 18,
                                          color: entry.isDirectory
                                              ? colorScheme.primary
                                              : colorScheme.onSurface
                                                  .withValues(alpha: 0.8),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            entry.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: matchesMode
                                                      ? FontWeight.w500
                                                      : FontWeight.w400,
                                                ),
                                          ),
                                        ),
                                        if (!matchesMode)
                                          Text(
                                            widget.mode ==
                                                    MiniExplorerPickerMode.file
                                                ? 'Dossier'
                                                : 'Fichier',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.5),
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
            Divider(height: 1, color: dividerColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (widget.mode == MiniExplorerPickerMode.directory)
                    Expanded(
                      child: Text(
                        _currentPath,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                      ),
                    )
                  else
                    Expanded(
                      child: Text(
                        _selectedPath ?? 'Aucun fichier selectionne',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: _selectedPath == null
                                  ? colorScheme.onSurface
                                      .withValues(alpha: 0.5)
                                  : colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                            ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isConfirmEnabled ? _confirmSelection : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(confirmText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplorerEntry {
  const _ExplorerEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
  });

  final String name;
  final String path;
  final bool isDirectory;
}

class _InitialPath {
  const _InitialPath({required this.path, this.selectedPath});

  final String path;
  final String? selectedPath;
}
