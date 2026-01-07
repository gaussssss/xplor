import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/mini_explorer_dialog.dart';
import '../../data/onboarding_service.dart';

enum OnboardingStepKind { standard, access }

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

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _introController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slideUp;

  int _currentPage = 0;
  String? _accessPath;
  bool _isRequestingAccess = false;

  static const List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Bienvenue dans Xplor',
      subtitle: 'Un explorateur qui se sent vivant',
      description:
          "Xplor mélange élégance, vitesse et clarté pour transformer la navigation en expérience fluide.",
      icon: lucide.LucideIcons.sparkle,
      highlights: [
        'Interface glass',
        'Navigation fluide',
        'Local-first',
      ],
    ),
    OnboardingStep(
      title: 'Navigation intelligente',
      subtitle: 'Liste, grille, raccourcis',
      description:
          "Passez d'une vue à l'autre, retrouvez vos dossiers en un geste, et gardez le contrôle en un clic.",
      icon: lucide.LucideIcons.compass,
      highlights: [
        'Grille & liste',
        'Historique instantané',
        'Raccourcis rapides',
      ],
    ),
    OnboardingStep(
      title: 'Archives & glisser-déposer',
      subtitle: 'Manipulez vos fichiers naturellement',
      description:
          'Ouvrez les archives comme des dossiers, glissez-déposez depuis votre bureau et gardez tout organisé.',
      icon: lucide.LucideIcons.archive,
      highlights: [
        'Ouvrir comme dossier',
        'Extraction rapide',
        'Drag & drop',
      ],
    ),
    OnboardingStep(
      title: 'Accès aux fichiers',
      subtitle: 'Choisissez un dossier principal',
      description:
          'Sélectionnez un dossier à explorer. Cela permet à Xplor de rester rapide et de respecter votre vie privée.',
      icon: lucide.LucideIcons.folderKey,
      highlights: [
        'Local uniquement',
        'Réglable plus tard',
        'Indexation rapide',
      ],
      kind: OnboardingStepKind.access,
    ),
    OnboardingStep(
      title: 'Personnalisez votre espace',
      subtitle: 'Thèmes, palettes, ambiance',
      description:
          'Adaptez l\'interface, ajoutez votre fond favori et créez une ambiance qui vous ressemble.',
      icon: lucide.LucideIcons.palette,
      highlights: [
        'Clair & sombre',
        'Fonds personnalisés',
        'Ambiance unique',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _introController.forward();
    _loadAccessPath();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _introController.dispose();
    super.dispose();
  }

  Future<void> _loadAccessPath() async {
    final stored = await OnboardingService.getPreferredRootPath();
    if (!mounted) return;
    if (stored != null && stored.trim().isNotEmpty) {
      setState(() => _accessPath = stored.trim());
    }
  }

  Future<void> _completeOnboarding() async {
    await OnboardingService.setOnboardingCompleted(true);
    if (!mounted) return;
    widget.onComplete?.call();
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _requestAccess() async {
    if (_isRequestingAccess) return;
    setState(() => _isRequestingAccess = true);

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => MiniExplorerDialog(
        title: 'Choisir un dossier principal',
        mode: MiniExplorerPickerMode.directory,
        initialPath: _accessPath ?? _homeDirectory(),
        confirmLabel: 'Autoriser l\'accès',
      ),
    );

    if (!mounted) return;
    if (selected != null && selected.trim().isNotEmpty) {
      final trimmed = selected.trim();
      setState(() => _accessPath = trimmed);
      await OnboardingService.setPreferredRootPath(trimmed);
    }

    if (mounted) {
      setState(() => _isRequestingAccess = false);
    }
  }

  Future<void> _useHomeAccess() async {
    final home = _homeDirectory();
    setState(() => _accessPath = home);
    await OnboardingService.setPreferredRootPath(home);
  }

  String _homeDirectory() {
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'] ?? Directory.current.path;
    }
    return Platform.environment['HOME'] ?? Directory.current.path;
  }

  Color _accentForIndex(ColorScheme scheme, int index) {
    final accents = [scheme.primary, scheme.secondary, scheme.tertiary];
    return accents[index % accents.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final bgImagePath = themeProvider.backgroundImagePath;
    final hasBgImage = bgImagePath != null && File(bgImagePath).existsSync();
    final isLight = themeProvider.isLight;
    final pageValue = _pageController.hasClients
        ? _pageController.page ?? _currentPage.toDouble()
        : _currentPage.toDouble();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          if (!hasBgImage)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLight
                      ? const [Color(0xFFF7F4EF), Color(0xFFEDEAF1)]
                      : const [Color(0xFF0D0D11), Color(0xFF171720)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          if (hasBgImage)
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: FileImage(File(bgImagePath)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          if (hasBgImage)
            Container(
              color: isLight
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.4),
            ),
          _OnboardingBackdrop(isLight: isLight, progress: pageValue),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slideUp,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      return Column(
                        children: [
                          _OnboardingHeader(
                            isLight: isLight,
                            onSkip: _completeOnboarding,
                          ),
                          const SizedBox(height: 18),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (isWide)
                                  SizedBox(
                                    width: 260,
                                    child: _StepRail(
                                      steps: _steps,
                                      currentIndex: _currentPage,
                                      isLight: isLight,
                                      onSelect: (index) {
                                        _pageController.animateToPage(
                                          index,
                                          duration:
                                              const Duration(milliseconds: 350),
                                          curve: Curves.easeOutCubic,
                                        );
                                      },
                                    ),
                                  ),
                                if (isWide) const SizedBox(width: 24),
                                Expanded(
                                  child: _buildPageView(
                                    theme: theme,
                                    isLight: isLight,
                                    pageValue: pageValue,
                                    isWide: isWide,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (!isWide)
                            _StepDots(
                              count: _steps.length,
                              currentIndex: _currentPage,
                              isLight: isLight,
                            ),
                          if (!isWide) const SizedBox(height: 12),
                          _OnboardingFooter(
                            currentIndex: _currentPage,
                            total: _steps.length,
                            isLight: isLight,
                            onBack: _previousPage,
                            onNext: _nextPage,
                            onSkip: _completeOnboarding,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView({
    required ThemeData theme,
    required bool isLight,
    required double pageValue,
    required bool isWide,
  }) {
    return PageView.builder(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) {
        setState(() => _currentPage = index);
      },
      itemCount: _steps.length,
      itemBuilder: (context, index) {
        final step = _steps[index];
        final delta = (pageValue - index).abs().clamp(0.0, 1.0);
        final scale = 1 - (delta * 0.06);
        final opacity = 1 - (delta * 0.25);
        final accent = _accentForIndex(theme.colorScheme, index);

        return Center(
          child: AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, delta * 18),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(opacity: opacity, child: child),
                ),
              );
            },
            child: _OnboardingCard(
              step: step,
              isLight: isLight,
              accent: accent,
              currentIndex: index,
              total: _steps.length,
              accessPath: _accessPath,
              isRequestingAccess: _isRequestingAccess,
              onRequestAccess: _requestAccess,
              onUseHome: _useHomeAccess,
              isWide: isWide,
            ),
          ),
        );
      },
    );
  }
}

class OnboardingStep {
  const OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.highlights,
    this.kind = OnboardingStepKind.standard,
  });

  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<String> highlights;
  final OnboardingStepKind kind;
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.isLight,
    required this.onSkip,
  });

  final bool isLight;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Row(
      children: [
        _BrandMark(isLight: isLight),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xplor',
              style: GoogleFonts.fraunces(
                textStyle: theme.textTheme.titleLarge,
                fontWeight: FontWeight.w700,
                color: onSurface,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'Onboarding',
              style: GoogleFonts.manrope(
                textStyle: theme.textTheme.labelMedium,
                fontWeight: FontWeight.w600,
                color: onSurface.withValues(alpha: 0.6),
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const Spacer(),
        _GlassActionButton(
          label: 'Passer',
          isLight: isLight,
          onPressed: onSkip,
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.isLight});

  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(
              alpha: isLight ? 0.25 : 0.5,
            ),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        lucide.LucideIcons.folderOpen,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    required this.step,
    required this.isLight,
    required this.accent,
    required this.currentIndex,
    required this.total,
    required this.accessPath,
    required this.isRequestingAccess,
    required this.onRequestAccess,
    required this.onUseHome,
    required this.isWide,
  });

  final OnboardingStep step;
  final bool isLight;
  final Color accent;
  final int currentIndex;
  final int total;
  final String? accessPath;
  final bool isRequestingAccess;
  final VoidCallback onRequestAccess;
  final VoidCallback onUseHome;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: _GlassPanel(
        isLight: isLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        borderRadius: 26,
        blurSigma: 24,
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -40,
              child: _GlowOrb(
                color: accent,
                intensity: isLight ? 0.14 : 0.26,
                size: 150,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.9),
                        accent.withValues(alpha: 0.2),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _IconBadge(
                      icon: step.icon,
                      accent: accent,
                      isLight: isLight,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: GoogleFonts.fraunces(
                              textStyle: theme.textTheme.headlineSmall,
                              fontWeight: FontWeight.w700,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.subtitle,
                            style: GoogleFonts.manrope(
                              textStyle: theme.textTheme.bodyMedium,
                              fontWeight: FontWeight.w600,
                              color: onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StepCounter(
                      current: currentIndex + 1,
                      total: total,
                      isLight: isLight,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  step.description,
                  style: GoogleFonts.manrope(
                    textStyle: theme.textTheme.bodyMedium,
                    height: 1.6,
                    color: onSurface.withValues(alpha: 0.76),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: step.highlights
                      .map(
                        (item) => _HighlightChip(
                          label: item,
                          accent: accent,
                          isLight: isLight,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                if (step.kind == OnboardingStepKind.access)
                  _AccessPanel(
                    isLight: isLight,
                    accessPath: accessPath,
                    isRequesting: isRequestingAccess,
                    onRequestAccess: onRequestAccess,
                    onUseHome: onUseHome,
                  )
                else
                  _FeatureDeck(isLight: isLight, accent: accent, isWide: isWide),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureDeck extends StatelessWidget {
  const _FeatureDeck({
    required this.isLight,
    required this.accent,
    required this.isWide,
  });

  final bool isLight;
  final Color accent;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final tiles = [
      _MiniFeature(
        icon: lucide.LucideIcons.layers,
        title: 'Vue adaptée',
        description: 'Basculez entre grille et liste selon vos tâches.',
      ),
      _MiniFeature(
        icon: lucide.LucideIcons.search,
        title: 'Recherche rapide',
        description: 'Tapez, filtrez, trouvez instantanément.',
      ),
      _MiniFeature(
        icon: lucide.LucideIcons.sparkles,
        title: 'Design vivant',
        description: 'Des détails glass et une lumière douce.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isLight
            ? Colors.white.withValues(alpha: 0.72)
            : Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: onSurface.withValues(alpha: isLight ? 0.12 : 0.22),
        ),
      ),
      child: isWide
          ? Row(
              children: tiles
                  .map(
                    (tile) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _FeatureTile(
                          feature: tile,
                          accent: accent,
                          isLight: isLight,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            )
          : Column(
              children: tiles
                  .map(
                    (tile) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _FeatureTile(
                        feature: tile,
                        accent: accent,
                        isLight: isLight,
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _MiniFeature {
  const _MiniFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.feature,
    required this.accent,
    required this.isLight,
  });

  final _MiniFeature feature;
  final Color accent;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isLight
            ? Colors.white.withValues(alpha: 0.82)
            : Colors.black.withValues(alpha: 0.3),
        border: Border.all(
          color: onSurface.withValues(alpha: isLight ? 0.12 : 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: accent.withValues(alpha: isLight ? 0.18 : 0.3),
            ),
            child: Icon(feature.icon, size: 18, color: accent),
          ),
          const SizedBox(height: 12),
          Text(
            feature.title,
            style: GoogleFonts.manrope(
              textStyle: theme.textTheme.titleSmall,
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            feature.description,
            style: GoogleFonts.manrope(
              textStyle: theme.textTheme.bodySmall,
              height: 1.4,
              color: onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessPanel extends StatelessWidget {
  const _AccessPanel({
    required this.isLight,
    required this.accessPath,
    required this.isRequesting,
    required this.onRequestAccess,
    required this.onUseHome,
  });

  final bool isLight;
  final String? accessPath;
  final bool isRequesting;
  final VoidCallback onRequestAccess;
  final VoidCallback onUseHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final hasAccess = accessPath != null && accessPath!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isLight
            ? Colors.white.withValues(alpha: 0.78)
            : Colors.black.withValues(alpha: 0.4),
        border: Border.all(
          color: onSurface.withValues(alpha: isLight ? 0.14 : 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasAccess
                    ? lucide.LucideIcons.shieldCheck
                    : lucide.LucideIcons.shield,
                color: hasAccess
                    ? theme.colorScheme.primary
                    : onSurface.withValues(alpha: 0.7),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                hasAccess ? 'Accès accordé' : 'Autoriser l\'accès',
                style: GoogleFonts.manrope(
                  textStyle: theme.textTheme.titleSmall,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
              const Spacer(),
              if (hasAccess)
                _StatusPill(
                  label: 'Prêt',
                  isLight: isLight,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasAccess
                ? 'Dossier sélectionné :'
                : 'Choisissez un dossier pour explorer vos fichiers.',
            style: GoogleFonts.manrope(
              textStyle: theme.textTheme.bodyMedium,
              color: onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          if (hasAccess)
            Text(
              accessPath!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                textStyle: theme.textTheme.bodySmall,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _GradientButton(
                label: hasAccess ? 'Modifier le dossier' : 'Choisir un dossier',
                icon: lucide.LucideIcons.folderOpen,
                isLight: isLight,
                onPressed: isRequesting ? null : onRequestAccess,
              ),
              _GlassActionButton(
                label: 'Utiliser le dossier personnel',
                icon: lucide.LucideIcons.home,
                isLight: isLight,
                onPressed: onUseHome,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.isLight});

  final String label;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.primary.withValues(alpha: 0.15),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.manrope(
          textStyle: theme.textTheme.labelSmall,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _OnboardingFooter extends StatelessWidget {
  const _OnboardingFooter({
    required this.currentIndex,
    required this.total,
    required this.isLight,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  final int currentIndex;
  final int total;
  final bool isLight;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final isLast = currentIndex == total - 1;

    return Row(
      children: [
        if (currentIndex > 0)
          _GlassActionButton(
            label: 'Précédent',
            icon: lucide.LucideIcons.chevronLeft,
            isLight: isLight,
            onPressed: onBack,
          )
        else
          const SizedBox(width: 128),
        const Spacer(),
        _GlassActionButton(
          label: 'Passer',
          isLight: isLight,
          onPressed: onSkip,
        ),
        const SizedBox(width: 12),
        _GradientButton(
          label: isLast ? 'Terminer' : 'Suivant',
          icon: isLast
              ? lucide.LucideIcons.check
              : lucide.LucideIcons.chevronRight,
          isLight: isLight,
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  const _GlassActionButton({
    required this.label,
    required this.isLight,
    this.icon,
    required this.onPressed,
  });

  final String label;
  final bool isLight;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final disabled = onPressed == null;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isLight
                      ? Colors.white.withValues(alpha: 0.78)
                      : Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                    color: onSurface.withValues(alpha: isLight ? 0.14 : 0.24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isLight ? 0.06 : 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 16, color: onSurface),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: GoogleFonts.manrope(
                        textStyle: theme.textTheme.labelLarge,
                        fontWeight: FontWeight.w700,
                        color: onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.icon,
    required this.isLight,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isLight;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [theme.colorScheme.primary, theme.colorScheme.secondary];
    final disabled = onPressed == null;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      colors.first.withValues(alpha: isLight ? 0.86 : 0.55),
                      colors.last.withValues(alpha: isLight ? 0.76 : 0.45),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isLight ? 0.35 : 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.first
                          .withValues(alpha: isLight ? 0.22 : 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: GoogleFonts.manrope(
                        textStyle: theme.textTheme.labelLarge,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepRail extends StatelessWidget {
  const _StepRail({
    required this.steps,
    required this.currentIndex,
    required this.isLight,
    required this.onSelect,
  });

  final List<OnboardingStep> steps;
  final int currentIndex;
  final bool isLight;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parcours',
          style: GoogleFonts.manrope(
            textStyle: theme.textTheme.titleSmall,
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              final isActive = index == currentIndex;
              final isCompleted = index < currentIndex;
              final isLast = index == steps.length - 1;

              return InkWell(
                onTap: () => onSelect(index),
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    height: 76,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 28,
                          child: Column(
                            children: [
                              _StepIndexBadge(
                                index: index + 1,
                                isActive: isActive,
                                isCompleted: isCompleted,
                                isLight: isLight,
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    margin: const EdgeInsets.only(top: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          (isActive || isCompleted)
                                              ? theme.colorScheme.primary
                                                  .withValues(alpha: 0.55)
                                              : onSurface.withValues(
                                                  alpha: isLight ? 0.25 : 0.35,
                                                ),
                                          onSurface.withValues(
                                            alpha: isLight ? 0.08 : 0.18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: isActive
                                      ? (isLight
                                          ? Colors.white.withValues(
                                              alpha: 0.82,
                                            )
                                          : Colors.white.withValues(
                                              alpha: 0.1,
                                            ))
                                      : (isLight
                                          ? Colors.white.withValues(
                                              alpha: 0.55,
                                            )
                                          : Colors.white.withValues(
                                              alpha: 0.04,
                                            )),
                                  border: Border.all(
                                    color: onSurface.withValues(
                                      alpha: isActive ? 0.18 : 0.1,
                                    ),
                                  ),
                                  boxShadow: [
                                    if (isActive)
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      step.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.manrope(
                                        textStyle: theme.textTheme.bodyMedium,
                                        fontWeight: FontWeight.w700,
                                        color: onSurface.withValues(
                                          alpha: isActive ? 0.95 : 0.75,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      step.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.manrope(
                                        textStyle: theme.textTheme.bodySmall,
                                        fontWeight: FontWeight.w600,
                                        color: onSurface.withValues(
                                          alpha: 0.55,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StepIndexBadge extends StatelessWidget {
  const _StepIndexBadge({
    required this.index,
    required this.isActive,
    required this.isCompleted,
    required this.isLight,
  });

  final int index;
  final bool isActive;
  final bool isCompleted;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = isActive || isCompleted
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.3);
    final fillColor = isActive || isCompleted
        ? theme.colorScheme.primary
        : (isLight
            ? Colors.white.withValues(alpha: 0.65)
            : Colors.black.withValues(alpha: 0.25));
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fillColor,
        border: Border.all(color: baseColor, width: 2),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Center(
        child: isCompleted
            ? const Icon(lucide.LucideIcons.check, size: 12, color: Colors.white)
            : Text(
                index.toString(),
                style: GoogleFonts.manrope(
                  textStyle: theme.textTheme.labelSmall,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
      ),
    );
  }
}

class _StepCounter extends StatelessWidget {
  const _StepCounter({
    required this.current,
    required this.total,
    required this.isLight,
  });

  final int current;
  final int total;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isLight
            ? Colors.white.withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.12),
        border: Border.all(
          color: onSurface.withValues(alpha: isLight ? 0.14 : 0.24),
        ),
      ),
      child: Text(
        '$current / $total',
        style: GoogleFonts.manrope(
          textStyle: theme.textTheme.labelMedium,
          fontWeight: FontWeight.w700,
          color: onSurface.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({
    required this.label,
    required this.accent,
    required this.isLight,
  });

  final String label;
  final Color accent;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: accent.withValues(alpha: isLight ? 0.14 : 0.22),
        border: Border.all(
          color: accent.withValues(alpha: isLight ? 0.3 : 0.4),
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.manrope(
          textStyle: Theme.of(context).textTheme.labelSmall,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: accent,
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.accent,
    required this.isLight,
  });

  final IconData icon;
  final Color accent;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: isLight ? 0.3 : 0.4),
            accent.withValues(alpha: isLight ? 0.08 : 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
      ),
      child: Icon(icon, size: 28, color: accent),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({
    required this.count,
    required this.currentIndex,
    required this.isLight,
  });

  final int count;
  final int currentIndex;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) {
          final isActive = index == currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: isLight ? 0.2 : 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
          );
        },
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.isLight,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.blurSigma = 20,
  });

  final bool isLight;
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final baseColor = isLight
        ? Colors.white.withValues(alpha: 0.75)
        : Colors.black.withValues(alpha: 0.55);
    final border = onSurface.withValues(alpha: isLight ? 0.12 : 0.22);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.3),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _OnboardingBackdrop extends StatelessWidget {
  const _OnboardingBackdrop({required this.isLight, required this.progress});

  final bool isLight;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final tertiary = Theme.of(context).colorScheme.tertiary;
    final shift = (progress - progress.floor()).clamp(0.0, 1.0);

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120 + shift * 40,
            right: -80 + shift * 20,
            child: _GlowOrb(
              color: primary,
              intensity: isLight ? 0.18 : 0.28,
              size: 280,
            ),
          ),
          Positioned(
            bottom: -140 - shift * 30,
            left: -90 + shift * 20,
            child: _GlowOrb(
              color: secondary,
              intensity: isLight ? 0.14 : 0.24,
              size: 260,
            ),
          ),
          Positioned(
            top: 80 + shift * 20,
            left: 40,
            child: _GlowOrb(
              color: tertiary,
              intensity: isLight ? 0.12 : 0.22,
              size: 180,
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPatternPainter(
                color: Colors.white.withValues(alpha: isLight ? 0.08 : 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.color,
    required this.intensity,
    required this.size,
  });

  final Color color;
  final double intensity;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: intensity),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  const _GridPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 60.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
