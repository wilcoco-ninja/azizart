import 'package:flutter/material.dart';

import '../theme/responsive.dart';
import 'optimized_image.dart';

class ArtPieceCard extends StatelessWidget {
  final String imageUrl;

  const ArtPieceCard({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Taille de cache calculée sur la largeur réelle du conteneur.
        // OptimizedImage neutralise memCacheWidth sur le Web.
        final cacheWidth = Responsive.getMemCacheWidth(
          context,
          widgetWidth: constraints.maxWidth,
        );

        return OptimizedImage(
          url: imageUrl,
          fit: BoxFit.cover,
          memCacheWidth: cacheWidth,
        );
      },
    );
  }
}