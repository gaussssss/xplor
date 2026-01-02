import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

/// Breadcrumb bar compact (32px hauteur - Windows 11 style)
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
    return SizedBox(
      height: DesignTokens.breadcrumbHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _BreadcrumbChip(
              label: Platform.isWindows ? 'PC' : '~',
              onTap: () => onNavigate(_root()),
              isFirst: true,
            ),
            for (int i = 0; i < segments.length; i++) ...[
              _BreadcrumbSeparator(),
              _BreadcrumbChip(
                label: segments[i].label,
                onTap: () => onNavigate(segments[i].path),
              ),
            ],
          ],
        ),
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

/// Séparateur entre les breadcrumbs
class _BreadcrumbSeparator extends StatelessWidget {
  const _BreadcrumbSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingXS),
      child: Text(
        '/',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 13,
        ),
      ),
    );
  }
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: DesignTokens.breadcrumbHeight,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.paddingMD,
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
