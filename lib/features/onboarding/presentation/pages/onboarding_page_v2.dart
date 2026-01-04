import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/constants/assets.dart';
import '../../data/onboarding_service.dart';

/// Onboarding avec glassmorphisme élégant et design épuré
class OnboardingPageV2 extends StatefulWidget {
  const OnboardingPageV2({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingPageV2> createState() => _OnboardingPageV2State();
}

class _OnboardingPageV2State extends State<OnboardingPageV2>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<OnboardingStep> _steps = const [
    OnboardingStep(
      title: 'Bienvenue sur Xplor',
      description:
          'Un explorateur de fichiers moderne, rapide et élégant pour macOS.',
      backgroundIndex: 0,
    ),
    OnboardingStep(
      title: 'Vue grille ou liste',
      description:
          'Basculez entre les vues pour trouver exactement ce que vous cherchez.',
      backgroundIndex: 1,
    ),
    OnboardingStep(
      title: 'Glissez-déposez',
      description:
          'Organisez vos fichiers en les déplaçant depuis le Finder. Gestion intelligente des doublons.',
      backgroundIndex: 2,
    ),
    OnboardingStep(
      title: 'Recherche puissante',
      description:
          'Trouvez n\'importe quel fichier instantanément grâce à la recherche intégrée.',
      backgroundIndex: 3,
    ),
    OnboardingStep(
      title: 'Personnalisez',
      description:
          'Choisissez parmi plusieurs thèmes et palettes de couleurs pour adapter Xplor à vos goûts.',
      backgroundIndex: 4,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await OnboardingService.setOnboardingCompleted(true);
    widget.onComplete();
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _animationController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      _animationController.forward();
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _animationController.reset();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background image plein écran
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1000),
              child: SizedBox.expand(
                child: Image.asset(
                  AppAssets.onboardingBackgrounds[_steps[_currentPage]
                      .backgroundIndex],
                  key: ValueKey(_currentPage),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),

          // Overlay gradient subtil
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),

          // Contenu centré
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(),

                    const SizedBox(height: 32),

                    // PageView avec contenu
                    SizedBox(
                      height: 260,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemCount: _steps.length,
                        itemBuilder: (context, index) {
                          return _buildPage(context, _steps[index], theme);
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Navigation avec indicateurs au centre
                    _buildNavigation(theme),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Opacity(
      opacity: 0.8,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            AppAssets.appLogo,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    OnboardingStep step,
    ThemeData theme,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 550),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 36,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.2),
                          Colors.white.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Titre
                        Text(
                          step.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontSize: 32,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 20),

                        // Description
                        Text(
                          step.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.7,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 17,
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
      ),
    );
  }

  Widget _buildNavigation(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Bouton précédent (placeholder pour garder l'alignement)
              _currentPage > 0
                  ? _buildNavButton(
                      theme: theme,
                      label: 'Préc.',
                      icon: Icons.chevron_left_rounded,
                      onPressed: _previousPage,
                      iconPosition: IconPosition.left,
                    )
                  : const SizedBox(width: 56, height: 44),

              const SizedBox(width: 14),

              // Indicateurs de page au centre
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (index) => _buildPageIndicator(theme, index == _currentPage),
                ),
              ),

              const SizedBox(width: 14),

              // Bouton suivant/commencer
              _buildNavButton(
                theme: theme,
                label: _currentPage == _steps.length - 1 ? 'Fini' : 'Suiv.',
                icon: _currentPage == _steps.length - 1
                    ? Icons.check_rounded
                    : Icons.chevron_right_rounded,
                onPressed: _nextPage,
                iconPosition: IconPosition.right,
                isPrimary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(ThemeData theme, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 6,
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary
            : Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildNavButton({
    required ThemeData theme,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required IconPosition iconPosition,
    bool isPrimary = false,
  }) {
    final Color borderColor = isPrimary
        ? theme.colorScheme.primary.withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.22);

    final Color backgroundColor = isPrimary
        ? theme.colorScheme.primary.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          constraints: const BoxConstraints(minWidth: 56, minHeight: 44),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (iconPosition == IconPosition.left) ...[
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              if (iconPosition == IconPosition.right) ...[
                const SizedBox(width: 4),
                Icon(icon, color: Colors.white, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum IconPosition { left, right }

/// Modèle d'une étape d'onboarding
class OnboardingStep {
  const OnboardingStep({
    required this.title,
    required this.description,
    required this.backgroundIndex,
  });

  final String title;
  final String description;
  final int backgroundIndex;
}
