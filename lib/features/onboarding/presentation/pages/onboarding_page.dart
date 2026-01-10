import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';

import '../../../../core/constants/assets.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/animated_background.dart';
import '../../../../core/widgets/mini_explorer_dialog.dart';
import '../../data/onboarding_service.dart';

enum OnboardingStepKind { standard, access }

/// Page d'onboarding avec plusieurs étapes
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.onComplete});

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
  List<String> _accessPaths = [];
  bool _isRequestingAccess = false;

  static const List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Bienvenue dans Xplor',
      subtitle: 'Un explorateur qui se sent vivant',
      description:
          "Xplor mélange élégance, vitesse et clarté pour transformer la navigation en expérience fluide.",
      icon: lucide.LucideIcons.sparkle,
      highlights: ['Interface glass', 'Navigation fluide', 'Local-first'],
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
      primaryCtaLabel: 'Explorer les archives',
      primaryCtaIcon: lucide.LucideIcons.archive,
      secondaryCtaLabel: 'Voir le drag & drop',
      secondaryCtaIcon: lucide.LucideIcons.mousePointer2,
      highlights: [
        'Ouvrir comme dossier',
        'Extraction rapide',
        'Drag & drop',
        'Chiffrer vos dossiers',
        'Verrouillage par clé',
      ],
    ),
    OnboardingStep(
      title: 'Chiffrement & verrouillage',
      subtitle: 'Protégez vos fichiers et dossiers',
      description:
          'Verrouillez vos fichiers ou dossiers avec une clé de chiffrement. '
          'Tout est chiffré localement, et vous gardez le contrôle.',
      icon: lucide.LucideIcons.lock,
      primaryCtaLabel: 'Découvrir le verrouillage',
      primaryCtaIcon: lucide.LucideIcons.lock,
      secondaryCtaLabel: 'Voir la sécurité',
      secondaryCtaIcon: lucide.LucideIcons.shieldCheck,
      highlights: [
        'Clé privée',
        'Chiffrement local',
        'Fichiers & dossiers',
        'Déverrouillage rapide',
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
        'Chiffrement disponible',
      ],
      kind: OnboardingStepKind.access,
    ),
    OnboardingStep(
      title: 'Personnalisez votre espace',
      subtitle: 'Thèmes, palettes, ambiance',
      description:
          'Adaptez l\'interface, ajoutez votre fond favori et créez une ambiance qui vous ressemble.',
      icon: lucide.LucideIcons.palette,
      primaryCtaLabel: 'Personnaliser maintenant',
      primaryCtaIcon: lucide.LucideIcons.palette,
      secondaryCtaLabel: 'Découvrir les thèmes',
      secondaryCtaIcon: lucide.LucideIcons.sparkles,
      highlights: ['Clair & sombre', 'Fonds personnalisés', 'Ambiance unique'],
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
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _introController.forward();
    _loadAccessPath();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyGreenOnboardingBackground();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _introController.dispose();
    super.dispose();
  }

  Future<void> _loadAccessPath() async {
    final stored = await OnboardingService.getPreferredRootPaths();
    if (!mounted) return;
    if (stored.isNotEmpty) {
      setState(() => _accessPaths = stored);
    }
  }

  Future<void> _applyGreenOnboardingBackground() async {
    final themeProvider = context.read<ThemeProvider>();
    for (var attempt = 0; attempt < 5; attempt += 1) {
      if (themeProvider.backgroundThemes.isNotEmpty) {
        await themeProvider.applyRandomThemeImage('green', limitToFirst: 3);
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
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
        title: 'Ajouter un dossier',
        mode: MiniExplorerPickerMode.directory,
        initialPath: _accessPaths.isNotEmpty
            ? _accessPaths.last
            : _homeDirectory(),
        confirmLabel: 'Ajouter ce dossier',
      ),
    );

    if (!mounted) return;
    if (selected != null && selected.trim().isNotEmpty) {
      await _addAccessPath(selected);
    }

    if (mounted) {
      setState(() => _isRequestingAccess = false);
    }
  }

  Future<void> _useHomeAccess() async {
    final home = _homeDirectory();
    await _addAccessPath(home);
  }

  Future<void> _addAccessPath(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return;
    if (_accessPaths.contains(trimmed)) {
      return;
    }
    final updated = [..._accessPaths, trimmed];
    setState(() => _accessPaths = updated);
    await OnboardingService.setPreferredRootPaths(updated);
  }

  Future<void> _removeAccessPath(String path) async {
    final updated = _accessPaths.where((item) => item != path).toList();
    setState(() => _accessPaths = updated);
    await OnboardingService.setPreferredRootPaths(updated);
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
    final hasBgImage = themeProvider.hasBackgroundImage;
    final bgImage = themeProvider.backgroundImageProvider;
    final bgImageKey = themeProvider.backgroundImagePath;
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
            if (hasBgImage && bgImage != null)
              AnimatedBackground(image: bgImage, imageKey: bgImageKey),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 24,
                    ),
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
                                            duration: const Duration(
                                              milliseconds: 350,
                                            ),
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
        final isActive = index == _currentPage;
        final primaryCta = index == _steps.length - 1
            ? _completeOnboarding
            : _nextPage;

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
              isActive: isActive,
              accessPaths: _accessPaths,
              isRequestingAccess: _isRequestingAccess,
              onRequestAccess: _requestAccess,
              onUseHome: _useHomeAccess,
              onRemoveAccessPath: _removeAccessPath,
              onPrimaryCta: primaryCta,
              onSecondaryCta: _nextPage,
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
    this.primaryCtaLabel,
    this.primaryCtaIcon,
    this.secondaryCtaLabel,
    this.secondaryCtaIcon,
  });

  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<String> highlights;
  final OnboardingStepKind kind;
  final String? primaryCtaLabel;
  final IconData? primaryCtaIcon;
  final String? secondaryCtaLabel;
  final IconData? secondaryCtaIcon;
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({required this.isLight, required this.onSkip});

  final bool isLight;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(left: 0, top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _BrandMark(isLight: isLight),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
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
                'Découvrir. Explorer. Maîtriser.',
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
      ),
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
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isLight
            ? Colors.white.withValues(alpha: 0.65)
            : Colors.white.withValues(alpha: 0.12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(
              alpha: isLight ? 0.18 : 0.4,
            ),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(AppAssets.logo, fit: BoxFit.cover),
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
    required this.isActive,
    required this.accessPaths,
    required this.isRequestingAccess,
    required this.onRequestAccess,
    required this.onUseHome,
    required this.onRemoveAccessPath,
    required this.onPrimaryCta,
    required this.onSecondaryCta,
    required this.isWide,
  });

  final OnboardingStep step;
  final bool isLight;
  final Color accent;
  final int currentIndex;
  final int total;
  final bool isActive;
  final List<String> accessPaths;
  final bool isRequestingAccess;
  final VoidCallback onRequestAccess;
  final VoidCallback onUseHome;
  final ValueChanged<String> onRemoveAccessPath;
  final VoidCallback onPrimaryCta;
  final VoidCallback onSecondaryCta;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final alignRight = currentIndex.isOdd;
    final crossAxis = alignRight
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final textAlign = alignRight ? TextAlign.right : TextAlign.left;
    final alignment = alignRight ? Alignment.centerRight : Alignment.centerLeft;
    final titleSize = isWide ? 60.0 : 46.0;
    final subtitleSize = isWide ? 20.0 : 18.0;
    final bodySize = isWide ? 17.0 : 15.0;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 550),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(animation);
          final scale = Tween<double>(begin: 0.96, end: 1).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: slide,
              child: ScaleTransition(scale: scale, child: child),
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey('${step.title}-$isActive'),
          child: Align(
            alignment: alignment,
            child: SizedBox(
              width: isWide ? 560 : double.infinity,
              child: Column(
                crossAxisAlignment: crossAxis,
                children: [
                  Row(
                    mainAxisAlignment: alignRight
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: alignRight
                        ? [
                            _StepCounter(
                              current: currentIndex + 1,
                              total: total,
                              isLight: isLight,
                            ),
                            const SizedBox(width: 10),
                            _IconBadge(
                              icon: step.icon,
                              accent: accent,
                              isLight: isLight,
                            ),
                          ]
                        : [
                            _IconBadge(
                              icon: step.icon,
                              accent: accent,
                              isLight: isLight,
                            ),
                            const SizedBox(width: 10),
                            _StepCounter(
                              current: currentIndex + 1,
                              total: total,
                              isLight: isLight,
                            ),
                          ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: alignRight
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 110,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          colors: [
                            accent.withValues(alpha: 0.9),
                            accent.withValues(alpha: 0.15),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    step.title,
                    textAlign: textAlign,
                    style: GoogleFonts.fraunces(
                      fontSize: titleSize,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                      color: onSurface.withValues(alpha: 0.92),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(
                            alpha: isLight ? 0.12 : 0.4,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (isActive)
                    _TypewriterText(
                      key: ValueKey('subtitle-${step.subtitle}-$isActive'),
                      text: step.subtitle,
                      textAlign: textAlign,
                      style: GoogleFonts.manrope(
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: onSurface.withValues(alpha: 0.74),
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(
                              alpha: isLight ? 0.1 : 0.35,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      step.subtitle,
                      textAlign: textAlign,
                      style: GoogleFonts.manrope(
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: onSurface.withValues(alpha: 0.74),
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(
                              alpha: isLight ? 0.1 : 0.35,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    step.description,
                    textAlign: textAlign,
                    style: GoogleFonts.manrope(
                      fontSize: bodySize,
                      height: 1.6,
                      color: onSurface.withValues(alpha: 0.72),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(
                            alpha: isLight ? 0.06 : 0.28,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: alignRight
                        ? WrapAlignment.end
                        : WrapAlignment.start,
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
                  const SizedBox(height: 18),
                  if (step.kind == OnboardingStepKind.access)
                    _AccessPanel(
                      isLight: isLight,
                      alignRight: alignRight,
                      accessPaths: accessPaths,
                      isRequesting: isRequestingAccess,
                      onRequestAccess: onRequestAccess,
                      onUseHome: onUseHome,
                      onRemovePath: onRemoveAccessPath,
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

class _AccessPanel extends StatelessWidget {
  const _AccessPanel({
    required this.isLight,
    required this.alignRight,
    required this.accessPaths,
    required this.isRequesting,
    required this.onRequestAccess,
    required this.onUseHome,
    required this.onRemovePath,
  });

  final bool isLight;
  final bool alignRight;
  final List<String> accessPaths;
  final bool isRequesting;
  final VoidCallback onRequestAccess;
  final VoidCallback onUseHome;
  final ValueChanged<String> onRemovePath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final hasAccess = accessPaths.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: isLight
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: onSurface.withValues(alpha: isLight ? 0.18 : 0.22),
            ),
          ),
          child: Column(
            crossAxisAlignment: alignRight
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: alignRight
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
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
                  const SizedBox(width: 12),
                  if (hasAccess) _StatusPill(label: 'Prêt', isLight: isLight),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                hasAccess
                    ? 'Dossiers sélectionnés :'
                    : 'Choisissez un ou plusieurs dossiers pour explorer vos fichiers.',
                textAlign: alignRight ? TextAlign.right : TextAlign.left,
                style: GoogleFonts.manrope(
                  textStyle: theme.textTheme.bodyMedium,
                  color: onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 10),
              if (hasAccess)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: alignRight
                      ? WrapAlignment.end
                      : WrapAlignment.start,
                  children: accessPaths
                      .map(
                        (path) => _AccessPathBadge(
                          path: path,
                          isLight: isLight,
                          onRemove: () => onRemovePath(path),
                        ),
                      )
                      .toList(),
                )
              else
                Text(
                  'Aucun dossier ajouté pour le moment.',
                  textAlign: alignRight ? TextAlign.right : TextAlign.left,
                  style: GoogleFonts.manrope(
                    textStyle: theme.textTheme.bodySmall,
                    fontWeight: FontWeight.w600,
                    color: onSurface.withValues(alpha: 0.55),
                  ),
                ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: alignRight ? WrapAlignment.end : WrapAlignment.start,
                children: [
                  _GradientButton(
                    label: hasAccess
                        ? 'Ajouter un dossier'
                        : 'Choisir un dossier',
                    icon: lucide.LucideIcons.folderPlus,
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
        ),
      ),
    );
  }
}

class _AccessPathBadge extends StatelessWidget {
  const _AccessPathBadge({
    required this.path,
    required this.isLight,
    required this.onRemove,
  });

  final String path;
  final bool isLight;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isLight
              ? Colors.white.withValues(alpha: 0.72)
              : Colors.white.withValues(alpha: 0.2),
          border: Border.all(
            color: onSurface.withValues(alpha: isLight ? 0.22 : 0.32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              lucide.LucideIcons.folder,
              size: 14,
              color: onSurface.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  textStyle: theme.textTheme.labelMedium,
                  fontWeight: FontWeight.w600,
                  color: onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                lucide.LucideIcons.x,
                size: 14,
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
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
        color: theme.colorScheme.primary.withValues(
          alpha: isLight ? 0.28 : 0.22,
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(
            alpha: isLight ? 0.45 : 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
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
  });

  final int currentIndex;
  final int total;
  final bool isLight;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = currentIndex == total - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (currentIndex > 0)
          _GlassActionButton(
            label: 'Précédent',
            icon: lucide.LucideIcons.chevronLeft,
            isLight: isLight,
            onPressed: onBack,
          )
        else
          const SizedBox.shrink(),
        if (currentIndex > 0) const SizedBox(width: 12),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isLight
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.28),
                  border: Border.all(
                    color: onSurface.withValues(alpha: isLight ? 0.2 : 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isLight ? 0.06 : 0.25,
                      ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
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
                      color: colors.first.withValues(
                        alpha: isLight ? 0.22 : 0.35,
                      ),
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

class _TypewriterText extends StatefulWidget {
  const _TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.left,
    this.speedPerChar = const Duration(milliseconds: 28),
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final Duration speedPerChar;

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _chars;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  @override
  void didUpdateWidget(covariant _TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.speedPerChar != widget.speedPerChar) {
      _controller.dispose();
      _initAnimation();
    }
  }

  void _initAnimation() {
    final length = widget.text.length;
    final duration = Duration(
      milliseconds: (length * widget.speedPerChar.inMilliseconds) + 120,
    );
    _controller = AnimationController(vsync: this, duration: duration);
    _chars = StepTween(
      begin: 0,
      end: length,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    if (length == 0) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    return AnimatedBuilder(
      animation: _chars,
      builder: (context, child) {
        final count = _chars.value.clamp(0, text.length);
        return Text(
          text.substring(0, count),
          textAlign: widget.textAlign,
          style: widget.style,
        );
      },
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
          '',
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
            ? const Icon(
                lucide.LucideIcons.check,
                size: 12,
                color: Colors.white,
              )
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isLight
            ? accent.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.08),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.manrope(
          textStyle: Theme.of(context).textTheme.labelSmall,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
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
            accent.withValues(alpha: isLight ? 0.45 : 0.38),
            accent.withValues(alpha: isLight ? 0.18 : 0.28),
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
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: isLight ? 0.2 : 0.4,
                  ),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
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
