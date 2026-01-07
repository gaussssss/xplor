part of '../explorer_page.dart';

class _MenuItem {
  const _MenuItem(this.value, this.label);
  final String value;
  final String label;
  
  bool get enabled => true;
}

class _ContextMenuEntry {
  const _ContextMenuEntry({
    required this.id,
    required this.label,
    this.icon,
    this.enabled = true,
    this.destructive = false,
    this.shortcut,
    this.children = const [],
    this.isSeparator = false,
  });

  const _ContextMenuEntry.separator()
      : id = '',
        label = '',
        icon = null,
        enabled = false,
        destructive = false,
        shortcut = null,
        children = const [],
        isSeparator = true;

  final String id;
  final String label;
  final IconData? icon;
  final bool enabled;
  final bool destructive;
  final String? shortcut;
  final List<_ContextMenuEntry> children;
  final bool isSeparator;

  bool get hasChildren => children.isNotEmpty;
}

class _MenuLayer {
  const _MenuLayer({
    required this.items,
    required this.position,
    required this.level,
  });

  final List<_ContextMenuEntry> items;
  final Offset position;
  final int level;
}

class _ContextMenuOverlay extends StatefulWidget {
  const _ContextMenuOverlay({
    required this.position,
    required this.items,
  });

  final Offset position;
  final List<_ContextMenuEntry> items;

  static Future<String?> show({
    required BuildContext context,
    required Offset position,
    required List<_ContextMenuEntry> items,
  }) {
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'context_menu',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (context, _, __) {
        return _ContextMenuOverlay(position: position, items: items);
      },
      transitionBuilder: (context, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  @override
  State<_ContextMenuOverlay> createState() => _ContextMenuOverlayState();
}

class _ContextMenuOverlayState extends State<_ContextMenuOverlay> {
  static const double _menuWidth = 240;
  static const double _menuItemHeight = 36;
  static const double _separatorHeight = 10;
  static const EdgeInsets _menuPadding =
      EdgeInsets.symmetric(vertical: 6, horizontal: 6);

  late List<_MenuLayer> _layers;
  bool _initialized = false;
  final Map<int, int?> _hoveredIndexByLayer = {};

  @override
  void initState() {
    super.initState();
    _layers = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _layers = [
      _MenuLayer(
        items: widget.items,
        position: _clampPosition(widget.position, widget.items),
        level: 0,
      ),
    ];
  }

  Offset _clampPosition(Offset desired, List<_ContextMenuEntry> items) {
    final size = MediaQuery.of(context).size;
    final menuHeight = _menuHeight(items);
    var dx = desired.dx;
    var dy = desired.dy;
    if (dx + _menuWidth > size.width) {
      dx = size.width - _menuWidth - 8;
    }
    if (dy + menuHeight > size.height) {
      dy = size.height - menuHeight - 8;
    }
    if (dx < 8) dx = 8;
    if (dy < 8) dy = 8;
    return Offset(dx, dy);
  }

  Offset _submenuPosition(Rect itemRect, List<_ContextMenuEntry> items) {
    final size = MediaQuery.of(context).size;
    final menuHeight = _menuHeight(items);
    var dx = itemRect.right + 6;
    var dy = itemRect.top - 4;
    if (dx + _menuWidth > size.width) {
      dx = itemRect.left - _menuWidth - 6;
    }
    if (dy + menuHeight > size.height) {
      dy = size.height - menuHeight - 8;
    }
    if (dy < 8) dy = 8;
    if (dx < 8) dx = 8;
    return Offset(dx, dy);
  }

  double _menuHeight(List<_ContextMenuEntry> items) {
    var height = _menuPadding.vertical;
    for (final item in items) {
      height += item.isSeparator ? _separatorHeight : _menuItemHeight;
    }
    return height;
  }

  bool _isPointInsideMenus(Offset point) {
    for (final layer in _layers) {
      final rect = Rect.fromLTWH(
        layer.position.dx,
        layer.position.dy,
        _menuWidth,
        _menuHeight(layer.items),
      );
      if (rect.contains(point)) return true;
    }
    return false;
  }

  void _closeFromLevel(int level) {
    setState(() {
      _layers = _layers.where((layer) => layer.level <= level).toList();
      _hoveredIndexByLayer.removeWhere((key, _) => key > level);
    });
  }

  void _openSubmenu({
    required int level,
    required _ContextMenuEntry entry,
    required BuildContext itemContext,
  }) {
    if (!entry.hasChildren) {
      _closeFromLevel(level);
      return;
    }
    final renderBox = itemContext.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final position = renderBox.localToGlobal(Offset.zero);
    final rect = Rect.fromLTWH(
      position.dx,
      position.dy,
      renderBox.size.width,
      renderBox.size.height,
    );
    final nextLayer = _MenuLayer(
      items: entry.children,
      position: _submenuPosition(rect, entry.children),
      level: level + 1,
    );
    setState(() {
      _layers = [
        ..._layers.where((layer) => layer.level <= level),
        nextLayer,
      ];
    });
  }

  Widget _buildMenuLayer(_MenuLayer layer) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final menuBg = DesignTokens.selectionMenuBackground(brightness);
    final onSurface = theme.colorScheme.onSurface;
    final borderColor = onSurface.withValues(alpha: brightness == Brightness.light ? 0.12 : 0.22);

    return Positioned(
      left: layer.position.dx,
      top: layer.position.dy,
      child: MouseRegion(
        onExit: (_) {
          setState(() {
            _hoveredIndexByLayer[layer.level] = null;
          });
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: _menuWidth,
                padding: _menuPadding,
                decoration: BoxDecoration(
                  color: menuBg.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(layer.items.length, (index) {
                    final item = layer.items[index];
                    if (item.isSeparator) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Container(
                          height: 1,
                          color: onSurface.withValues(alpha: 0.1),
                        ),
                      );
                    }

                    final isHovered = _hoveredIndexByLayer[layer.level] == index;
                    final isEnabled = item.enabled;
                    final labelColor = item.destructive
                        ? theme.colorScheme.error
                        : onSurface.withValues(alpha: isEnabled ? 0.95 : 0.45);

                    return Builder(
                      builder: (itemContext) {
                        return MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              _hoveredIndexByLayer[layer.level] = index;
                            });
                            if (item.hasChildren) {
                              _openSubmenu(
                                level: layer.level,
                                entry: item,
                                itemContext: itemContext,
                              );
                            } else {
                              _closeFromLevel(layer.level);
                            }
                          },
                          child: InkWell(
                            onTap: isEnabled
                                ? () {
                                    if (item.hasChildren) {
                                      _openSubmenu(
                                        level: layer.level,
                                        entry: item,
                                        itemContext: itemContext,
                                      );
                                      return;
                                    }
                                    Navigator.of(context).pop(item.id);
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              height: _menuItemHeight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: isHovered
                                    ? onSurface.withValues(alpha: 0.08)
                                    : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  if (item.icon != null)
                                    Icon(
                                      item.icon,
                                      size: 16,
                                      color: labelColor,
                                    )
                                  else
                                    const SizedBox(width: 16),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: labelColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item.shortcut != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Text(
                                        item.shortcut!,
                                        style:
                                            theme.textTheme.labelSmall?.copyWith(
                                          color: onSurface.withValues(alpha: 0.55),
                                        ),
                                      ),
                                    ),
                                  if (item.hasChildren)
                                    Icon(
                                      lucide.LucideIcons.chevronRight,
                                      size: 16,
                                      color: onSurface.withValues(alpha: 0.7),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) {
          if (!_isPointInsideMenus(details.globalPosition)) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
          children: _layers.map(_buildMenuLayer).toList(),
        ),
      ),
    );
  }
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.entry});

  final FileEntry entry;

  @override
  Widget build(BuildContext context) {
    final icon = entry.isDirectory ? lucide.LucideIcons.folder : lucide.LucideIcons.file;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                entry.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
