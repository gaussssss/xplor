part of '../explorer_page.dart';

class _DuplicateDialog extends StatefulWidget {
  const _DuplicateDialog({
    required this.duplicates,
    required this.sourcePathMap,
  });

  final List<String> duplicates;
  final Map<String, String> sourcePathMap;

  @override
  State<_DuplicateDialog> createState() => _DuplicateDialogState();
}

class _DuplicateDialogState extends State<_DuplicateDialog> {
  late final Map<String, TextEditingController> _nameControllers;
  late final Map<String, DuplicateActionType?> _selectedActions;
  bool _applyToAll = false;
  DuplicateActionType? _batchAction;

  @override
  void initState() {
    super.initState();
    _nameControllers = {};
    _selectedActions = {};

    for (final fileName in widget.duplicates) {
      _nameControllers[fileName] = TextEditingController(text: _generateDuplicateName(fileName));
      _selectedActions[fileName] = null;
    }
  }

  @override
  void dispose() {
    for (final controller in _nameControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _generateDuplicateName(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1) {
      return '$fileName copie';
    }
    final name = fileName.substring(0, lastDot);
    final ext = fileName.substring(lastDot);
    return '$name copie$ext';
  }

  void _handleConfirm() {
    final actions = <String, DuplicateAction>{};

    if (_applyToAll && _batchAction != null) {
      // Mode batch: appliquer la même action à tous
      for (final fileName in widget.duplicates) {
        if (_batchAction == DuplicateActionType.duplicate) {
          actions[fileName] = DuplicateAction(
            type: _batchAction!,
            newName: _nameControllers[fileName]!.text,
          );
        } else {
          actions[fileName] = DuplicateAction(type: _batchAction!);
        }
      }
    } else {
      // Mode individuel: utiliser les actions spécifiques de chaque fichier
      for (final fileName in widget.duplicates) {
        final actionType = _selectedActions[fileName];
        if (actionType != null) {
          if (actionType == DuplicateActionType.duplicate) {
            actions[fileName] = DuplicateAction(
              type: actionType,
              newName: _nameControllers[fileName]!.text,
            );
          } else {
            actions[fileName] = DuplicateAction(type: actionType);
          }
        } else {
          // Aucune action sélectionnée = skip par défaut
          actions[fileName] = const DuplicateAction(type: DuplicateActionType.skip);
        }
      }
    }

    Navigator.pop(context, actions);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = context.read<ThemeProvider>();
    final isLight = themeProvider.isLight;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550, maxHeight: 700),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  children: [
                    Icon(
                      lucide.LucideIcons.alertTriangle,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Fichiers existants',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  '${widget.duplicates.length} fichier(s) existent déjà. Choisissez une action:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // Option "Appliquer à tous"
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isLight ? Colors.black : Colors.white).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _applyToAll,
                            onChanged: (value) {
                              setState(() {
                                _applyToAll = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              'Appliquer la même action à tous les fichiers',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_applyToAll) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const SizedBox(width: 40),
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Remplacer'),
                                    selected: _batchAction == DuplicateActionType.replace,
                                    onSelected: (selected) {
                                      setState(() {
                                        _batchAction = selected ? DuplicateActionType.replace : null;
                                      });
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Dupliquer (conserver les deux)'),
                                    selected: _batchAction == DuplicateActionType.duplicate,
                                    onSelected: (selected) {
                                      setState(() {
                                        _batchAction = selected ? DuplicateActionType.duplicate : null;
                                      });
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Garder la version actuelle'),
                                    selected: _batchAction == DuplicateActionType.skip,
                                    onSelected: (selected) {
                                      setState(() {
                                        _batchAction = selected ? DuplicateActionType.skip : null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Liste des fichiers
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: (isLight ? Colors.black : Colors.white).withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.onSurface.withValues(alpha: 0.1),
                      ),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.duplicates.length,
                      itemBuilder: (context, index) {
                        final fileName = widget.duplicates[index];
                        final selectedAction = _selectedActions[fileName];

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: index < widget.duplicates.length - 1
                                  ? BorderSide(
                                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                                    )
                                  : BorderSide.none,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nom du fichier
                              Row(
                                children: [
                                  Icon(
                                    lucide.LucideIcons.file,
                                    size: 16,
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      fileName,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              if (!_applyToAll) ...[
                                const SizedBox(height: 8),
                                // Actions individuelles
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    ChoiceChip(
                                      label: const Text('Remplacer'),
                                      selected: selectedAction == DuplicateActionType.replace,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedActions[fileName] = selected
                                              ? DuplicateActionType.replace
                                              : null;
                                        });
                                      },
                                    ),
                                    ChoiceChip(
                                      label: const Text('Dupliquer (conserver les deux)'),
                                      selected: selectedAction == DuplicateActionType.duplicate,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedActions[fileName] = selected
                                              ? DuplicateActionType.duplicate
                                              : null;
                                        });
                                      },
                                    ),
                                    ChoiceChip(
                                      label: const Text('Garder la version actuelle'),
                                      selected: selectedAction == DuplicateActionType.skip,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedActions[fileName] = selected
                                              ? DuplicateActionType.skip
                                              : null;
                                        });
                                      },
                                    ),
                                  ],
                                ),

                                // Champ de renommage si "Dupliquer" est sélectionné
                                if (selectedAction == DuplicateActionType.duplicate) ...[
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _nameControllers[fileName],
                                    decoration: InputDecoration(
                                      labelText: 'Nouveau nom',
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      isDense: true,
                                    ),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Boutons d'action
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _handleConfirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                      ),
                      child: const Text('Confirmer'),
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
