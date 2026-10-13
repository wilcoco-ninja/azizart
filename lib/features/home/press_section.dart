import 'package:flutter/material.dart';

import '../../theme/aziz_colors.dart';
import '../../widgets/optimized_image.dart';
import '../media/models/media_model.dart';
import 'shared_components.dart';

/// Section « Dans la presse » — alimentée par les médias publiés de type
/// presse. Masquée entièrement s'il n'y en a aucun.
///
/// Pour inclure aussi les documentaires, remplacez le filtre `_pressItems` par :
///   mediaItems.where((m) =>
///       m.type == MediaType.press || m.type == MediaType.documentary)
class PressSection extends StatelessWidget {
  final Function(int) onNavigate;
  final List<MediaItem> mediaItems;

  const PressSection({
    super.key,
    required this.onNavigate,
    required this.mediaItems,
  });

  /// Nombre maximum d'articles affichés (au-delà, le rail est trop long).
  static const int _maxItems = 10;

  List<MediaItem> get _pressItems => mediaItems
      .where((m) => m.type == MediaType.press)
      .take(_maxItems)
      .toList();

  @override
  Widget build(BuildContext context) {
    final items = _pressItems;
    if (items.isEmpty) return const SizedBox.shrink();

    final isMobile = homeIsMobile(context);
    final isEn = homeIsEn(context);
    final cardWidth = isMobile ? 280.0 : 360.0;

    return HomeBand(
      color: AzizColors.lightBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeHeading(
            title: isEn ? 'In the press' : 'Dans la presse',
            trailing: TextLinkBtn(
              label: isEn ? 'All media' : 'Tous les médias',
              onTap: () => onNavigate(3),
            ),
          ),
          SizedBox(height: isMobile ? 32 : 48),
          SizedBox(
            height: 330,
            child: HomeRail(
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: _PressCard(
                      item: item,
                      width: cardWidth,
                      isEn: isEn,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PressCard extends StatelessWidget {
  final MediaItem item;
  final double width;
  final bool isEn;

  const _PressCard({
    required this.item,
    required this.width,
    required this.isEn,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        isEn && item.titleEn.isNotEmpty ? item.titleEn : item.titleFr;
    final imageUrl = item.displayThumb;
    final hasImage = imageUrl.isNotEmpty;
    final year = item.year.trim();
    final source = item.source.trim();
    final link = item.displayUrl;
    final radius = BorderRadius.circular(kHomeRadius);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImage)
          SizedBox(
            height: 180,
            child: ClipRRect(
              borderRadius: radius,
              child: OptimizedImage(
                url: imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 700,
                errorWidget: Container(
                  color: AzizColors.lightCard,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.article_outlined,
                    color: AzizColors.lightTextMuted,
                    size: 40,
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: AzizColors.lightCard,
              borderRadius: radius,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.article_outlined,
              color: AzizColors.lightTextMuted,
              size: 40,
            ),
          ),
        const SizedBox(height: 16),
        if (source.isNotEmpty || link.isNotEmpty) ...[
          Row(
            children: [
              if (source.isNotEmpty)
                Flexible(
                  child: Text(
                    source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: homeSans(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: AzizColors.trueIndigo,
                    ),
                  ),
                ),
              if (link.isNotEmpty) ...[
                const SizedBox(width: 6),
                const Icon(
                  HomeIcons.external,
                  size: 15,
                  color: AzizColors.trueIndigo,
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
        ],
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: homeSerif(size: 18, height: 1.25),
        ),
        if (year.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            year,
            style: homeSans(
              size: 12,
              color: AzizColors.lightTextMuted,
            ),
          ),
        ],
      ],
    );

    // Pas d'URL → carte non cliquable (mais toujours visible).
    if (link.isEmpty) {
      return SizedBox(width: width, child: content);
    }

    return SizedBox(
      width: width,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => homeLaunch(link),
          borderRadius: radius,
          child: content,
        ),
      ),
    );
  }
}