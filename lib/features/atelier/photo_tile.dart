import 'package:flutter/material.dart';

import '../../theme/aziz_colors.dart';
import '../../widgets/optimized_image.dart';
import '../home/shared_components.dart';
import 'models/atelier_model.dart';

/// Photo d'atelier : image à angles droits, légende visible dessous.
class PhotoTile extends StatefulWidget {
  final AtelierPhoto photo;
  final VoidCallback onTap;

  const PhotoTile({super.key, required this.photo, required this.onTap});

  /// Rayon commun des images (angles presque droits).
  static const double radius = kHomeRadius;

  /// Hauteur réservée à la légende sous l'image.
  static const double captionHeight = 84;

  @override
  State<PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<PhotoTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final caption = widget.photo.caption;
    final detail = widget.photo.detail;
    final radius = BorderRadius.circular(PhotoTile.radius);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Semantics(
        button: true,
        label: caption.isNotEmpty
            ? caption
            : homeText(context, fr: 'Photo de l’atelier', en: 'Studio photo'),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: radius,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedScale(
                        scale: _hovered ? 1.04 : 1.0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        child: OptimizedImage(
                          url: widget.photo.displayImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          memCacheWidth: 700,
                          placeholder:
                              const ColoredBox(color: AzizColors.lightSurface),
                          errorWidget: const _PhotoImageFallback(),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _hovered ? 1.0 : 0.0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AzizColors.mat,
                              borderRadius: radius,
                            ),
                            child: const Icon(
                              HomeIcons.viewLarge,
                              size: 18,
                              color: AzizColors.trueIndigoDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: PhotoTile.captionHeight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (caption.isNotEmpty)
                        Text(
                          caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: homeSerif(
                            size: 16,
                            style: FontStyle.italic,
                            height: 1.3,
                          ),
                        ),
                      if (detail.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          detail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: homeSans(size: 13, height: 1.45),
                        ),
                      ],
                    ],
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

class _PhotoImageFallback extends StatelessWidget {
  const _PhotoImageFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: AzizColors.lightSurface,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: AzizColors.lightTextMuted,
            size: 32,
          ),
        ),
      );
}