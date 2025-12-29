import 'dart:io';

import 'package:flutter/material.dart';

class BreadcrumbBar extends StatelessWidget {
  const BreadcrumbBar({
    super.key,
    required this.path,
    required this.onNavigate,
  });

  final String path;
  final void Function(String targetPath) onNavigate;

  @override
  Widget build(BuildContext context) {
    final segments = _segmentsForPath(path);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _BreadcrumbChip(
            label: Platform.isWindows ? 'PC' : 'Disque',
            onTap: () => onNavigate(_root()),
            isFirst: true,
          ),
          for (final segment in segments)
            _BreadcrumbChip(
              label: segment.label,
              onTap: () => onNavigate(segment.path),
            ),
        ],
      ),
    );
  }

  List<_PathSegment> _segmentsForPath(String path) {
    final separator = Platform.pathSeparator;
    final parts = path.split(separator).where((p) => p.isNotEmpty).toList();
    final segments = <_PathSegment>[];
    for (var i = 0; i < parts.length; i++) {
      final subParts = parts.sublist(0, i + 1);
      final segmentPath =
          Platform.isWindows ? subParts.join(separator) : '/${subParts.join(separator)}';
      segments.add(_PathSegment(label: parts[i], path: segmentPath));
    }
    return segments;
  }

  String _root() {
    if (Platform.isWindows) {
      final drive =
          path.contains(':') ? path.split(Platform.pathSeparator).first : 'C:';
      final separator = Platform.pathSeparator;
      return drive.endsWith(separator) ? drive : '$drive$separator';
    }
    return Platform.pathSeparator;
  }
}

class _PathSegment {
  const _PathSegment({required this.label, required this.path});

  final String label;
  final String path;
}

class _BreadcrumbChip extends StatelessWidget {
  const _BreadcrumbChip({
    required this.label,
    required this.onTap,
    this.isFirst = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: isFirst ? 0 : 6),
      child: ActionChip(
        label: Text(label, overflow: TextOverflow.ellipsis),
        onPressed: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        backgroundColor: Colors.white.withOpacity(0.06),
        side: const BorderSide(color: Colors.white12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
