import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/theme_provider.dart';

/// Page d'onboarding avec plusieurs étapes
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    this.onComplete,
  });

  final VoidCallback? onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingStep> _steps = const [
    OnboardingStep(
      icon: lucide.LucideIcons.folder,
      title: 'Bienvenue dans Xplor',
      description: 'Un explorateur de fichiers moderne avec une interface élégante et intuitive.',
    ),
    OnboardingStep(
      icon: lucide.LucideIcons.layoutGrid,
      title: 'Vue grille ou liste',
      description: 'Basculez facilement entre la vue grille et la vue liste pour naviguer dans vos fichiers.',
    ),
    OnboardingStep(
      icon: lucide.LucideIcons.move,
      title: 'Glisser-déposer',
      description: 'Déplacez vos fichiers et dossiers par simple glisser-déposer depuis le Finder.',
    ),
    OnboardingStep(
      icon: lucide.LucideIcons.search,
      title: 'Recherche rapide',
      description: 'Trouvez rapidement vos fichiers grâce à la barre de recherche intégrée.',
    ),
    OnboardingStep(
      icon: lucide.LucideIcons.palette,
      title: 'Personnalisez votre expérience',
      description: 'Choisissez parmi plusieurs thèmes et palettes de couleurs pour adapter Xplor à vos goûts.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      // Appeler le callback pour notifier le parent
      widget.onComplete?.call();
    }
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final isLight = themeProvider.isLight;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Contenu des pages
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                return _buildPage(context, _steps[index], isLight);
              },
            ),

            // Indicateurs de page
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (index) => _buildPageIndicator(context, index == _currentPage),
                ),
              ),
            ),

            // Boutons de navigation
            Positioned(
              bottom: 40,
              left: 40,
              right: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bouton précédent
                  if (_currentPage > 0)
                    TextButton.icon(
                      onPressed: _previousPage,
                      icon: const Icon(lucide.LucideIcons.chevronLeft),
                      label: const Text('Précédent'),
                    )
                  else
                    const SizedBox(width: 120),

                  // Bouton passer
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: const Text('Passer'),
                  ),

                  // Bouton suivant/terminer
                  FilledButton.icon(
                    onPressed: _nextPage,
                    icon: Icon(
                      _currentPage == _steps.length - 1
                          ? lucide.LucideIcons.check
                          : lucide.LucideIcons.chevronRight,
                    ),
                    label: Text(
                      _currentPage == _steps.length - 1 ? 'Terminer' : 'Suivant',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, OnboardingStep step, bool isLight) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Icône
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              step.icon,
              size: 60,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 48),

          // Titre
          Text(
            step.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Description
          Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Text(
              step.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(BuildContext context, bool isActive) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Modèle d'une étape d'onboarding
class OnboardingStep {
  const OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
