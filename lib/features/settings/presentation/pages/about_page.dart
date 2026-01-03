import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';

/// Informations sur un contributeur
class Contributor {
  const Contributor({
    required this.name,
    required this.role,
    this.githubUrl,
    this.avatarUrl,
  });

  final String name;
  final String role;
  final String? githubUrl;
  final String? avatarUrl;
}

/// Page À propos de l'application
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // Liste des contributeurs
  static const List<Contributor> _contributors = [
    Contributor(
      name: 'Claude Sonnet 4.5',
      role: 'Développement principal',
      githubUrl: 'https://github.com/anthropics',
    ),
    // Ajouter d'autres contributeurs ici
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final isLight = themeProvider.isLight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Contenu principal
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
                  margin: const EdgeInsets.all(40),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête
                      Row(
                        children: [
                          Icon(
                            lucide.LucideIcons.info,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'À propos de Xplor',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(lucide.LucideIcons.x),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Contenu scrollable
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Logo et version
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        lucide.LucideIcons.folder,
                                        size: 40,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Xplor',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Version 1.0.0',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Description
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: (isLight ? Colors.black : Colors.white).withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Text(
                                  'Xplor est un explorateur de fichiers moderne avec une interface glassmorphique élégante. '
                                  'Conçu pour macOS avec Flutter, il offre une expérience utilisateur fluide et intuitive '
                                  'pour gérer vos fichiers et dossiers.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.6,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Contributeurs
                              Text(
                                'Contributeurs',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),

                              ..._contributors.map((contributor) => _buildContributorCard(
                                context,
                                contributor,
                                isLight,
                              )),

                              const SizedBox(height: 32),

                              // Liens
                              Text(
                                'Liens utiles',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),

                              _buildLinkCard(
                                context,
                                lucide.LucideIcons.github,
                                'Code source',
                                'Consultez le code sur GitHub',
                                isLight,
                              ),
                              const SizedBox(height: 12),
                              _buildLinkCard(
                                context,
                                lucide.LucideIcons.bug,
                                'Signaler un bug',
                                'Aidez-nous à améliorer Xplor',
                                isLight,
                              ),
                              const SizedBox(height: 12),
                              _buildLinkCard(
                                context,
                                lucide.LucideIcons.heart,
                                'Soutenir le projet',
                                'Contribuez au développement',
                                isLight,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Copyright
                      Center(
                        child: Text(
                          '© 2026 Xplor. Sous licence MIT.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
    );
  }

  Widget _buildContributorCard(BuildContext context, Contributor contributor, bool isLight) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isLight ? Colors.black : Colors.white).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              lucide.LucideIcons.user,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Nom et rôle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contributor.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contributor.role,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          // Lien GitHub
          if (contributor.githubUrl != null)
            IconButton(
              icon: const Icon(lucide.LucideIcons.github),
              onPressed: () {
                // Ouvrir le lien GitHub
              },
              tooltip: 'Voir le profil GitHub',
            ),
        ],
      ),
    );
  }

  Widget _buildLinkCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool isLight,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        // Ouvrir le lien
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (isLight ? Colors.black : Colors.white).withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 16),
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
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              lucide.LucideIcons.externalLink,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
