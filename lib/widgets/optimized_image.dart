import 'package:flutter/material.dart';

class OptimizedImage extends StatelessWidget {
  final String assetPath;
  final BoxFit fit;
  final bool lazyLoad;
  final Widget? errorWidget;

  const OptimizedImage({
    super.key,
    required this.assetPath,
    this.fit = BoxFit.cover,
    this.lazyLoad = false,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Vérification simple pour déterminer s'il s'agit d'une image locale ou distante
    final isNetwork =
        assetPath.startsWith('http://') || assetPath.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        assetPath,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              const Center(
                child: Icon(Icons.broken_image, color: Colors.grey),
              );
        },
      );
    }

    // Gestion de l'image locale en Asset
    return Image.asset(
      assetPath,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ??
            const Center(
              child: Icon(Icons.image_not_supported, color: Colors.grey),
            );
      },
    );
  }
}
