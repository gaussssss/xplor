import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../../explorer/presentation/widgets/glass_panel_v2.dart';
import '../../../../core/providers/theme_provider.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class HelpBlock {
  const HelpBlock({
    required this.title,
    required this.description,
    required this.bullets,
    this.tip,
  });

  final String title;
  final String description;
  final List<String> bullets;
  final String? tip;

  factory HelpBlock.fromJson(Map<String, dynamic> json) {
    return HelpBlock(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      bullets: (json['bullets'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      tip: json['tip'] as String?,
    );
  }
}

class HelpCategory {
  const HelpCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.blocks,
    this.cta,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<HelpBlock> blocks;
  final String? cta;

  factory HelpCategory.fromJson(
    Map<String, dynamic> json, {
    required IconData icon,
  }) {
    return HelpCategory(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      icon: icon,
      blocks: (json['blocks'] as List<dynamic>? ?? const [])
          .map((item) => HelpBlock.fromJson(item as Map<String, dynamic>))
          .toList(),
      cta: json['cta'] as String?,
    );
  }
}

const _fallbackHelpCategories = [
  HelpCategory(
    title: 'Démarrage',
    subtitle: 'Les bases pour prendre l\'app en main sans friction.',
    icon: lucide.LucideIcons.rocket,
    blocks: [
      HelpBlock(
        title: 'Interface principale',
        description: 'Tout est organisé autour de la barre latérale.',
        bullets: [
          'Accédez aux favoris, emplacements et disques en un clic.',
          'Le fil d Ariane vous permet de remonter rapidement.',
          'Passez de la grille à la liste pour changer de densité.',
        ],
        tip: 'Astuce : double-cliquez pour ouvrir un dossier ou un fichier.',
      ),
      HelpBlock(
        title: 'Emplacements spéciaux',
        description: 'Les raccourcis système restent toujours disponibles.',
        bullets: [
          'Récents, Bureau, Documents, Téléchargements, Images.',
          'Les emplacements sont automatiquement résolus si un chemin change.',
        ],
      ),
      HelpBlock(
        title: 'Recherche instantanée',
        description: 'Filtrez sans quitter le dossier.',
        bullets: [
          'Tapez un mot-clé pour filtrer immédiatement.',
          'Combinez avec tags et types pour affiner les résultats.',
        ],
      ),
    ],
  ),
  HelpCategory(
    title: 'Fichiers & dossiers',
    subtitle: 'Sélection, actions rapides, et organisation.',
    icon: lucide.LucideIcons.folder,
    blocks: [
      HelpBlock(
        title: 'Sélection',
        description: 'Sélection simple ou multiple selon le réglage.',
        bullets: [
          'Cliquez une fois pour sélectionner.',
          'Utilisez la sélection multiple si l option est active.',
        ],
      ),
      HelpBlock(
        title: 'Menu contextuel',
        description: 'Toutes les actions essentielles au clic droit.',
        bullets: [
          'Ouvrir, renommer, déplacer, supprimer.',
          'Prévisualiser quand le format le permet.',
          'Copier/couper/coller et duplication rapide.',
        ],
      ),
      HelpBlock(
        title: 'Drag & drop',
        description: 'Déplacez rapidement entre dossiers.',
        bullets: [
          'Glissez des fichiers vers un dossier cible.',
          'Le drop garde la structure du dossier.',
        ],
      ),
    ],
  ),
  HelpCategory(
    title: 'Prévisualisation & médias',
    subtitle: 'Aperçu rapide des contenus avant ouverture.',
    icon: lucide.LucideIcons.playCircle,
    blocks: [
      HelpBlock(
        title: 'Prévisualiser',
        description: 'Le menu contextuel propose l\'aperçu si disponible.',
        bullets: [
          'Documents, PDF, images, audio et vidéo.',
          'L\'aperçu s\'ouvre dans un panneau dédié.',
        ],
      ),
      HelpBlock(
        title: 'Audio',
        description: 'Les pochettes sont récupérées automatiquement.',
        bullets: [
          'MP3 via métadonnées.',
          'Fallback QuickLook si la pochette est manquante.',
        ],
      ),
      HelpBlock(
        title: 'Vidéo',
        description: 'Miniature et aperçu pour confirmer le contenu.',
        bullets: [
          'QuickLook génère les miniatures.',
          'Ouvrir dans le lecteur par défaut si besoin.',
        ],
      ),
    ],
  ),
  HelpCategory(
    title: 'Archives & compression',
    subtitle: 'Explorer, extraire et créer des archives.',
    icon: lucide.LucideIcons.archive,
    blocks: [
      HelpBlock(
        title: 'Ouvrir une archive',
        description: 'Une archive se comporte comme un dossier.',
        bullets: [
          'Naviguez dans le contenu sans extraire.',
          'Copiez ou déplacez un fichier directement.',
        ],
      ),
      HelpBlock(
        title: 'Extraction',
        description: 'Choisissez une destination et gérez les doublons.',
        bullets: [
          'Duplication, remplacement ou conservation.',
          'Option pour ouvrir le dossier après extraction.',
        ],
      ),
      HelpBlock(
        title: 'Compression',
        description: 'Créer un ZIP depuis la sélection.',
        bullets: [
          'Sélectionnez plusieurs éléments.',
          'L\'archive est créée dans le dossier courant.',
        ],
      ),
    ],
  ),
  HelpCategory(
    title: 'Sécurité & chiffrement',
    subtitle: 'Protégez vos fichiers avec une clé de chiffrement.',
    icon: lucide.LucideIcons.lock,
    blocks: [
      HelpBlock(
        title: 'Verrouiller',
        description: 'Choisissez une clé et confirmez-la.',
        bullets: [
          'La clé n\'est pas stockée.',
          'Une icône de cadenas apparaît sur l\'élément.',
        ],
      ),
      HelpBlock(
        title: 'Déverrouiller',
        description: 'Saisissez la clé pour restaurer le contenu.',
        bullets: [
          'Aucune récupération possible sans la clé.',
          'Le fichier retrouve son état original.',
        ],
      ),
      HelpBlock(
        title: 'Conseils',
        description: 'Sécurisez votre clé.',
        bullets: [
          'Utilisez au moins 4 caractères.',
          'Copiez ou partagez la clé si nécessaire.',
        ],
      ),
    ],
  ),
  HelpCategory(
    title: 'Cloud & réseau',
    subtitle: 'Accéder aux drives et dossiers réseau.',
    icon: lucide.LucideIcons.cloud,
    blocks: [
      HelpBlock(
        title: 'Google Drive / OneDrive',
        description: 'Installez l\'application officielle du fournisseur.',
        bullets: [
          'Google Drive crée un disque local après installation.',
          'OneDrive et Dropbox fonctionnent de la même manière.',
          'Le dossier apparaît ensuite dans la section Disques.',
        ],
      ),
      HelpBlock(
        title: 'Partages réseau',
        description: 'Montez un volume réseau via le système.',
        bullets: [
          'macOS : Finder > Aller > Se connecter au serveur.',
          'Windows : Connecter un lecteur réseau.',
          'Une fois monté, le volume apparait dans Xplor.',
        ],
        tip: 'Astuce : vérifiez que le réseau est accessible avant de monter.',
      ),
    ],
    cta:
        'Pour les drives cloud, installez les apps officielles (Google Drive, OneDrive, Dropbox).',
  ),
  HelpCategory(
    title: 'Personnalisation',
    subtitle: 'Adaptez l\'apparence à votre style.',
    icon: lucide.LucideIcons.palette,
    blocks: [
      HelpBlock(
        title: 'Mode clair, sombre, auto',
        description: 'Choisissez le mode depuis le menu latéral.',
        bullets: [
          'Auto suit le thème système.',
          'Clair et sombre sont persistés.',
        ],
      ),
      HelpBlock(
        title: 'Arrière-plans',
        description: 'Choisissez un fond ou un dossier d\'images.',
        bullets: [
          'Images locales personnalisées.',
          'Rotation automatique configurable.',
        ],
      ),
      HelpBlock(
        title: 'Animations',
        description: 'Activez ou désactivez les animations.',
        bullets: [
          'Disponible dans les réglages avancés.',
          'Utile pour améliorer les performances.',
        ],
      ),
    ],
  ),
  HelpCategory(
    title: 'Raccourcis & productivité',
    subtitle: 'Accélérez votre navigation.',
    icon: lucide.LucideIcons.keyboard,
    blocks: [
      HelpBlock(
        title: 'Raccourcis essentiels',
        description: 'Les raccourcis les plus utiles.',
        bullets: [
          'Cmd/Ctrl + C, V, X pour copier, coller, couper.',
          'Cmd/Ctrl + F pour la recherche.',
          'Retour arrière pour remonter.',
        ],
      ),
      HelpBlock(
        title: 'Navigation rapide',
        description: 'Accédez vite aux dossiers récents.',
        bullets: [
          'Utilisez la section Récents.',
          'Le bouton Dernier emplacement revient au dernier dossier.',
        ],
      ),
    ],
  ),
  HelpCategory(
    title: 'Dépannage',
    subtitle: 'Que faire en cas de problème.',
    icon: lucide.LucideIcons.lifeBuoy,
    blocks: [
      HelpBlock(
        title: 'Aperçus indisponibles',
        description: 'Certains formats ne supportent pas les miniatures.',
        bullets: [
          'Essayez l\'ouverture par défaut.',
          'Vérifiez que QuickLook fonctionne sur le système.',
        ],
      ),
      HelpBlock(
        title: 'Accès refusé',
        description: 'Les permissions système peuvent bloquer un dossier.',
        bullets: [
          'Ajoutez l accès dans les réglages système.',
          'Redémarrez l application après autorisation.',
        ],
      ),
      HelpBlock(
        title: 'Indexation',
        description: 'La recherche peut nécessiter un rafraîchissement.',
        bullets: [
          'Rafraîchissez le dossier actif.',
          'Attendez la fin de l\'indexation en arrière-plan.',
        ],
      ),
    ],
  ),
];

const Map<String, IconData> _helpIconMap = {
  'rocket': lucide.LucideIcons.rocket,
  'folder': lucide.LucideIcons.folder,
  'playCircle': lucide.LucideIcons.playCircle,
  'archive': lucide.LucideIcons.archive,
  'lock': lucide.LucideIcons.lock,
  'cloud': lucide.LucideIcons.cloud,
  'palette': lucide.LucideIcons.palette,
  'keyboard': lucide.LucideIcons.keyboard,
  'lifeBuoy': lucide.LucideIcons.lifeBuoy,
  'help': lucide.LucideIcons.helpCircle,
};

class _HelpCenterPageState extends State<HelpCenterPage> {
  int _selectedIndex = 0;
  late final Future<List<HelpCategory>> _helpFuture;

  @override
  void initState() {
    super.initState();
    _helpFuture = _loadHelpContent();
  }

  Future<List<HelpCategory>> _loadHelpContent() async {
    try {
      final raw = await rootBundle.loadString('assets/help/help_content.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final categoriesJson =
          decoded['categories'] as List<dynamic>? ?? const [];
      final categories = categoriesJson
          .map((item) {
            final map = item as Map<String, dynamic>;
            final iconKey = (map['icon'] as String? ?? 'help').trim();
            final icon = _helpIconMap[iconKey] ?? lucide.LucideIcons.helpCircle;
            return HelpCategory.fromJson(map, icon: icon);
          })
          .where((category) => category.title.isNotEmpty)
          .toList();

      return categories;
    } catch (error) {
      debugPrint('Help JSON load failed: $error');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final hasImage = themeProvider.hasBackgroundImage;
    final bgImage = themeProvider.backgroundImageProvider;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          if (hasImage && bgImage != null)
            Positioned.fill(
              child: Image(image: bgImage, fit: BoxFit.cover),
            ),
          const Positioned(top: -140, left: -120, child: _HelpGlow(size: 360)),
          const Positioned(
            bottom: -180,
            right: -160,
            child: _HelpGlow(size: 420),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surface.withValues(alpha: 0.9),
                    theme.colorScheme.surface.withValues(alpha: 0.72),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          SafeArea(
            child: FutureBuilder<List<HelpCategory>>(
              future: _helpFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const _HelpStatusPanel(
                    icon: lucide.LucideIcons.refreshCw,
                    title: 'Chargement de l\'aide',
                    message:
                        'Nous préparons la documentation pour vous guider.',
                  );
                }

                if (snapshot.hasError) {
                  return const _HelpStatusPanel(
                    icon: lucide.LucideIcons.alertTriangle,
                    title: 'Impossible de charger l\'aide',
                    message:
                        'Le fichier JSON n\'a pas pu être chargé. Vérifiez '
                        'assets/help/help_content.json et relancez l\'app.',
                  );
                }

                final categories = snapshot.data ?? const <HelpCategory>[];
                if (categories.isEmpty) {
                  return const _HelpStatusPanel(
                    icon: lucide.LucideIcons.alertTriangle,
                    title: 'Aucune donnée trouvée',
                    message:
                        'Le fichier JSON ne contient pas de sections valides.',
                  );
                }

                final safeIndex = _selectedIndex.clamp(
                  0,
                  categories.length - 1,
                );
                final category = categories[safeIndex];

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _HelpTopBar(
                        title: 'Centre d\'aide',
                        subtitle: 'Documentation utilisateur',
                        onClose: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _HelpNavRail(
                                  categories: categories,
                                  selectedIndex: safeIndex,
                                  onSelected: (index) =>
                                      setState(() => _selectedIndex = index),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: _HelpContentPane(
                                        key: ValueKey(category.title),
                                        category: category,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpTopBar extends StatelessWidget {
  const _HelpTopBar({
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
    return GlassPanelV2(
      level: GlassPanelLevel.tertiary,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.18),
            ),
            child: Icon(
              lucide.LucideIcons.bookOpen,
              size: 18,
              color: theme.colorScheme.primary,
            ),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onClose,
            icon: const Icon(lucide.LucideIcons.x, size: 16),
            label: const Text('Fermer'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.08,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpNavRail extends StatelessWidget {
  const _HelpNavRail({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<HelpCategory> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 240,
      child: GlassPanelV2(
        level: GlassPanelLevel.tertiary,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  lucide.LucideIcons.layers,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Sections',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${categories.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = categories[index];
                  final isActive = index == selectedIndex;
                  return _HelpNavItem(
                    title: item.title,
                    subtitle: item.subtitle,
                    icon: item.icon,
                    isActive: isActive,
                    onTap: () => onSelected(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpNavItem extends StatelessWidget {
  const _HelpNavItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface.withValues(
      alpha: isActive ? 0.9 : 0.6,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : theme.colorScheme.onSurface.withValues(alpha: 0.05),
            width: 0.6,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? activeColor.withValues(alpha: 0.2)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.06),
              ),
              child: Icon(
                icon,
                size: 16,
                color: isActive ? activeColor : textColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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

class _HelpContentPane extends StatelessWidget {
  const _HelpContentPane({super.key, required this.category});

  final HelpCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassPanelV2(
      level: GlassPanelLevel.secondary,
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 820;
          final cardWidth = isWide
              ? (constraints.maxWidth - 16) / 2
              : constraints.maxWidth;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                      ),
                      child: Icon(
                        category.icon,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _HelpHeroCard(category: category),
                const SizedBox(height: 20),
                Column(
                  children: category.blocks
                      .map(
                        (block) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _HelpBlockCard(block: block),
                        ),
                      )
                      .toList(),
                ),
                if (category.cta != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          lucide.LucideIcons.info,
                          size: 18,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            category.cta!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.75,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HelpHeroCard extends StatelessWidget {
  const _HelpHeroCard({required this.category});

  final HelpCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlights = category.blocks
        .take(3)
        .map((block) => block.title)
        .toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.2),
            theme.colorScheme.secondary.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vue rapide',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tout ce qui compte dans cette section, en quelques points clairs.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: highlights
                .map(
                  (label) =>
                      _HelpPill(label: label, color: theme.colorScheme.primary),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _HelpPill extends StatelessWidget {
  const _HelpPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(lucide.LucideIcons.sparkles, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpBlockCard extends StatelessWidget {
  const _HelpBlockCard({required this.block});

  final HelpBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            block.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            block.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 14),
          ...block.bullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    lucide.LucideIcons.chevronRight,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bullet,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.5,
                        fontSize: 13.5,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.72,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (block.tip != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    lucide.LucideIcons.sparkles,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      block.tip!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HelpGlow extends StatelessWidget {
  const _HelpGlow({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.35),
              theme.colorScheme.primary.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpStatusPanel extends StatelessWidget {
  const _HelpStatusPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: GlassPanelV2(
        level: GlassPanelLevel.tertiary,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 320,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
