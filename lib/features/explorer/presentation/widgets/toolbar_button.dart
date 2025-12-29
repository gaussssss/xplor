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
                ? colorScheme.primary.withOpacity(0.12)
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: isActive ? colorScheme.primary : Colors.white.withOpacity(0.9),
            size: 20,
          ),
        ),
      ),
    );
  }
}
