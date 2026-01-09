part of '../explorer_page.dart';

extension _ExplorerPageNavigation on _ExplorerPageState {
  List<_NavItem> _buildFavoriteItems() {
    final home = Platform.environment['HOME'] ?? Directory.current.parent.path;
    return [
      _NavItem(label: 'Accueil', icon: lucide.LucideIcons.home, path: home),
      _NavItem(
        label: 'Bureau',
        icon: lucide.LucideIcons.monitor,
        path: _join(home, 'Desktop'),
      ),
      _NavItem(
        label: 'Documents',
        icon: lucide.LucideIcons.folderOpen,
        path: _join(home, 'Documents'),
      ),
      _NavItem(
        label: 'Telechargements',
        icon: lucide.LucideIcons.download,
        path: _join(home, 'Downloads'),
      ),
    ];
  }

  List<_NavItem> _buildSystemItems(String initialPath) {
    return [
      _NavItem(
        label: 'Bureau',
        icon: lucide.LucideIcons.monitor,
        path: SpecialLocations.desktop,
      ),
      _NavItem(
        label: 'Documents',
        icon: lucide.LucideIcons.fileText,
        path: SpecialLocations.documents,
      ),
      _NavItem(
        label: 'Téléchargements',
        icon: lucide.LucideIcons.download,
        path: SpecialLocations.downloads,
      ),
      _NavItem(
        label: 'Applications',
        icon: lucide.LucideIcons.appWindow,
        path: SpecialLocations.applications,
      ),
      _NavItem(
        label: 'Images',
        icon: lucide.LucideIcons.image,
        path: SpecialLocations.pictures,
      ),
      _NavItem(
        label: 'Corbeille',
        icon: lucide.LucideIcons.trash2,
        path: SpecialLocations.trash,
      ),
    ];
  }

  List<_NavItem> _buildQuickItems() {
    final home = Platform.environment['HOME'] ?? Directory.current.parent.path;
    return [
      _NavItem(label: 'Recents', icon: lucide.LucideIcons.clock3, path: home),
      _NavItem(label: 'Partage', icon: lucide.LucideIcons.share2, path: home),
    ];
  }

  List<_TagItem> _buildTags() {
    return const [
      _TagItem(label: 'Rouge', color: Colors.redAccent),
      _TagItem(label: 'Orange', color: Colors.orangeAccent),
      _TagItem(label: 'Jaune', color: Colors.amberAccent),
      _TagItem(label: 'Vert', color: Colors.lightGreenAccent),
      _TagItem(label: 'Bleu', color: Colors.lightBlueAccent),
      _TagItem(label: 'Violet', color: Colors.purpleAccent),
      _TagItem(label: 'Gris', color: Colors.grey),
      _TagItem(label: 'Important', color: Colors.grey),
      _TagItem(label: 'Bureau', color: Colors.grey),
      _TagItem(label: 'Domicile', color: Colors.grey),
    ];
  }

  Color? _tagColorForPath(String path) {
    final tag = _viewModel.tagForPath(path);
    if (tag == null) return null;
    final match =
        _tagItems.firstWhere((t) => t.label == tag, orElse: () => _TagItem(label: '', color: Colors.transparent));
    return match.label.isEmpty ? null : match.color;
  }

  String _join(String base, String child) {
    if (base.endsWith(Platform.pathSeparator)) return '$base$child';
    return '$base${Platform.pathSeparator}$child';
  }
}
