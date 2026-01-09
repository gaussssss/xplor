import 'package:flutter/material.dart';

class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({
    super.key,
    required this.image,
    required this.imageKey,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 350),
    this.curve = Curves.easeInOut,
  });

  final ImageProvider? image;
  final String? imageKey;
  final BoxFit fit;
  final Alignment alignment;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final provider = image;
    if (provider == null) return const SizedBox.shrink();
    final key = imageKey ?? provider.toString();
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: [
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Container(
        key: ValueKey<String>(key),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: provider,
            fit: fit,
            alignment: alignment,
          ),
        ),
      ),
    );
  }
}
