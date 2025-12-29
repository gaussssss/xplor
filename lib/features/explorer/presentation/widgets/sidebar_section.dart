import 'package:flutter/material.dart';

class SidebarSection extends StatelessWidget {
  const SidebarSection({
    super.key,
    required this.title,
    required this.items,
    this.compact = false,
  });

  final String title;
  final List<SidebarItem> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            bottom: compact ? 6 : 8,
            left: 6,
            right: 6,
          ),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(letterSpacing: 0.8, color: Colors.white60),
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
    this.trailing,
    this.isActive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isActive;
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({required this.item});

  final SidebarItem item;

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    return ListTile(
      onTap: item.onTap,
      dense: true,
      minLeadingWidth: 0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: Icon(
        item.icon,
        color: item.isActive ? activeColor : Colors.white.withOpacity(0.82),
        size: 20,
      ),
      title: Text(
        item.label,
        style: TextStyle(
          fontWeight: item.isActive ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: item.trailing,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: Colors.white.withOpacity(0.05),
      tileColor: item.isActive ? Colors.white.withOpacity(0.06) : null,
    );
  }
}
