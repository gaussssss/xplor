import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/explorer/presentation/pages/explorer_page.dart';

class XplorApp extends StatelessWidget {
  const XplorApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrapper l'app avec ChangeNotifierProvider pour le ThemeProvider
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const _XplorAppContent(),
    );
  }
}

/// Contenu de l'app qui écoute les changements de thème
class _XplorAppContent extends StatelessWidget {
  const _XplorAppContent();

  @override
  Widget build(BuildContext context) {
    // Écouter les changements du ThemeProvider
    final themeProvider = context.watch<ThemeProvider>();

    // Afficher un loader pendant le chargement de la palette sauvegardée
    if (themeProvider.isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF0A0A0A),
          body: Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return ShadApp(
      title: 'Xplor',
      debugShowCheckedModeBanner: false,
      theme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(),
      ),
      // Utiliser le thème avec palette ou le thème classique selon feature flag
      materialThemeBuilder: (context, _) => AppTheme.darkWithPalette(themeProvider),
      home: const ExplorerPage(),
    );
  }
}
