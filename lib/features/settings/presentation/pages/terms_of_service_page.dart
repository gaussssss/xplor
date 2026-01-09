import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' as lucide;
import 'package:provider/provider.dart';

import '../../../../core/providers/theme_provider.dart';

class TermsOfServicePage extends StatefulWidget {
  const TermsOfServicePage({super.key});

  @override
  State<TermsOfServicePage> createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends State<TermsOfServicePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _bounce;

  static const String _lastUpdated = '3 janvier 2026';

  static const List<_TermsSection> _sections = [
    _TermsSection(
      title: 'Acceptation des conditions',
      body:
          "En utilisant Xplor, vous acceptez d'être lié par ces conditions. Si elles ne vous conviennent pas, veuillez ne pas utiliser l'application.",
    ),
    _TermsSection(
      title: "Licence d'utilisation",
      body:
          "Xplor est open-source sous licence MIT. Vous pouvez l'utiliser, le modifier et le distribuer en respectant cette licence.",
    ),
    _TermsSection(
      title: 'Usage responsable',
      body:
          "Vous restez responsable des actions effectuées dans l'application, notamment la suppression, la modification ou le déplacement de fichiers.",
    ),
    _TermsSection(
      title: 'Données et vie privée',
      body:
          "Xplor ne collecte aucune donnée personnelle. Toutes les opérations sont locales, aucune information n'est transmise à des serveurs externes.",
    ),
    _TermsSection(
      title: 'Limitation de responsabilité',
      body:
          "L'application est fournie telle quelle, sans garantie. Les contributeurs ne peuvent être tenus responsables de pertes de données ou de dommages.",
    ),
    _TermsSection(
      title: 'Modifications',
      body:
          "Les conditions peuvent évoluer. Les mises à jour prendront effet lors de leur publication dans l'application.",
    ),
    _TermsSection(
      title: 'Contact',
      body:
          'Pour toute question, consultez la page À propos ou le dépôt GitHub officiel.',
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
            curve: const Interval(0.12, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _bounce = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
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
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final hasBgImage = themeProvider.hasBackgroundImage;
    final bgImage = themeProvider.backgroundImageProvider;
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
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(image: bgImage, fit: BoxFit.cover),
                ),
              ),
            if (hasBgImage)
              Container(
                color: isLight
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.4),
              ),
            _DecorativeBackdrop(isLight: isLight),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: FadeTransition(
                      opacity: _fade,
                      child: SlideTransition(
                        position: _slideUp,
                        child: Column(
                          children: [
                            _HeaderBar(
                              title: 'Conditions Générales',
                              subtitle: "Cadre d'utilisation de Xplor",
                              onClose: () => Navigator.pop(context),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ScaleTransition(
                                      scale: _bounce,
                                      child: _HeroPanel(
                                        isLight: isLight,
                                        lastUpdated: _lastUpdated,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: const [
                                        _InfoChip(label: 'Open-source MIT'),
                                        _InfoChip(label: 'Local-first'),
                                        _InfoChip(label: 'Aucune collecte'),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    ..._sections.asMap().entries.map(
                                      (entry) => _StaggeredSection(
                                        index: entry.key,
                                        child: _SectionCard(
                                          section: entry.value,
                                          isLight: isLight,
                                        ),
                                        controller: _controller,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ActionBar(
                              isLight: isLight,
                              onClose: () => Navigator.pop(context),
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
    );
  }
}

class _TermsSection {
  const _TermsSection({required this.title, required this.body});

  final String title;
  final String body;
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
            lucide.LucideIcons.fileText,
            color: theme.colorScheme.primary,
            size: 20,
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

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.isLight, required this.lastUpdated});

  final bool isLight;
  final String lastUpdated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final bg = isLight
        ? Colors.white.withValues(alpha: 0.74)
        : Colors.black.withValues(alpha: 0.55);
    final border = onSurface.withValues(alpha: isLight ? 0.1 : 0.2);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.tertiary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  lucide.LucideIcons.scrollText,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Règles claires, transparence totale',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dernière mise à jour : $lastUpdated',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.isLight});

  final _TermsSection section;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final bg = isLight
        ? Colors.white.withValues(alpha: 0.7)
        : Colors.black.withValues(alpha: 0.55);
    final border = onSurface.withValues(alpha: isLight ? 0.08 : 0.2);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    lucide.LucideIcons.dot,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        section.body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          color: onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.isLight, required this.onClose});

  final bool isLight;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final bg = isLight
        ? Colors.white.withValues(alpha: 0.8)
        : Colors.black.withValues(alpha: 0.6);
    final border = onSurface.withValues(alpha: isLight ? 0.1 : 0.2);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            children: [
              Text(
                'Vous avez des questions ?',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: onClose,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                ),
                child: const Text("J'ai compris"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.primary.withValues(alpha: 0.14),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _StaggeredSection extends StatelessWidget {
  const _StaggeredSection({
    required this.index,
    required this.child,
    required this.controller,
  });

  final int index;
  final Widget child;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final start = 0.2 + (index * 0.08);
    final end = (start + 0.4).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    final offset = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(animation);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: offset, child: child),
    );
  }
}

class _DecorativeBackdrop extends StatelessWidget {
  const _DecorativeBackdrop({required this.isLight});

  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -70,
            child: _GlowOrb(
              color: primary,
              intensity: isLight ? 0.16 : 0.26,
              size: 240,
            ),
          ),
          Positioned(
            bottom: -120,
            right: -90,
            child: _GlowOrb(
              color: secondary,
              intensity: isLight ? 0.14 : 0.22,
              size: 260,
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
