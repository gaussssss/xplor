import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slideUp;
  int _selectedIndex = 0;

  final List<_HelpSection> _sections = const [
    _HelpSection(
      title: 'Demarrage rapide',
      icon: lucide.LucideIcons.sparkles,
      summary:
          'Prenez en main Xplor en quelques minutes : navigation, recherche, '
          'et actions essentielles.',
      bullets: [
        'Cliquez deux fois pour ouvrir un dossier ou un fichier.',
        'Utilisez la barre de recherche pour filtrer rapidement.',
        'Clic droit pour les actions rapides : ouvrir, partager, renommer.',
      ],
      tips: [
        'Le menu de gauche donne acces aux emplacements systeme.',
        'Les touches flechees naviguent entre les elements.',
      ],
    ),
    _HelpSection(
      title: 'Navigation',
      icon: lucide.LucideIcons.map,
      summary: 'Comprendre les emplacements, favoris et disques.',
      bullets: [
        'Utilisez le fil d Ariane pour remonter rapidement.',
        'Les emplacements speciaux apparaissent dans la colonne de gauche.',
        'Les disques montes sont accessibles depuis la section Disques.',
      ],
      tips: [
        'Vous pouvez redimensionner la colonne de gauche.',
        'Double-cliquez sur un disque pour l ouvrir.',
      ],
    ),
    _HelpSection(
      title: 'Recherche',
      icon: lucide.LucideIcons.search,
      summary: 'Retrouver un fichier par nom, type ou tag.',
      bullets: [
        'Activez la recherche et tapez un mot-cle.',
        'Filtrez par type via la zone Types.',
        'Utilisez les tags pour affiner les resultats.',
      ],
      tips: [
        'La recherche est progressive : les resultats arrivent au fur et a mesure.',
      ],
    ),
    _HelpSection(
      title: 'Previsualisation',
      icon: lucide.LucideIcons.eye,
      summary: 'Voir rapidement le contenu avant d ouvrir.',
      bullets: [
        'La grille affiche un apercu quand c est disponible.',
        'Le menu contextuel propose Previsualiser sur les formats supportes.',
        'Les medias utilisent QuickLook pour les apercus.',
      ],
      tips: ['Si un apercu est indisponible, l icone par defaut est affichee.'],
    ),
    _HelpSection(
      title: 'Archives',
      icon: lucide.LucideIcons.archive,
      summary: 'Ouvrir et extraire les archives.',
      bullets: [
        'Les archives se comportent comme des dossiers.',
        'Vous pouvez extraire via le menu contextuel.',
        'Une barre d outils specifique apparait en vue archive.',
      ],
      tips: ['Pensez a verifier l espace disque avant une extraction lourde.'],
    ),
    _HelpSection(
      title: 'Chiffrement',
      icon: lucide.LucideIcons.lock,
      summary: 'Proteger des fichiers et dossiers avec une cle.',
      bullets: [
        'Choisissez une cle et confirmez-la lors du verrouillage.',
        'Gardez la cle en securite : elle n est pas stockee.',
        'Un badge apparait sur les elements verrouilles.',
      ],
      tips: ['Vous pouvez copier ou partager la cle apres verrouillage.'],
    ),
    _HelpSection(
      title: 'Personnalisation',
      icon: lucide.LucideIcons.palette,
      summary: 'Adaptez le theme et l apparence de l application.',
      bullets: [
        'Selectionnez Clair, Sombre ou Auto dans le menu.',
        'Activez les options d apparence via les reglages.',
      ],
      tips: ['Le theme adaptatif suit le mode du systeme.'],
    ),
    _HelpSection(
      title: 'Raccourcis',
      icon: lucide.LucideIcons.keyboard,
      summary: 'Gagner du temps avec les raccourcis clavier.',
      bullets: [
        'Cmd + C / Cmd + V pour copier et coller.',
        'Cmd + F pour ouvrir la recherche.',
        'Retour pour remonter au dossier parent.',
      ],
      tips: ['Les raccourcis s adaptent a la plateforme.'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isLight = themeProvider.isLight;
    final hasBgImage = themeProvider.hasBackgroundImage;
    final bgImage = themeProvider.backgroundImageProvider;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          if (hasBgImage && bgImage != null)
            Positioned.fill(
              child: Image(image: bgImage, fit: BoxFit.cover),
            ),
          if (hasBgImage)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: isLight ? 0.15 : 0.35),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slideUp,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 900;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HelpHeader(
                            isLight: isLight,
                            onBack: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: _HelpBody(
                              isLight: isLight,
                              isNarrow: isNarrow,
                              sections: _sections,
                              selectedIndex: _selectedIndex,
                              onSelect: (index) {
                                setState(() => _selectedIndex = index);
                              },
                              colorScheme: colorScheme,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (themeProvider.useGlassmorphism)
            Positioned.fill(
              child: IgnorePointer(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: themeProvider.blurIntensity,
                    sigmaY: themeProvider.blurIntensity,
                  ),
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HelpHeader extends StatelessWidget {
  const _HelpHeader({required this.isLight, required this.onBack});

  final bool isLight;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          icon: const Icon(lucide.LucideIcons.arrowLeft),
          onPressed: onBack,
          tooltip: 'Retour',
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Centre d aide',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Documentation utilisateur',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(
                  alpha: isLight ? 0.6 : 0.7,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HelpBody extends StatelessWidget {
  const _HelpBody({
    required this.isLight,
    required this.isNarrow,
    required this.sections,
    required this.selectedIndex,
    required this.onSelect,
    required this.colorScheme,
  });

  final bool isLight;
  final bool isNarrow;
  final List<_HelpSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final panelColor = colorScheme.surface.withValues(alpha: 0.85);
    final borderColor = colorScheme.onSurface.withValues(
      alpha: isLight ? 0.08 : 0.18,
    );

    if (isNarrow) {
      return Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sections.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final section = sections[index];
                final isActive = index == selectedIndex;
                return _HelpTabChip(
                  section: section,
                  isActive: isActive,
                  onTap: () => onSelect(index),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _HelpContentCard(
              section: sections[selectedIndex],
              panelColor: panelColor,
              borderColor: borderColor,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Container(
          width: 240,
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 0.6),
          ),
          padding: const EdgeInsets.all(12),
          child: ListView.separated(
            itemCount: sections.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final section = sections[index];
              final isActive = index == selectedIndex;
              return _HelpTabItem(
                section: section,
                isActive: isActive,
                onTap: () => onSelect(index),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _HelpContentCard(
            section: sections[selectedIndex],
            panelColor: panelColor,
            borderColor: borderColor,
          ),
        ),
      ],
    );
  }
}

class _HelpTabItem extends StatelessWidget {
  const _HelpTabItem({
    required this.section,
    required this.isActive,
    required this.onTap,
  });

  final _HelpSection section;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = isActive
        ? colorScheme.primary.withValues(alpha: 0.12)
        : Colors.transparent;
    final fg = isActive ? colorScheme.primary : colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(section.icon, size: 16, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpTabChip extends StatelessWidget {
  const _HelpTabChip({
    required this.section,
    required this.isActive,
    required this.onTap,
  });

  final _HelpSection section;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = isActive
        ? colorScheme.primary.withValues(alpha: 0.12)
        : colorScheme.surface.withValues(alpha: 0.8);
    final fg = isActive ? colorScheme.primary : colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
              width: 0.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(section.icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(
                section.title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpContentCard extends StatelessWidget {
  const _HelpContentCard({
    required this.section,
    required this.panelColor,
    required this.borderColor,
  });

  final _HelpSection section;
  final Color panelColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 0.6),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            section.summary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'En bref',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...section.bullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bullet,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Conseils',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: section.tips
                .map(
                  (tip) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tip,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              'Besoin d aide ? Contactez-nous depuis A propos.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpSection {
  const _HelpSection({
    required this.title,
    required this.icon,
    required this.summary,
    required this.bullets,
    required this.tips,
  });

  final String title;
  final IconData icon;
  final String summary;
  final List<String> bullets;
  final List<String> tips;
}
