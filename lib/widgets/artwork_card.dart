import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../features/gallery/models/artwork.dart';
import '../theme/aziz_colors.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ArtworkCard — Carte d'œuvre réutilisable (galerie, accueil, etc.)
// ══════════════════════════════════════════════════════════════════════════════
class ArtworkCard extends StatefulWidget {
  final Artwork artwork;
  final VoidCallback? onTap;

  const ArtworkCard({
    super.key,
    required this.artwork,
    this.onTap,
  });

  @override
  State<ArtworkCard> createState() => _ArtworkCardState();
}

class _ArtworkCardState extends State<ArtworkCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onHover(bool hovered) {
    setState(() => _hovered = hovered);
    if (hovered) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final artwork = widget.artwork;

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            decoration: BoxDecoration(
              color: AzizColors.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _hovered
                    ? AzizColors.gold.withValues(alpha: 0.4)
                    : AzizColors.border,
                width: _hovered ? 1 : 0.5,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: AzizColors.gold.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        artwork.hasNetworkImage
                            ? CachedNetworkImage(
                                imageUrl: artwork.imageUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 700,
                                placeholder: (_, __) =>
                                    Container(color: AzizColors.card),
                                errorWidget: (_, __, ___) => Container(
                                  color: AzizColors.card,
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: AzizColors.textMuted,
                                    size: 40,
                                  ),
                                ),
                              )
                            : Image.asset(
                                artwork.imagePath,
                                fit: BoxFit.cover,
                                cacheWidth: 700,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AzizColors.card,
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: AzizColors.textMuted,
                                    size: 40,
                                  ),
                                ),
                              ),
                        // Badge disponibilité
                        Positioned(
                          top: 10,
                          right: 10,
                          child: _AvailabilityBadge(
                              isAvailable: artwork.isAvailable),
                        ),
                      ],
                    ),
                  ),
                ),
                // Infos
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artwork.title,
                        style: const TextStyle(
                          color: AzizColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artwork.category,
                        style: const TextStyle(
                          color: AzizColors.textSecondary,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artwork.dimensions,
                        style: const TextStyle(
                          color: AzizColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;
  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable
            ? AzizColors.gold.withValues(alpha: 0.9)
            : AzizColors.terracotta.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        isAvailable ? 'Disponible' : 'Vendue',
        style: const TextStyle(
          color: AzizColors.background,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
