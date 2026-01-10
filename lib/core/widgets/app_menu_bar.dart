import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../features/explorer/presentation/viewmodels/explorer_view_model.dart';
import '../../features/help/presentation/pages/help_page.dart';
import '../../features/settings/presentation/pages/about_page.dart';
import '../../features/settings/presentation/pages/terms_of_service_page.dart';
import '../constants/special_locations.dart';

/// Menu bar natif de l'application Xplor
/// S'intègre nativement sur macOS (menu en haut de l'écran)
/// et Windows/Linux (menu dans la fenêtre)
class AppMenuBar extends StatelessWidget {
  const AppMenuBar({
    super.key,
    required this.child,
    this.onboardingMode = false,
  });

  final Widget child;
  final bool onboardingMode;

  @override
  Widget build(BuildContext context) {
    final vm = _maybeVm(context);
    final state = vm?.state;
    final isListMode = state?.viewMode == ExplorerViewMode.list;
    return PlatformMenuBar(
      menus: _buildMenus(context, vm, isListMode),
      child: child,
    );
  }

  void _notify(BuildContext context, String message) {
    debugPrint(message);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  ExplorerViewModel? _maybeVm(BuildContext context) {
    try {
      return Provider.of<ExplorerViewModel>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  List<PlatformMenuItem> _buildMenus(
    BuildContext context,
    ExplorerViewModel? vm,
    bool isListMode,
  ) {
    final hasVm = vm != null && !onboardingMode;
    return [
      _buildPlacesMenu(context, vm, hasVm),
      _buildSettingsMenu(context),
      _buildTerminalMenu(context, vm, hasVm),
      _buildSupportMenu(context),
    ];
  }

  /// Menu Terminal
  PlatformMenu _buildTerminalMenu(
    BuildContext context,
    ExplorerViewModel? vm,
    bool hasVm,
  ) {
    return PlatformMenu(
      label: 'Terminal',
      menus: [
        PlatformMenuItem(
          label: 'Nouveau terminal',
          shortcut: const SingleActivator(
            LogicalKeyboardKey.keyT,
            meta: true,
            shift: true,
          ),
          onSelected:
              hasVm ? () => vm!.openTerminalHere(vm.state.currentPath) : null,
        ),
        PlatformMenuItem(
          label: 'Ouvrir dans le terminal',
          onSelected:
              hasVm ? () => vm!.openTerminalHere(vm.state.currentPath) : null,
        ),
      ],
    );
  }

  /// Menu Support
  PlatformMenu _buildSupportMenu(BuildContext context) {
    return PlatformMenu(
      label: 'Support',
      menus: [
        PlatformMenuItem(
          label: 'Documentation',
          onSelected: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const HelpCenterPage(),
            ),
          ),
        ),
        PlatformMenuItem(
          label: 'Conditions d’utilisation',
          onSelected: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TermsOfServicePage(),
            ),
          ),
        ),
        PlatformMenuItem(
          label: 'À propos',
          onSelected: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AboutPage(),
            ),
          ),
        ),
        if (PlatformProvidedMenuItem.hasMenu(
          PlatformProvidedMenuItemType.about,
        ))
          const PlatformProvidedMenuItem(
            type: PlatformProvidedMenuItemType.about,
          ),
      ],
    );
  }

  /// Menu Réglages (ouvre le panneau d’apparence pour l’instant)
  PlatformMenu _buildSettingsMenu(BuildContext context) {
    return PlatformMenu(
      label: 'Réglages',
      menus: [
        PlatformMenuItem(
          label: 'Ouvrir les réglages',
          onSelected: () => _notify(
            context,
            'Réglages disponibles dans l’interface (ouvrir le panneau Apparence).',
          ),
        ),
      ],
    );
  }

  /// Menu Emplacements rapides
  PlatformMenu _buildPlacesMenu(
    BuildContext context,
    ExplorerViewModel? vm,
    bool hasVm,
  ) {
    final items = <PlatformMenuItem>[
      PlatformMenuItem(
        label: 'Disques',
        onSelected:
            hasVm ? () => vm!.loadDirectory(SpecialLocations.disks) : null,
      ),
      PlatformMenuItem(
        label: 'Téléchargements',
        onSelected:
            hasVm ? () => vm!.loadDirectory(SpecialLocations.downloads) : null,
      ),
      PlatformMenuItem(
        label: 'Documents',
        onSelected:
            hasVm ? () => vm!.loadDirectory(SpecialLocations.documents) : null,
      ),
      PlatformMenuItem(
        label: 'Bureau',
        onSelected:
            hasVm ? () => vm!.loadDirectory(SpecialLocations.desktop) : null,
      ),
      PlatformMenuItem(
        label: 'Images',
        onSelected:
            hasVm ? () => vm!.loadDirectory(SpecialLocations.pictures) : null,
      ),
      PlatformMenuItem(
        label: 'Corbeille',
        onSelected:
            hasVm ? () => vm!.loadDirectory(SpecialLocations.trash) : null,
      ),
    ];

    return PlatformMenu(
      label: 'Emplacements',
      menus: items,
    );
  }
}
