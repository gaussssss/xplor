import 'package:flutter/material.dart';

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
      child: InkResponse(
        onTap: onPressed,
        radius: 28,
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? colorScheme.primary.withOpacity(0.18)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? colorScheme.primary.withOpacity(0.5)
                  : Colors.white10,
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: isActive ? colorScheme.primary : Colors.white70,
          ),
        ),
      ),
    );
  }
}
