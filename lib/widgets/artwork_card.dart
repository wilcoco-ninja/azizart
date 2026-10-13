import 'package:flutter/material.dart';

import '../features/gallery/models/artwork.dart';
import '../features/home/shared_components.dart';
import '../theme/aziz_colors.dart';
import 'optimized_image.dart';

/// Œuvre sur son passe-partout, avec son cartel (titre, technique, année).
/// L'image n'est jamais recadrée.
class ArtworkCard extends StatefulWidget {
  final Artwork artwork;
  final VoidCallback? onTap;
  final String heroTagPrefix;

  /// Hauteur réservée au cartel sous le cadre.
  static const double labelHeight = 64;

  const ArtworkCard({
    super.key,
    required this.artwork,
    this.onTap,
    this.heroTagPrefix = 'gallery',
  });

  @override
  State<ArtworkCard> createState() => _ArtworkCardState();
}

class _ArtworkCardState extends State<ArtworkCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final artwork = widget.artwork;
    final details = <String>[
      if (artwork.technique.trim().isNotEmpty) artwork.technique.trim(),
      if (artwork.year.trim().isNotEmpty) artwork.year.trim(),
    ].join(', ');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        label: artwork.title,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: HomeMat(
                  raised: _hovered,
                  padding: 12,
                  child: Hero(
                    tag: '${widget.heroTagPrefix}-artwork-${artwork.id}',
                    child: _ArtworkImage(artwork: artwork),
                  ),
                ),
              ),
              SizedBox(
                height: ArtworkCard.labelHeight,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          artwork.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: homeSerif(
                            size: 16.5,
                            style: FontStyle.italic,
                            height: 1.25,
                          ),
                        ),
                        if (details.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            details,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: homeSans(size: 13, height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtworkImage extends StatelessWidget {
  final Artwork artwork;
  const _ArtworkImage({required this.artwork});

  @override
  Widget build(BuildContext context) {
    final src = artwork.displayImage;

    if (src.isEmpty) return const _ImageFallback();

    if (src.startsWith('assets/')) {
      return Image.asset(
        src,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => const _ImageFallback(),
      );
    }

    return OptimizedImage(
      url: src,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      memCacheWidth: 600,
      errorWidget: const _ImageFallback(),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) => Container(
        color: AzizColors.lightSurface,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AzizColors.lightTextSecondary,
          size: 28,
        ),
      );
}