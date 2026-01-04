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
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  final List<OnboardingStep> _steps = const [
    OnboardingStep(
      backgroundImage: 0,
      icon: lucide.LucideIcons.sparkles,
      title: 'Xplor',
      subtitle: 'L\'explorateur réinventé',
      pitch: 'Finder est lent, limité et daté.',
      description: 'Xplor offre une interface moderne, rapide et élégante pour gérer vos fichiers avec style.',
    ),
    OnboardingStep(
      backgroundImage: 1,
      icon: lucide.LucideIcons.layoutGrid,
      title: 'Adaptable',
      subtitle: 'Grille · Liste · Votre choix',
      pitch: 'Changez de vue en un clic.',
      description: 'Passez de la grille visuelle à la liste détaillée selon vos besoins du moment.',
    ),
    OnboardingStep(
      backgroundImage: 2,
      icon: lucide.LucideIcons.move,
      title: 'Intuitif',
      subtitle: 'Glissez · Déposez · Terminé',
      pitch: 'Organisez sans effort.',
      description: 'Drag & drop depuis Finder avec gestion intelligente des doublons et des conflits.',
    ),
    OnboardingStep(
      backgroundImage: 3,
      icon: lucide.LucideIcons.zap,
      title: 'Rapide',
      subtitle: 'Recherche instantanée',
      pitch: 'Trouvez tout, immédiatement.',
      description: 'Moteur de recherche ultra-performant avec filtres avancés et résultats en temps réel.',
    ),
    OnboardingStep(
      backgroundImage: 4,
      icon: lucide.LucideIcons.palette,
      title: 'Personnel',
      subtitle: 'Thèmes · Couleurs · Style',
      pitch: 'Faites-le vôtre.',
      description: 'Palettes de couleurs raffinées, mode clair/sombre, personnalisation complète.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
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
      _scaleController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubicEmphasized,
      );
      _scaleController.forward();
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _scaleController.reset();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubicEmphasized,
      );
      _scaleController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Background avec image et dégradé
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1000),
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
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.3),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                    stops: const [0.0, 0.5, 1.0],
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
              _scaleController.reset();
              _scaleController.forward();
            },
            itemCount: _steps.length,
            itemBuilder: (context, index) {
              return _buildPage(context, _steps[index], theme, themeProvider);
            },
          ),

          // Bouton skip
          Positioned(
            top: 24,
            right: 24,
            child: _buildSkipButton(theme),
          ),

          // Contrôles en bas
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: _buildControls(theme, themeProvider),
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
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // Icône compacte avec glow
            ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(
                  parent: _scaleController,
                  curve: Curves.easeOutBack,
                ),
              ),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.3),
                      theme.colorScheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  step.icon,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Titre + Subtitle compact
            FadeTransition(
              opacity: _fadeController,
              child: Column(
                children: [
                  Text(
                    step.title,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.5,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.subtitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Card glassmorphique compacte
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.pitch,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        step.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(),
            const SizedBox(height: 120), // Espace pour les contrôles
          ],
        ),
      ),
    );
  }

  Widget _buildControls(ThemeData theme, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          // Bouton précédent (si pas première page)
          if (_currentPage > 0)
            _buildChevronButton(
              icon: lucide.LucideIcons.chevronLeft,
              onTap: _previousPage,
              theme: theme,
            )
          else
            const SizedBox(width: 48),

          const SizedBox(width: 16),

          // Indicateurs au centre
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  _steps.length,
                  (index) => _buildDot(index == _currentPage, theme),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Bouton suivant/terminer
          _buildChevronButton(
            icon: _currentPage == _steps.length - 1
                ? lucide.LucideIcons.check
                : lucide.LucideIcons.chevronRight,
            onTap: _nextPage,
            theme: theme,
            isPrimary: true,
            label: _currentPage == _steps.length - 1 ? 'Commencer' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildChevronButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isPrimary = false,
    String? label,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 48,
              padding: EdgeInsets.symmetric(
                horizontal: label != null ? 20 : 16,
              ),
              decoration: BoxDecoration(
                color: isPrimary
                    ? theme.colorScheme.primary
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isPrimary
                      ? theme.colorScheme.primary
                      : Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null) ...[
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    icon,
                    size: 20,
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

  Widget _buildDot(bool isActive, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary
            : Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildSkipButton(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _completeOnboarding,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Passer',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    lucide.LucideIcons.arrowRight,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.7),
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
