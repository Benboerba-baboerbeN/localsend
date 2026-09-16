import 'dart:io';

import 'package:flutter/material.dart';

class SkinBackground extends StatelessWidget {
  final String? wallpaperPath;
  final Widget child;

  const SkinBackground({required this.wallpaperPath, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final path = wallpaperPath;
    if (path == null) {
      return child;
    }

    final theme = Theme.of(context);
    final overlayOpacity = theme.brightness == Brightness.dark ? 0.48 : 0.58;

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            cacheWidth: 1920,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => ColoredBox(color: theme.colorScheme.surface),
          ),
        ),
        ColoredBox(color: theme.colorScheme.surface.withValues(alpha: overlayOpacity)),
        child,
      ],
    );
  }
}
