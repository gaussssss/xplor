import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

/// Bouton compact pour la toolbar (36x36px - Windows 11 style)
class ToolbarButton extends StatelessWidget {
  const ToolbarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: DesignTokens.borderRadiusXS,
          child: Container(
            width: DesignTokens.toolbarButtonSize,
            height: DesignTokens.toolbarButtonSize,
            decoration: BoxDecoration(
              // Seulement un subtle background pour l'état actif
              color: isActive
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: DesignTokens.borderRadiusXS,
            ),
            child: Center(
              child: Icon(
                icon,
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.7),
                size: DesignTokens.iconSizeNormal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
