import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';

/// Page des Conditions Générales d'Utilisation
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
                            lucide.LucideIcons.fileText,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Conditions Générales d\'Utilisation',
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
                      const SizedBox(height: 8),
                      Text(
                        'Dernière mise à jour: 3 janvier 2026',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Contenu scrollable
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (isLight ? Colors.black : Colors.white).withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSection(
                                  context,
                                  '1. Acceptation des conditions',
                                  'En utilisant Xplor, vous acceptez d\'être lié par ces conditions générales d\'utilisation. Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser l\'application.',
                                ),
                                _buildSection(
                                  context,
                                  '2. Licence d\'utilisation',
                                  'Xplor est un logiciel open-source gratuit. Vous êtes libre de l\'utiliser, de le modifier et de le distribuer selon les termes de la licence MIT.',
                                ),
                                _buildSection(
                                  context,
                                  '3. Utilisation de l\'application',
                                  'Xplor est un explorateur de fichiers conçu pour vous aider à gérer vos fichiers et dossiers. Vous êtes responsable de toutes les actions effectuées dans l\'application, y compris la suppression, la modification ou le déplacement de fichiers.',
                                ),
                                _buildSection(
                                  context,
                                  '4. Collecte de données',
                                  'Xplor ne collecte aucune donnée personnelle. Toutes les opérations sont effectuées localement sur votre appareil. Aucune information n\'est envoyée vers des serveurs externes.',
                                ),
                                _buildSection(
                                  context,
                                  '5. Limitation de responsabilité',
                                  'L\'application est fournie "telle quelle" sans aucune garantie. Les développeurs ne peuvent être tenus responsables de toute perte de données ou dommages résultant de l\'utilisation de l\'application.',
                                ),
                                _buildSection(
                                  context,
                                  '6. Modifications',
                                  'Nous nous réservons le droit de modifier ces conditions à tout moment. Les modifications prendront effet dès leur publication dans l\'application.',
                                ),
                                _buildSection(
                                  context,
                                  '7. Contact',
                                  'Pour toute question concernant ces conditions, veuillez consulter la page "À propos" ou visiter notre dépôt GitHub.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Bouton de fermeture
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: const Text('J\'ai compris'),
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

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
