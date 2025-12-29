import 'package:flutter/material.dart';

class SidebarSection extends StatelessWidget {
  const SidebarSection({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<SidebarItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(letterSpacing: 0.8, color: Colors.white70),
          ),
        ),
        ...items.map((item) => _SidebarTile(item: item)),
      ],
    );
  }
}

class SidebarItem {
  const SidebarItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({required this.item});

  final SidebarItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: item.onTap,
      dense: true,
      minLeadingWidth: 0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Icon(item.icon, color: Colors.blueGrey.shade100),
      title: Text(item.label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: Colors.white.withOpacity(0.04),
    );
  }
}
