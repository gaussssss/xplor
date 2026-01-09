import 'dart:convert';
import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';

import '../../../../core/constants/assets.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/animated_background.dart';

const String _appVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.0.0',
);
const String _buildNumber = String.fromEnvironment(
  'BUILD_NUMBER',
  defaultValue: 'dev',
);
const String _githubRepoUrl = 'https://github.com/gaussssss/xplor';
const String _githubRepoLabel = 'github.com/gaussssss/xplor';
const String _githubApiUrl = 'https://api.github.com/repos/gaussssss/xplor';

class _GithubRepoStats {
  const _GithubRepoStats({
    required this.stars,
    required this.forks,
    required this.issues,
    required this.updatedAt,
  });

  final int stars;
  final int forks;
  final int issues;
  final DateTime updatedAt;

  factory _GithubRepoStats.fromJson(Map<String, dynamic> json) {
    return _GithubRepoStats(
      stars: json['stargazers_count'] as int? ?? 0,
      forks: json['forks_count'] as int? ?? 0,
      issues: json['open_issues_count'] as int? ?? 0,
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class Contributor {
  const Contributor({
    required this.name,
    required this.role,
    required this.githubUrl,
    required this.linkedinUrl,
    required this.avatarAsset,
  });

  final String name;
  final String role;
  final String githubUrl;
  final String linkedinUrl;
  final String avatarAsset;
}

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _bounce;
  late final Future<_GithubRepoStats> _githubStatsFuture;

  static const List<Contributor> _contributors = [
    Contributor(
      name: 'Florian Tiya',
      role: 'Design & Engineering',
      githubUrl: 'https://github.com/gaussssss/',
      linkedinUrl: 'https://www.linkedin.com/in/floriantiya/',
      avatarAsset: AppAssets.florianPortrait,
    ),
    Contributor(
      name: 'Jacobin Fokou',
      role: 'Product & Engineering',
      githubUrl: 'https://github.com/HeroNational',
      linkedinUrl: 'https://www.linkedin.com/in/jacobindanielfokou/',
      avatarAsset: AppAssets.jacobinPortrait,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _bounce = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _githubStatsFuture = _fetchGithubStats();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final hasBgImage = themeProvider.hasBackgroundImage;
    final bgImage = themeProvider.backgroundImageProvider;
    final bgImageKey = themeProvider.backgroundImagePath;
    final bgAttribution = themeProvider.backgroundImageAttribution;
    final isLight = themeProvider.isLight;

    final adjustedSurface = hasBgImage
        ? (isLight
              ? Colors.white.withValues(alpha: 0.9)
              : Colors.black.withValues(alpha: 0.7))
        : theme.colorScheme.surface;
    final adjustedOnSurface = hasBgImage && isLight
        ? Colors.black
        : (hasBgImage ? Colors.white : theme.colorScheme.onSurface);
    final themed = theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        surface: adjustedSurface,
        onSurface: adjustedOnSurface,
        onPrimary: hasBgImage && isLight
            ? Colors.black
            : (hasBgImage ? Colors.white : theme.colorScheme.onPrimary),
        onSecondary: hasBgImage && isLight
            ? Colors.black
            : (hasBgImage ? Colors.white : theme.colorScheme.onSecondary),
        onTertiary: hasBgImage && isLight
            ? Colors.black
            : (hasBgImage ? Colors.white : theme.colorScheme.onTertiary),
      ),
    );

    return Theme(
      data: themed,
      child: ScaffoldMessenger(
        key: _messengerKey,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              if (!hasBgImage)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLight
                          ? const [Color(0xFFF7F7F7), Color(0xFFECEFF1)]
                          : const [Color(0xFF0F1012), Color(0xFF151820)],
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
              _DecorativeBackdrop(isLight: isLight),
              if (hasBgImage &&
                  bgAttribution != null &&
                  bgAttribution.trim().isNotEmpty)
                Positioned(
                  right: 20,
                  bottom: 16,
                  child: Text(
                    bgAttribution,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                      shadows: [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.black.withValues(alpha: 0.35),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1140),
                      child: FadeTransition(
                        opacity: _fade,
                        child: SlideTransition(
                          position: _slideUp,
                          child: Column(
                            children: [
                              _HeaderBar(
                                title: 'À propos',
                                subtitle:
                                    'Xplor, explorateur moderne et local-first',
                                onClose: () => Navigator.pop(context),
                              ),
                              const SizedBox(height: 18),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth > 980;
                                    final hero = _HeroCard(
                                      isLight: isLight,
                                      bounce: _bounce,
                                      onCopyRepo: () =>
                                          _copyLink(context, _githubRepoUrl),
                                    );
                                    final contributors = _SectionCard(
                                      title: 'Contributeurs',
                                      subtitle: 'Les visages derrière Xplor',
                                      icon: lucide.LucideIcons.users,
                                      isLight: isLight,
                                      child: LayoutBuilder(
                                        builder: (context, inner) {
                                          final maxWidth = inner.maxWidth;
                                          final cardWidth = maxWidth >= 520
                                              ? (maxWidth - 12) / 2
                                              : maxWidth;
                                          return Wrap(
                                            spacing: 12,
                                            runSpacing: 12,
                                            children: _contributors
                                                .map(
                                                  (contributor) => SizedBox(
                                                    width: cardWidth,
                                                    child: _ContributorCard(
                                                      contributor: contributor,
                                                      isLight: isLight,
                                                      onCopy: (url) =>
                                                          _copyLink(
                                                            context,
                                                            url,
                                                          ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          );
                                        },
                                      ),
                                    );
                                    final stats = _SectionCard(
                                      title: 'Statistiques GitHub',
                                      subtitle: _githubRepoLabel,
                                      icon: lucide.LucideIcons.github,
                                      isLight: isLight,
                                      child: FutureBuilder<_GithubRepoStats>(
                                        future: _githubStatsFuture,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState !=
                                              ConnectionState.done) {
                                            return _StatsWrap(
                                              isLight: isLight,
                                              items: _buildStatItems(null),
                                              isPlaceholder: true,
                                            );
                                          }

                                          if (!snapshot.hasData) {
                                            return _StatsError(
                                              isLight: isLight,
                                              onCopy: () => _copyLink(
                                                context,
                                                _githubRepoUrl,
                                              ),
                                            );
                                          }

                                          return _StatsWrap(
                                            isLight: isLight,
                                            items: _buildStatItems(
                                              snapshot.data,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                    final values = _SectionCard(
                                      title: 'Notre ADN',
                                      subtitle:
                                          'Ce qui façonne l’expérience Xplor',
                                      icon: lucide.LucideIcons.sparkles,
                                      isLight: isLight,
                                      child: Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          _ValueTile(
                                            icon: lucide.LucideIcons.lock,
                                            title: 'Local-first',
                                            description:
                                                'Vos données restent sur votre machine.',
                                            isLight: isLight,
                                          ),
                                          _ValueTile(
                                            icon: lucide.LucideIcons.archive,
                                            title: 'Archives fluides',
                                            description:
                                                'Ouvrir, explorer et extraire sans friction.',
                                            isLight: isLight,
                                          ),
                                          _ValueTile(
                                            icon: lucide.LucideIcons.palette,
                                            title: 'Personnalisation',
                                            description:
                                                'Thèmes, fonds, raccourcis, tout est modulable.',
                                            isLight: isLight,
                                          ),
                                          _ValueTile(
                                            icon:
                                                lucide.LucideIcons.shieldCheck,
                                            title: 'Confiance',
                                            description:
                                                'Open-source MIT et transparence totale.',
                                            isLight: isLight,
                                          ),
                                        ],
                                      ),
                                    );
                                    final links = _SectionCard(
                                      title: 'Ressources',
                                      subtitle: 'Aller plus loin',
                                      icon: lucide.LucideIcons.link2,
                                      isLight: isLight,
                                      child: Column(
                                        children: [
                                          _LinkTile(
                                            icon: lucide.LucideIcons.github,
                                            title: 'Code source',
                                            subtitle: _githubRepoLabel,
                                            isLight: isLight,
                                            onTap: () => _copyLink(
                                              context,
                                              _githubRepoUrl,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          _LinkTile(
                                            icon: lucide.LucideIcons.sparkles,
                                            title: 'Contribution',
                                            subtitle: 'Pull requests & idées',
                                            isLight: isLight,
                                            onTap: () => _copyLink(
                                              context,
                                              '$_githubRepoUrl/pulls',
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          _LinkTile(
                                            icon: lucide.LucideIcons.bug,
                                            title: 'Signaler un bug',
                                            subtitle: 'Issues GitHub',
                                            isLight: isLight,
                                            onTap: () => _copyLink(
                                              context,
                                              '$_githubRepoUrl/issues',
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (isWide) {
                                      return SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            hero,
                                            const SizedBox(height: 20),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: Column(
                                                    children: [
                                                      contributors,
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      values,
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      links,
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 18),
                                                Expanded(
                                                  flex: 2,
                                                  child: Column(
                                                    children: [
                                                      stats,
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      _SideNotePanel(
                                                        isLight: isLight,
                                                        onCopy: () => _copyLink(
                                                          context,
                                                          _githubRepoUrl,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          hero,
                                          const SizedBox(height: 18),
                                          contributors,
                                          const SizedBox(height: 16),
                                          stats,
                                          const SizedBox(height: 16),
                                          values,
                                          const SizedBox(height: 16),
                                          links,
                                          const SizedBox(height: 16),
                                          _SideNotePanel(
                                            isLight: isLight,
                                            onCopy: () => _copyLink(
                                              context,
                                              _githubRepoUrl,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '© 2026 Xplor. Sous licence MIT.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
  }

  Future<_GithubRepoStats> _fetchGithubStats() async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(_githubApiUrl));
      request.headers.set(HttpHeaders.userAgentHeader, 'xplor-app');
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw HttpException('GitHub API error: ${response.statusCode}');
      }
      final data = jsonDecode(body) as Map<String, dynamic>;
      return _GithubRepoStats.fromJson(data);
    } finally {
      client.close();
    }
  }

  String _formatStatValue(int value) {
    if (value >= 1000000) {
      final formatted = (value / 1000000).toStringAsFixed(
        value % 1000000 == 0 ? 0 : 1,
      );
      return '${formatted}M';
    }
    if (value >= 1000) {
      final formatted = (value / 1000).toStringAsFixed(
        value % 1000 == 0 ? 0 : 1,
      );
      return '${formatted}k';
    }
    return value.toString();
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }

  List<_StatItem> _buildStatItems(_GithubRepoStats? stats) {
    return [
      _StatItem(
        icon: lucide.LucideIcons.star,
        label: 'Stars',
        value: stats == null ? '—' : _formatStatValue(stats.stars),
      ),
      _StatItem(
        icon: lucide.LucideIcons.gitFork,
        label: 'Forks',
        value: stats == null ? '—' : _formatStatValue(stats.forks),
      ),
      _StatItem(
        icon: lucide.LucideIcons.bug,
        label: 'Issues ouvertes',
        value: stats == null ? '—' : stats.issues.toString(),
      ),
      _StatItem(
        icon: lucide.LucideIcons.refreshCcw,
        label: 'MAJ',
        value: stats == null ? '—' : _formatDate(stats.updatedAt),
      ),
    ];
  }

  Future<void> _copyLink(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    final messenger =
        _messengerKey.currentState ?? ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text('Lien copié : $url'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
          ),
          child: Icon(
            lucide.LucideIcons.sparkle,
            color: theme.colorScheme.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(lucide.LucideIcons.x),
          onPressed: onClose,
          color: onSurface.withValues(alpha: 0.7),
        ),
      ],
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.isLight,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.blurSigma = 18,
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
        ? Colors.white.withValues(alpha: 0.72)
        : Colors.black.withValues(alpha: 0.6);
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
                color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.35),
                blurRadius: 28,
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

class _BrandBadge extends StatelessWidget {
  const _BrandBadge({required this.isLight});

  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(
              alpha: isLight ? 0.2 : 0.45,
            ),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        lucide.LucideIcons.folderOpen,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.isLight,
  });

  final IconData icon;
  final String label;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final bg = isLight
        ? Colors.black.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.08);
    final border = onSurface.withValues(alpha: isLight ? 0.12 : 0.2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: onSurface.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.isLight,
    required this.bounce,
    required this.onCopyRepo,
  });

  final bool isLight;
  final Animation<double> bounce;
  final VoidCallback onCopyRepo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 560;
        return ScaleTransition(
          scale: bounce,
          child: _GlassPanel(
            isLight: isLight,
            padding: const EdgeInsets.all(28),
            borderRadius: 28,
            blurSigma: 22,
            child: Stack(
              children: [
                Positioned(
                  right: -120,
                  top: -80,
                  child: _GlowOrb(
                    color: theme.colorScheme.primary,
                    intensity: isLight ? 0.18 : 0.28,
                    size: 200,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BrandBadge(isLight: isLight),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xplor',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Explorateur moderne, rapide et local-first.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: const [
                                  _AccentChip(label: 'Open-source MIT'),
                                  _AccentChip(label: 'Local-first'),
                                  _AccentChip(label: 'Archives intelligentes'),
                                  _AccentChip(label: 'Design glass'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!isNarrow) ...[
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _MetaPill(
                                icon: lucide.LucideIcons.badgeCheck,
                                label: 'Version $_appVersion',
                                isLight: isLight,
                              ),
                              const SizedBox(height: 8),
                              _MetaPill(
                                icon: lucide.LucideIcons.cog,
                                label: 'Build $_buildNumber',
                                isLight: isLight,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Xplor combine une navigation fluide, une gestion avancée des archives et une interface immersive pour une expérience de bureau premium.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        color: onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: onCopyRepo,
                          icon: const Icon(lucide.LucideIcons.copy, size: 16),
                          label: const Text('Copier le repo GitHub'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface,
                            side: BorderSide(
                              color: onSurface.withValues(alpha: 0.2),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                        ),
                        _MetaPill(
                          icon: lucide.LucideIcons.github,
                          label: _githubRepoLabel,
                          isLight: isLight,
                        ),
                        if (isNarrow) ...[
                          _MetaPill(
                            icon: lucide.LucideIcons.badgeCheck,
                            label: 'Version $_appVersion',
                            isLight: isLight,
                          ),
                          _MetaPill(
                            icon: lucide.LucideIcons.cog,
                            label: 'Build $_buildNumber',
                            isLight: isLight,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.isLight,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool isLight;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return _GlassPanel(
      isLight: isLight,
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                ),
                child: Icon(icon, size: 18, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.isLight,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final bg = isLight
        ? Colors.black.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.06);
    final border = onSurface.withValues(alpha: isLight ? 0.08 : 0.18);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.primary.withValues(alpha: 0.18),
              ),
              child: Icon(icon, size: 18, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onSurface.withValues(alpha: 0.65),
                      height: 1.4,
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
}

class _SideNotePanel extends StatelessWidget {
  const _SideNotePanel({required this.isLight, required this.onCopy});

  final bool isLight;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return _GlassPanel(
      isLight: isLight,
      padding: const EdgeInsets.all(18),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                lucide.LucideIcons.sparkle,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Projet communautaire',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Xplor est pensé avec la communauté. Vos idées, bugs et contributions construisent la suite.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onCopy,
              icon: const Icon(lucide.LucideIcons.copy, size: 16),
              label: const Text('Copier le lien GitHub'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributorCard extends StatelessWidget {
  const _ContributorCard({
    required this.contributor,
    required this.isLight,
    required this.onCopy,
  });

  final Contributor contributor;
  final bool isLight;
  final void Function(String url) onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final bg = isLight
        ? Colors.black.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.05);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: onSurface.withValues(alpha: isLight ? 0.1 : 0.18),
        ),
      ),
      child: Row(
        children: [
          _AvatarBadge(
            name: contributor.name,
            assetPath: contributor.avatarAsset,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contributor.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contributor.role,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    _LinkPill(
                      icon: lucide.LucideIcons.github,
                      label: 'GitHub',
                      onTap: () => onCopy(contributor.githubUrl),
                    ),
                    _LinkPill(
                      icon: lucide.LucideIcons.linkedin,
                      label: 'LinkedIn',
                      onTap: () => onCopy(contributor.linkedinUrl),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLight,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final bg = isLight
        ? Colors.black.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.05);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: onSurface.withValues(alpha: isLight ? 0.1 : 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              lucide.LucideIcons.copy,
              size: 16,
              color: onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _StatsWrap extends StatelessWidget {
  const _StatsWrap({
    required this.isLight,
    required this.items,
    this.isPlaceholder = false,
  });

  final bool isLight;
  final List<_StatItem> items;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => _StatTile(
              item: item,
              isLight: isLight,
              isPlaceholder: isPlaceholder,
            ),
          )
          .toList(),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.item,
    required this.isLight,
    required this.isPlaceholder,
  });

  final _StatItem item;
  final bool isLight;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final bg = isLight
        ? Colors.black.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.06);
    final border = onSurface.withValues(alpha: isLight ? 0.08 : 0.2);
    final valueColor = onSurface.withValues(alpha: isPlaceholder ? 0.35 : 0.9);
    final labelColor = onSurface.withValues(alpha: isPlaceholder ? 0.35 : 0.6);
    final iconColor = theme.colorScheme.primary.withValues(
      alpha: isPlaceholder ? 0.5 : 1,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: theme.colorScheme.primary.withValues(
                alpha: isPlaceholder ? 0.12 : 0.2,
              ),
            ),
            child: Icon(item.icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: theme.textTheme.labelSmall?.copyWith(color: labelColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsError extends StatelessWidget {
  const _StatsError({required this.isLight, required this.onCopy});

  final bool isLight;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final bg = isLight
        ? Colors.black.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.06);
    final border = onSurface.withValues(alpha: isLight ? 0.08 : 0.2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            lucide.LucideIcons.cloudOff,
            size: 18,
            color: onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Impossible de charger les stats GitHub.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          TextButton(onPressed: onCopy, child: const Text('Copier le lien')),
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.name, required this.assetPath});

  final String name;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.onSurface.withValues(alpha: 0.18);

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1),
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _InitialsAvatar(name: name),
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final parts = name.split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'
        : name.characters.first;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _LinkPill extends StatelessWidget {
  const _LinkPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: onSurface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentChip extends StatelessWidget {
  const _AccentChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.primary.withValues(alpha: 0.15),
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _DecorativeBackdrop extends StatelessWidget {
  const _DecorativeBackdrop({required this.isLight});

  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final tertiary = Theme.of(context).colorScheme.tertiary;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _GlowOrb(
              color: primary,
              intensity: isLight ? 0.18 : 0.28,
              size: 260,
            ),
          ),
          Positioned(
            bottom: -140,
            left: -90,
            child: _GlowOrb(
              color: tertiary,
              intensity: isLight ? 0.16 : 0.24,
              size: 280,
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
