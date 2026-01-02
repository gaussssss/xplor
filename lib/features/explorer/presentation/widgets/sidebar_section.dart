import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

/// Section de sidebar minimaliste et épurée
class SidebarSection extends StatelessWidget {
  const SidebarSection({
    super.key,
    required this.title,
    required this.items,
    this.compact = false,
  });

  final String title;
  final List<SidebarItem> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header ultra-simple sans décorations
        Padding(
          padding: EdgeInsets.only(
            bottom: DesignTokens.spacingXS,
            left: DesignTokens.spacingMD,
            top: DesignTokens.spacingMD,
          ),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                          alpha: isLight ? 0.7 : 0.4,
                        ),
                  ),
            ),
          ),
        ...items.map((item) => _SidebarTile(item: item)),
      ],
    );
  }
}

class SidebarItem {
  const SidebarItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.trailing,
    this.isActive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isActive;
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({required this.item});

  final SidebarItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.primary;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isActive = item.isActive;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: DesignTokens.borderRadiusXS,
        child: Container(
          height: DesignTokens.sidebarTileHeight,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.paddingMD,
          ),
          decoration: BoxDecoration(
            // Seulement une subtle bar à gauche pour l'item actif
            border: isActive
                ? Border(
                    left: BorderSide(
                      color: activeColor,
                      width: 2,
                    ),
                  )
                : null,
            // Background ultra-subtle
            color: isActive
                ? colorScheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
            color: isActive
                ? activeColor
                : colorScheme.onSurface.withValues(alpha: isLight ? 0.85 : 0.7),
                size: DesignTokens.iconSizeSmall,
              ),
              SizedBox(width: DesignTokens.spacingMD),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                        fontSize: 13,
                        letterSpacing: 0,
                        color: isActive
                            ? colorScheme.onSurface.withValues(alpha: 0.95)
                            : colorScheme.onSurface.withValues(
                                alpha: isLight ? 0.9 : 0.75,
                              ),
                      ),
                ),
              ),
              if (item.trailing != null) item.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
