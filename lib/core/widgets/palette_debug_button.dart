import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/color_palettes.dart';

/// Widget de debug pour tester rapidement le changement de palettes
/// À utiliser temporairement pendant le développement
/// TODO: Remplacer par le PaletteSelector en Phase 6
class PaletteDebugButton extends StatelessWidget {
  const PaletteDebugButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return PopupMenuButton<ColorPalette>(
      icon: Icon(
        Icons.palette,
        color: themeProvider.colors.primary,
      ),
      tooltip: 'Changer de palette (Debug)',
      onSelected: (palette) {
        themeProvider.setPalette(palette);
      },
      itemBuilder: (context) => ColorPalette.values.map((palette) {
        final isSelected = palette == themeProvider.currentPalette;
        return PopupMenuItem<ColorPalette>(
          value: palette,
          child: Row(
            children: [
              Text(
                palette.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      palette.displayName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? themeProvider.colors.primary : null,
                      ),
                    ),
                    Text(
                      palette.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check,
                  color: themeProvider.colors.primary,
                  size: 20,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
