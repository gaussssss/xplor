import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/constants/assets.dart';

/// Informations sur un contributeur
class Contributor {
  const Contributor({
    required this.name,
    required this.role,
    this.bio,
    this.linkedinUrl,
    this.githubUrl,
    this.avatarUrl,
  });

  final String name;
  final String role;
  final String? bio;
  final String? linkedinUrl;
  final String? githubUrl;
  final String? avatarUrl;
}

/// Page À propos de l'application
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // Liste des contributeurs
  static const List<Contributor> _contributors = [
    Contributor(
      name: 'Florian Tiya',
      role: 'Ingénieur logiciel',
      bio:
          "Je conçois des applications solides, évolutives et pensées pour les besoins réels des entreprises. Au-delà du code : comprendre les enjeux, anticiper les problèmes, et collaborer efficacement pour livrer des solutions fiables et utiles.",
      githubUrl: 'https://github.com/gaussssss',
      linkedinUrl: 'https://www.linkedin.com/in/floriantiya',
      avatarUrl: AppAssets.portraitFlorian,
    ),
    Contributor(
      name: 'Jacobin Daniel Fokou',
      role: 'Ingénieur travaux informatiques',
      bio:
          'Informaticien, développeur de solutions logicielles et digitales. Passionné par les produits utiles et robustes.',
      githubUrl: 'https://github.com/HeroNational',
      linkedinUrl: 'https://www.linkedin.com/in/jacobindanielfokou/',
      avatarUrl: AppAssets.portraitJacobin,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final isLight = themeProvider.isLight;
    final currentYear = DateTime.now().year;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.background7,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 960,
                      maxHeight: 820,
                    ),
                    margin: const EdgeInsets.all(28),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.12,
                        ),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, theme),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _buildMetaChip(
                              theme,
                              lucide.LucideIcons.badgeCheck,
                              'Version 1.0.0',
                            ),
                            _buildMetaChip(
                              theme,
                              lucide.LucideIcons.shieldCheck,
                              'Licence MIT',
                            ),
                            _buildMetaChip(
                              theme,
                              lucide.LucideIcons.monitor,
                              'Optimisé macOS',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeroCard(theme, isLight),
                                const SizedBox(height: 18),
                                _buildContributorsBlock(
                                  context,
                                  theme,
                                  isLight,
                                ),
                                const SizedBox(height: 18),
                                _buildLinksBlock(context, theme, isLight),
                                const SizedBox(height: 16),
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        '© $currentYear Xplor — open source sous licence MIT.',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.55),
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Crédits photos : Unsplash (voir assets backgrounds).',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.5),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Fermer'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.92),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
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
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Icon(
            lucide.LucideIcons.info,
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
                'À propos de Xplor',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "L'explorateur de fichiers macOS avec un design glassmorphique et des performances rapides.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(lucide.LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildMetaChip(ThemeData theme, IconData icon, String label) {
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: onSurface.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: onSurface),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme, bool isLight) {
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.2),
            (isLight ? Colors.white : Colors.black).withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: Icon(lucide.LucideIcons.folder, size: 38, color: onSurface),
          ),
          const SizedBox(height: 14),
          Text(
            'Xplor',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Un explorateur de fichiers moderne, pensé pour macOS et construit avec Flutter. Glassmorphisme, animations douces et productivité au quotidien.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: onSurface.withValues(alpha: 0.9),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPill(theme, 'Glass UI'),
              _buildPill(theme, 'Recherche rapide'),
              _buildPill(theme, 'Glisser-déposer'),
              _buildPill(theme, 'Thèmes & palettes'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContributorsBlock(
    BuildContext context,
    ThemeData theme,
    bool isLight,
  ) {
    final hasContributors = _contributors.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contributeurs',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (hasContributors)
          Column(
            children: _contributors
                .map(
                  (contributor) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildContributorCard(context, theme, contributor),
                    ),
                  ),
                )
                .toList(),
          )
        else
          _buildEmptyContributor(theme),
      ],
    );
  }

  Widget _buildContributorCard(
    BuildContext context,
    ThemeData theme,
    Contributor contributor,
  ) {
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: onSurface.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(theme, contributor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contributor.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contributor.role,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                    if (contributor.bio != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        contributor.bio!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onSurface.withValues(alpha: 0.72),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (contributor.githubUrl != null || contributor.linkedinUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 60),
                  if (contributor.githubUrl != null)
                    _buildIconButton(
                      theme: theme,
                      icon: lucide.LucideIcons.github,
                      onTap: () => _openUrl(context, contributor.githubUrl!),
                      tooltip: 'Profil GitHub',
                    ),
                  if (contributor.linkedinUrl != null)
                    _buildIconButton(
                      theme: theme,
                      icon: lucide.LucideIcons.linkedin,
                      onTap: () => _openUrl(context, contributor.linkedinUrl!),
                      tooltip: 'Profil LinkedIn',
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required ThemeData theme,
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: onSurface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: onSurface.withValues(alpha: 0.16)),
          ),
          child: Icon(icon, size: 16, color: onSurface.withValues(alpha: 0.9)),
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && messenger != null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir le lien.')),
        );
      }
    } catch (_) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir le lien.')),
      );
    }
  }

  Widget _buildAvatar(ThemeData theme, Contributor contributor) {
    final initial = contributor.name.isNotEmpty ? contributor.name[0] : '?';
    final onSurface = theme.colorScheme.onSurface;
    final hasPhoto = contributor.avatarUrl != null;
    return SizedBox(
      width: 56,
      height: 56,
      child: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        foregroundColor: onSurface,
        backgroundImage: hasPhoto ? AssetImage(contributor.avatarUrl!) : null,
        child: hasPhoto
            ? null
            : Text(
                initial.toUpperCase(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyContributor(ThemeData theme) {
    final onSurface = theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: onSurface.withValues(alpha: 0.12)),
      ),
      child: Text(
        'Aucun contributeur listé pour le moment.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: onSurface.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  Widget _buildLinksBlock(BuildContext context, ThemeData theme, bool isLight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Liens utiles',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildLinkCard(
              context: context,
              theme: theme,
              isLight: isLight,
              icon: lucide.LucideIcons.github,
              title: 'Code source',
              subtitle: 'Consultez le dépôt GitHub',
              url: 'https://github.com/gaussssss/xplor',
            ),
            _buildLinkCard(
              context: context,
              theme: theme,
              isLight: isLight,
              icon: lucide.LucideIcons.bug,
              title: 'Signaler un bug',
              subtitle: 'Aidez-nous à améliorer Xplor',
              url: 'https://github.com/gaussssss/xplor/issues',
            ),
            _buildLinkCard(
              context: context,
              theme: theme,
              isLight: isLight,
              icon: lucide.LucideIcons.heart,
              title: 'Soutenir le projet',
              subtitle: 'Contribuez ou partagez vos idées',
              url: 'https://github.com/gaussssss/xplor',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLinkCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isLight,
    required IconData icon,
    required String title,
    required String subtitle,
    required String url,
  }) {
    final onSurface = theme.colorScheme.onSurface;

    return InkWell(
      onTap: () => _openUrl(context, url),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              onSurface.withValues(alpha: 0.05),
              onSurface.withValues(alpha: 0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: onSurface.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: Colors.white),
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
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              lucide.LucideIcons.externalLink,
              size: 18,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(ThemeData theme, String label) {
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
