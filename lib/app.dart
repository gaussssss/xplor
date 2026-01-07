import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/explorer/presentation/pages/explorer_page.dart';
import 'features/onboarding/data/onboarding_service.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';

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
class _XplorAppContent extends StatefulWidget {
  const _XplorAppContent();

  @override
  State<_XplorAppContent> createState() => _XplorAppContentState();
}

class _XplorAppContentState extends State<_XplorAppContent> {
  bool? _onboardingCompleted;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    if (kDebugMode) {
      if (mounted) {
        setState(() {
          _onboardingCompleted = false;
        });
      }
      return;
    }

    final completed = await OnboardingService.isOnboardingCompleted();
    if (mounted) {
      setState(() {
        _onboardingCompleted = completed;
      });
    }
  }

  void _onOnboardingComplete() {
    setState(() {
      _onboardingCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Écouter les changements du ThemeProvider
    final themeProvider = context.watch<ThemeProvider>();

    // Afficher un loader pendant le chargement de la palette sauvegardée ou de l'état onboarding
    if (themeProvider.isLoading || _onboardingCompleted == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF0A0A0A),
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    // Résoudre un bundle cohérent (Material + Shad) à partir de la palette courante
    final themeBundle = AppTheme.current(themeProvider);

    return ShadApp(
      title: 'Xplor',
      debugShowCheckedModeBanner: false,
      theme: themeBundle.shad,
      // Utiliser le thème avec palette ou le thème classique selon feature flag
      materialThemeBuilder: (context, _) => themeBundle.material,
      home: _onboardingCompleted!
          ? const ExplorerPage()
          : OnboardingPage(onComplete: _onOnboardingComplete),
      backgroundColor: themeBundle.background,
    );
  }
}
