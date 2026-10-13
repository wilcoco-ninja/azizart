import 'package:flutter/material.dart';

import '../../theme/aziz_colors.dart';
import '../../widgets/optimized_image.dart';
import '../home/shared_components.dart';
import '../media/models/media_model.dart';

/// Carte média : miniature à angles droits, type et titre lisibles, lien
/// externe signalé par une flèche sortante.
class MediaCard extends StatefulWidget {
  final MediaItem item;
  final bool isEn;
  final VoidCallback onTap;

  const MediaCard({
    super.key,
    required this.item,
    required this.isEn,
    required this.onTap,
  });

  /// Rayon commun aux tuiles image de l'app.
  static const double radius = kHomeRadius;

  static const double horizontalLayoutHeight = 144;
  static const double verticalLayoutHeight = 372;

  @override
  State<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<MediaCard> {
  bool _hovered = false;

  static const double _verticalLayoutMinHeight = 220;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final thumb = item.displayThumb;
    final title = widget.isEn && item.titleEn.isNotEmpty
        ? item.titleEn
        : item.titleFr;
    final radius = BorderRadius.circular(MediaCard.radius);

    return Semantics(
      button: true,
      enabled: item.url.isNotEmpty,
      label: title,
      hint: widget.isEn ? 'Open media link' : 'Ouvrir le lien du média',
      child: MouseRegion(
        cursor:
            item.url.isNotEmpty ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AzizColors.mat,
            borderRadius: radius,
            border: Border.all(
              color: _hovered
                  ? AzizColors.trueIndigoLight
                  : AzizColors.lightBorder,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : const [],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final horizontal =
                      constraints.maxHeight < _verticalLayoutMinHeight;
                  return horizontal
                      ? _buildHorizontal(item, thumb, title)
                      : _buildVertical(item, thumb, title);
                },
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: widget.onTap),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontal(MediaItem item, String thumb, String title) => Row(
        children: [
          SizedBox(
            width: 128,
            height: double.infinity,
            child: _Thumb(thumb: thumb, type: item.type, hovered: _hovered),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: _CardInfo(
                item: item,
                title: title,
                showDescription: false,
              ),
            ),
          ),
        ],
      );

  Widget _buildVertical(MediaItem item, String thumb, String title) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 190,
            child: _Thumb(thumb: thumb, type: item.type, hovered: _hovered),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _CardInfo(
                item: item,
                title: title,
                showDescription: true,
              ),
            ),
          ),
        ],
      );
}

class _Thumb extends StatelessWidget {
  final String thumb;
  final MediaType type;
  final bool hovered;

  const _Thumb({
    required this.thumb,
    required this.type,
    required this.hovered,
  });

  @override
  Widget build(BuildContext context) => ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedScale(
              scale: hovered ? 1.04 : 1.0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              child: thumb.isNotEmpty
                  ? OptimizedImage(
                      url: thumb,
                      folder: 'media',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      memCacheWidth: 500,
                      placeholder:
                          const ColoredBox(color: AzizColors.lightSurface),
                      errorWidget: _PlaceholderThumb(type: type),
                    )
                  : _PlaceholderThumb(type: type),
            ),
            // Le type de média est dit par l'icône : lecture, article, film.
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AzizColors.trueIndigoDark.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(kHomeRadius),
                ),
                child: Icon(type.icon, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      );
}

class _PlaceholderThumb extends StatelessWidget {
  final MediaType type;
  const _PlaceholderThumb({required this.type});

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: AzizColors.lightSurface,
        child: Center(
          child: Icon(
            type.icon,
            color: AzizColors.lightTextMuted.withValues(alpha: 0.6),
            size: 40,
          ),
        ),
      );
}

/// « VIDÉO » → « Vidéo » : la casse d'origine reste lisible.
String _sentenceCase(String value) {
  final text = value.trim();
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

Color _labelColor(Color base) {
  final hsl = HSLColor.fromColor(base);
  return hsl.withLightness(hsl.lightness * 0.62).toColor();
}

class _CardInfo extends StatelessWidget {
  final MediaItem item;
  final String title;
  final bool showDescription;

  const _CardInfo({
    required this.item,
    required this.title,
    required this.showDescription,
  });

  @override
  Widget build(BuildContext context) {
    final description = showDescription ? item.getDescription(context) : '';
    final typeColor = _labelColor(item.type.color);
    final source = item.source.trim();
    final year = item.year.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.type.icon, size: 15, color: typeColor),
                const SizedBox(width: 6),
                Text(
                  _sentenceCase(item.type.getLabel(context)),
                  style: homeSans(
                    size: 12.5,
                    color: typeColor,
                    weight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: homeSerif(size: 17, height: 1.3),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: homeSans(
                  size: 13,
                  color: AzizColors.lightTextMuted,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
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
                    color: AzizColors.lightTextSecondary,
                    weight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            if (source.isNotEmpty && year.isNotEmpty) const SizedBox(width: 8),
            if (year.isNotEmpty)
              Text(
                year,
                style: homeSans(
                  size: 12.5,
                  color: AzizColors.lightTextMuted,
                  height: 1.3,
                ),
              ),
            const Spacer(),
            if (item.url.isNotEmpty)
              const Icon(
                HomeIcons.external,
                size: 16,
                color: AzizColors.trueIndigo,
              ),
          ],
        ),
      ],
    );
  }
}