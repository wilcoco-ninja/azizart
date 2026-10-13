import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_data_provider.dart';
import '../../theme/aziz_colors.dart';
import '../../widgets/optimized_image.dart';
import 'models/home_event_model.dart';
import 'shared_components.dart';

class NewsEventsSection extends StatefulWidget {
  final void Function(int) onNavigate;
  const NewsEventsSection({super.key, required this.onNavigate});

  @override
  State<NewsEventsSection> createState() => _NewsEventsSectionState();
}

class _NewsEventsSectionState extends State<NewsEventsSection> {
  List<HomeEvent> _sortedByRelevance(List<HomeEvent> events) {
    DateTime dateOf(HomeEvent e) =>
        e.eventDate ?? e.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

    final upcoming = events.where(_isUpcoming).toList()
      ..sort((a, b) => dateOf(a).compareTo(dateOf(b)));

    final past = events.where((e) => !_isUpcoming(e)).toList()
      ..sort((a, b) => dateOf(b).compareTo(dateOf(a)));

    return [...upcoming, ...past];
  }

  @override
  Widget build(BuildContext context) {
    final raw =
        context.select<AppDataProvider, List<HomeEvent>>((p) => p.events);

    if (raw.isEmpty) return const SizedBox.shrink();

    final isMobile = homeIsMobile(context);
    final isEn = homeIsEn(context);
    final events = _sortedByRelevance(raw);

    final cardWidth = isMobile ? 310.0 : 400.0;
    final imageHeight = cardWidth * 0.68;
    final railHeight = imageHeight + 208;

    return HomeBand(
      color: AzizColors.lightBackgroundAlt,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 72 : 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: homeGutter(context)),
            child: HomeHeading(
              title: isEn ? 'News & events' : 'Actualités & événements',
            ),
          ),
          SizedBox(height: isMobile ? 32 : 48),
          SizedBox(
            height: railHeight,
            child: HomeRail(
              children: [
                for (var i = 0; i < events.length; i++)
                  Padding(
                    padding: EdgeInsets.only(right: isMobile ? 18 : 28),
                    child: _EventCard(
                      event: events[i],
                      width: cardWidth,
                      imageHeight: imageHeight,
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

class _EventCard extends StatelessWidget {
  final HomeEvent event;
  final double width;
  final double imageHeight;
  final bool isEn;

  const _EventCard({
    required this.event,
    required this.width,
    required this.imageHeight,
    required this.isEn,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        event.eventDate != null ? _formatDate(event.eventDate!, isEn) : '';
    final typeStr = _typeLabel(event.type, isEn);
    final title = event.getTitle(context);
    final description = event.getDescription(context);
    final hasLink = event.externalUrl.isNotEmpty;

    return SizedBox(
      width: width,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: hasLink ? () => homeLaunch(event.externalUrl) : null,
          borderRadius: BorderRadius.circular(kHomeRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (event.imageUrl.isNotEmpty)
                SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(kHomeRadius),
                    child: OptimizedImage(
                      url: event.imageUrl,
                      folder: 'home_events',
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                      errorWidget: Container(
                        color: AzizColors.lightCard,
                        alignment: Alignment.center,
                        child: Icon(
                          event.type.icon,
                          color: AzizColors.lightTextMuted,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (typeStr.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: event.type.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(kHomeRadius),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            event.type.icon,
                            size: 14,
                            color: _badgeForeground(event.type.color),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            typeStr,
                            style: homeSans(
                              size: 12,
                              color: _badgeForeground(event.type.color),
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (dateStr.isNotEmpty)
                    Text(
                      dateStr,
                      style: homeSans(
                        size: 13,
                        color: AzizColors.lightTextMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: homeSerif(size: 20, height: 1.25),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: homeSans(
                    size: 13.5,
                    height: 1.45,
                    color: AzizColors.lightTextMuted,
                  ),
                ),
              ],
              if (hasLink) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEn ? 'Read more' : 'Lire la suite',
                      style: homeSans(
                        size: 13.5,
                        color: AzizColors.trueIndigo,
                        weight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      HomeIcons.external,
                      size: 16,
                      color: AzizColors.trueIndigo,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

const List<String> _monthsFr = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

const List<String> _monthsEn = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _formatDate(DateTime date, bool isEn) {
  final d = date.toLocal();
  final month = (isEn ? _monthsEn : _monthsFr)[d.month - 1];
  if (isEn) return '$month ${d.day}, ${d.year}';
  final day = d.day == 1 ? '1er' : '${d.day}';
  return '$day $month ${d.year}';
}

bool _isUpcoming(HomeEvent event) {
  final date = event.eventDate;
  if (date == null) return false;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return !date.toLocal().isBefore(today);
}

String _typeLabel(HomeEventType type, bool isEn) {
  switch (type) {
    case HomeEventType.event:
      return isEn ? 'Event' : 'Événement';
    case HomeEventType.reportage:
      return isEn ? 'Report' : 'Reportage';
    case HomeEventType.news:
      return isEn ? 'News' : 'Actualité';
  }
}

Color _badgeForeground(Color base) {
  final hsl = HSLColor.fromColor(base);
  return hsl.withLightness(hsl.lightness * 0.62).toColor();
}