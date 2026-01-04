import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/constants/assets.dart';

/// Page des Conditions Générales d'Utilisation
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  static const List<_TosSection> _sections = [
    _TosSection(
      title: "Résumé rapide",
      description:
          "Xplor vous aide à organiser vos fichiers localement. Aucune télémétrie n'est envoyée et vous gardez le contrôle de vos données.",
      bullets: [
        "Vous êtes pleinement responsable des actions menées dans l'application.",
        "Nous ne sommes pas responsables d'un usage malveillant ou non conforme et nous ne le soutenons pas.",
        "Sauvegardez vos données : les actions sur les fichiers sont immédiates et locales.",
      ],
    ),
    _TosSection(
      title: "Usage responsable et conformité",
      description:
          "Utilisez Xplor dans le respect des lois, politiques internes et droits des tiers. L'application n'est pas destinée à contourner des protections ni à automatiser des actions nuisibles.",
      bullets: [
        "Interdiction d'utiliser Xplor pour supprimer, copier ou diffuser des données sans autorisation.",
        "Aucun soutien ni encouragement pour des usages non conformes ou illégaux (projets tiers compris).",
        "Vous devez disposer des autorisations nécessaires avant de manipuler des données sensibles.",
      ],
    ),
    _TosSection(
      title: "Sécurité et risques",
      description:
          "Xplor opère sur vos fichiers locaux. Une mauvaise manipulation peut entraîner perte ou modification de données.",
      bullets: [
        "Aucune garantie de disponibilité, d'exactitude ou d'absence de bugs.",
        "Les développeurs ne peuvent être tenus responsables des dommages directs ou indirects.",
        "Vérifiez toujours vos actions avant de déplacer ou supprimer des éléments.",
      ],
    ),
    _TosSection(
      title: "Données et confidentialité",
      description:
          "L'application fonctionne hors ligne. Elle ne collecte pas vos fichiers ni vos habitudes d'usage.",
      bullets: [
        "Les chemins et contenus restent sur votre machine.",
        "Aucune donnée personnelle n'est envoyée vers des serveurs externes.",
        "En cas d'intégration de services tiers, leurs conditions s'appliquent séparément.",
      ],
    ),
    _TosSection(
      title: "Licence et contributions",
      description:
          "Xplor est distribué sous licence MIT. Vous pouvez l'utiliser, le modifier et contribuer.",
      bullets: [
        "Les contributions doivent respecter la licence MIT et le code de conduite du projet.",
        "Le nom et le logo Xplor ne peuvent pas être utilisés pour se présenter comme partenaire officiel sans accord écrit.",
      ],
    ),
    _TosSection(
      title: "Évolution des conditions",
      description:
          "Nous pouvons mettre à jour ces CGU pour refléter l'évolution du produit ou des exigences légales.",
      bullets: [
        "Les modifications prennent effet dès leur publication dans l'application.",
        "La poursuite de l'utilisation vaut acceptation des nouvelles conditions.",
      ],
    ),
    _TosSection(
      title: "Contact",
      description:
          "Pour toute question, consultez la page \"À propos\" ou ouvrez une issue sur le dépôt GitHub.",
      bullets: [],
    ),
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
          Positioned.fill(
            child: Image.asset(
              AppAssets.background6,
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
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.78),
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
                              theme: theme,
                              icon: lucide.LucideIcons.calendar,
                              label: "Dernière mise à jour : 3 janv. 2026",
                            ),
                            _buildMetaChip(
                              theme: theme,
                              icon: lucide.LucideIcons.shieldCheck,
                              label: "Licence MIT",
                            ),
                            _buildMetaChip(
                              theme: theme,
                              icon: lucide.LucideIcons.hardDrive,
                              label: "Traitement local",
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant
                                  .withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: _sections
                                    .map(
                                      (section) => _buildSectionCard(
                                        context,
                                        section,
                                        theme,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text("J'ai compris"),
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
            lucide.LucideIcons.fileText,
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
                "Conditions Générales d'Utilisation",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Lisez attentivement : votre utilisation de Xplor implique l'acceptation de ces conditions.",
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

  Widget _buildMetaChip({
    required ThemeData theme,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    _TosSection section,
    ThemeData theme,
  ) {
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            section.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.6,
            ),
          ),
          if (section.bullets.isNotEmpty) ...[
            const SizedBox(height: 10),
            Column(
              children: section.bullets
                  .map((bullet) => _buildBulletPoint(theme, bullet))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBulletPoint(ThemeData theme, String text) {
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 2),
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: onSurface.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TosSection {
  const _TosSection({
    required this.title,
    required this.description,
    required this.bullets,
  });

  final String title;
  final String description;
  final List<String> bullets;
}
