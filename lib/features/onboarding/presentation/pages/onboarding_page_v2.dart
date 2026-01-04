import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/assets.dart';
import '../../../../core/providers/theme_provider.dart';

/// Page d'onboarding magnifique avec animations et backgrounds
class OnboardingPageV2 extends StatefulWidget {
  const OnboardingPageV2({
    super.key,
    this.onComplete,
  });

  final VoidCallback? onComplete;

  @override
  State<OnboardingPageV2> createState() => _OnboardingPageV2State();
}

class _OnboardingPageV2State extends State<OnboardingPageV2>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _contentController;
  late AnimationController _iconController;
  late AnimationController _glowController;

  final List<OnboardingStep> _steps = const [
    OnboardingStep(
      backgroundImage: 0,
      icon: lucide.LucideIcons.sparkles,
      title: 'Xplor',
      subtitle: 'L\'explorateur réinventé',
      pitch: 'Finder est lent, limité et daté',
      description: 'Xplor offre une interface moderne, rapide et élégante pour gérer vos fichiers avec style.',
    ),
    OnboardingStep(
      backgroundImage: 1,
      icon: lucide.LucideIcons.layoutGrid,
      title: 'Adaptable',
      subtitle: 'Grille • Liste • Votre choix',
      pitch: 'Changez de vue en un clic',
      description: 'Passez de la grille visuelle à la liste détaillée selon vos besoins.',
    ),
    OnboardingStep(
      backgroundImage: 2,
      icon: lucide.LucideIcons.move,
      title: 'Intuitif',
      subtitle: 'Glissez • Déposez • Terminé',
      pitch: 'Organisez sans effort',
      description: 'Drag & drop avec gestion intelligente des doublons et des conflits.',
    ),
    OnboardingStep(
      backgroundImage: 3,
      icon: lucide.LucideIcons.zap,
      title: 'Rapide',
      subtitle: 'Recherche instantanée',
      pitch: 'Trouvez tout, immédiatement',
      description: 'Moteur de recherche ultra-performant avec résultats en temps réel.',
    ),
    OnboardingStep(
      backgroundImage: 4,
      icon: lucide.LucideIcons.palette,
      title: 'Personnel',
      subtitle: 'Thèmes • Couleurs • Style',
      pitch: 'Faites-le vôtre',
      description: 'Palettes raffinées, mode clair/sombre, personnalisation complète.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentController.dispose();
    _iconController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      widget.onComplete?.call();
    }
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _contentController.reset();
      _iconController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubicEmphasized,
      );
      _contentController.forward();
      _iconController.forward();
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _contentController.reset();
      _iconController.reset();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubicEmphasized,
      );
      _contentController.forward();
      _iconController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Background avec image + overlay plus sombre
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1200),
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            child: Container(
              key: ValueKey(_currentPage),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    AppAssets.onboardingBackgrounds[_steps[_currentPage].backgroundImage],
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Contenu
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              _contentController.reset();
              _iconController.reset();
              _contentController.forward();
              _iconController.forward();
            },
            itemCount: _steps.length,
            itemBuilder: (context, index) {
              return _buildPage(context, _steps[index], theme, themeProvider);
            },
          ),

          // Bouton skip discret
          Positioned(
            top: 48,
            right: 48,
            child: _buildSkipButton(theme),
          ),

          // Contrôles centrés en bas
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: _buildControls(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    OnboardingStep step,
    ThemeData theme,
    ThemeProvider themeProvider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // Icône avec animation et glow pulsant
            ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(
                  parent: _iconController,
                  curve: Curves.elasticOut,
                ),
              ),
              child: FadeTransition(
                opacity: _iconController,
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.4 + (_glowController.value * 0.3),
                            ),
                            blurRadius: 60 + (_glowController.value * 40),
                            spreadRadius: 20 + (_glowController.value * 10),
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.25),
                          theme.colorScheme.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                    child: Icon(
                      step.icon,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Titre avec fade et slide
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _contentController,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(
                opacity: _contentController,
                child: Column(
                  children: [
                    Text(
                      step.title,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -2,
                        height: 1.0,
                        fontSize: 72,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      step.subtitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 56),

            // Card glassmorphique VRAIMENT visible
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _contentController,
                curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
              )),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _contentController,
                  curve: const Interval(0.2, 1.0),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 550),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              step.pitch,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                                fontSize: 24,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 2,
                              width: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary.withValues(alpha: 0.0),
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              step.description,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.7,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    final isLastPage = _currentPage == _steps.length - 1;

    return Column(
      children: [
        // Indicateurs de page
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _steps.length,
            (index) => _buildDot(index == _currentPage, theme),
          ),
        ),

        const SizedBox(height: 32),

        // Boutons de navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bouton précédent
              if (_currentPage > 0) ...[
                _buildNavButton(
                  icon: lucide.LucideIcons.chevronLeft,
                  onTap: _previousPage,
                  theme: theme,
                ),
                const SizedBox(width: 20),
              ],

              // Bouton suivant/commencer
              _buildMainButton(
                label: isLastPage ? 'Commencer l\'aventure' : 'Suivant',
                icon: isLastPage ? lucide.LucideIcons.rocket : lucide.LucideIcons.arrowRight,
                onTap: _nextPage,
                theme: theme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.4 + (_glowController.value * 0.2),
                        ),
                        blurRadius: 20 + (_glowController.value * 10),
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    icon,
                    size: 22,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot(bool isActive, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: isActive ? 40 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary
            : Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildSkipButton(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _completeOnboarding,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Passer',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    lucide.LucideIcons.arrowRight,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modèle d'une étape d'onboarding
class OnboardingStep {
  const OnboardingStep({
    required this.backgroundImage,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.pitch,
    required this.description,
  });

  final int backgroundImage;
  final IconData icon;
  final String title;
  final String subtitle;
  final String pitch;
  final String description;
}
