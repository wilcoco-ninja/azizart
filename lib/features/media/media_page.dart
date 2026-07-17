import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../../core/localization/language_provider.dart';
import '../media/models/media_model.dart';
import '../../theme/aziz_colors.dart';
import '../../widgets/optimized_image.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MediaPage — vidéos, reportages et actualités
//
// FIX vs ancienne version :
//   • Paramètre `mediaItems` (était `mediaList` → undefined_identifier)
//   • Utilise MediaType.news (était MediaType.actualite → undefined)
//   • Plus de références à .color/.icon/.duration/.date inexistants
//     (maintenant ils existent dans le modèle — section info est simplifiée)
//   • CachedNetworkImage pour les vignettes Firebase Storage
// ══════════════════════════════════════════════════════════════════════════════
class MediaPage extends StatefulWidget {
  final List<MediaItem> mediaItems;
  const MediaPage({super.key, required this.mediaItems});

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  MediaType? _filter; // null = tous

  List<MediaItem> get _filtered => _filter == null
      ? widget.mediaItems
      : widget.mediaItems.where((m) => m.type == _filter).toList();

  // FIX : voir contact_page.dart — `canLaunchUrl` n'est pas fiable sur
  // Flutter Web et bloquait l'ouverture des liens (YouTube, articles de
  // presse…) même quand `launchUrl` aurait fonctionné. On tente
  // désormais l'ouverture directement.
  Future<void> _open(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        debugPrint('MediaPage: launchUrl a échoué pour $uri');
      }
    } catch (e) {
      debugPrint('MediaPage: impossible d\'ouvrir $uri — $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final isEn = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    final width = MediaQuery.of(context).size.width;
    final mobile = width < 640;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Bannière ──────────────────────────────────────────────────────
        SliverToBoxAdapter(child: _MediaBanner(isEn: isEn)),

        // ── Filtres (sticky) ──────────────────────────────────────────────
        SliverPersistentHeader(
          pinned: true,
          delegate: _FilterDelegate(
            isEn: isEn,
            selected: _filter,
            onSelected: (f) => setState(() => _filter = f),
          ),
        ),

        // ── Grille ou liste vide ──────────────────────────────────────────
        _filtered.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.video_library_outlined,
                          color: AzizColors.lightTextSecondary, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        isEn ? 'No media available' : 'Aucun média disponible',
                        style: const TextStyle(
                            color: AzizColors.lightTextSecondary, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEn
                            ? 'Video reports and press coverage will appear here.'
                            : 'Les reportages vidéo et les couvertures presse apparaîtront ici.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AzizColors.lightTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            : SliverPadding(
                padding: EdgeInsets.symmetric(
                    horizontal: mobile ? 16 : 40, vertical: 8),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final item = _filtered[i];
                      return _MediaCard(
                          item: item, isEn: isEn, onTap: () => _open(item.url));
                    },
                    childCount: _filtered.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: mobile ? 1 : (width < 1024 ? 2 : 3),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: mobile ? 2.0 : 0.85,
                  ),
                ),
              ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ── Bannière ──────────────────────────────────────────────────────────────────
class _MediaBanner extends StatelessWidget {
  final bool isEn;
  const _MediaBanner({required this.isEn});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(40, 60, 40, 40),
        color: AzizColors.backgroundDark,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isEn ? 'MEDIA & PRESS' : 'MÉDIAS & PRESSE',
              style: const TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 40,
                  fontWeight: FontWeight.w300,
                  color: AzizColors.textPrimary,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(isEn ? 'In the Spotlight' : 'Sous les projecteurs',
              style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 14,
                  color: AzizColors.textSecondary,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          Container(
              width: 60,
              height: 1,
              color: AzizColors.saffron.withValues(alpha: 0.5)),
        ]),
      );
}

// ── Filtre bar (sticky) ───────────────────────────────────────────────────────
class _FilterDelegate extends SliverPersistentHeaderDelegate {
  final bool isEn;
  final MediaType? selected;
  final ValueChanged<MediaType?> onSelected;
  const _FilterDelegate(
      {required this.isEn, required this.selected, required this.onSelected});

  @override
  double get maxExtent => 60;
  @override
  double get minExtent => 60;
  @override
  bool shouldRebuild(_FilterDelegate old) =>
      old.selected != selected || old.isEn != isEn;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlaps) {
    return Container(
      color: AzizColors.backgroundDark,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        _Chip(
            label: isEn ? 'ALL' : 'TOUT',
            selected: selected == null,
            onTap: () => onSelected(null)),
        const SizedBox(width: 8),
        _Chip(
            label: isEn ? 'VIDEOS' : 'VIDÉOS',
            selected: selected == MediaType.video,
            color: MediaType.video.color,
            onTap: () => onSelected(
                selected == MediaType.video ? null : MediaType.video)),
        const SizedBox(width: 8),
        _Chip(
            label: isEn ? 'REPORTS' : 'REPORTAGES',
            selected: selected == MediaType.reportage,
            color: MediaType.reportage.color,
            onTap: () => onSelected(
                selected == MediaType.reportage ? null : MediaType.reportage)),
        const SizedBox(width: 8),
        _Chip(
            label: isEn ? 'NEWS' : 'ACTUALITÉS',
            selected: selected == MediaType.news,
            color: MediaType.news.color,
            onTap: () =>
                onSelected(selected == MediaType.news ? null : MediaType.news)),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap,
      this.color});
  @override
  Widget build(BuildContext ctx) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
              color: selected
                  ? (color ?? AzizColors.saffron).withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected
                      ? (color ?? AzizColors.saffron)
                      : AzizColors.cardBorder,
                  width: 0.5)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: selected
                      ? (color ?? AzizColors.saffron)
                      : AzizColors.textSecondary))));
}

// ── Media Card ────────────────────────────────────────────────────────────────
class _MediaCard extends StatefulWidget {
  final MediaItem item;
  final bool isEn;
  final VoidCallback onTap;
  const _MediaCard(
      {required this.item, required this.isEn, required this.onTap});
  @override
  State<_MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<_MediaCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final mobile = MediaQuery.of(context).size.width < 640;
    final thumb = item.displayThumb;
    final title =
        widget.isEn && item.titleEn.isNotEmpty ? item.titleEn : item.titleFr;

    return MouseRegion(
      cursor:
          item.url.isNotEmpty ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
              color: AzizColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _hovered
                      ? item.type.color.withValues(alpha: 0.5)
                      : AzizColors.cardBorder,
                  width: _hovered ? 1 : 0.5),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                          color: item.type.color.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 6))
                    ]
                  : []),
          child: mobile
              ? _buildHorizontal(item, thumb, title)
              : _buildVertical(item, thumb, title),
        ),
      ),
    );
  }

  // Layout horizontal (mobile)
  Widget _buildHorizontal(MediaItem item, String thumb, String title) =>
      Row(children: [
        ClipRRect(
          borderRadius:
              const BorderRadius.horizontal(left: Radius.circular(11)),
          child: SizedBox(
              width: 120,
              height: double.infinity,
              child: _Thumb(thumb: thumb, type: item.type, hovered: _hovered)),
        ),
        Expanded(
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: _CardInfo(item: item, title: title, isEn: widget.isEn))),
      ]);

  // Layout vertical (desktop)
  Widget _buildVertical(MediaItem item, String thumb, String title) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
          child: SizedBox(
              height: 180,
              child: _Thumb(thumb: thumb, type: item.type, hovered: _hovered)),
        ),
        Expanded(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: _CardInfo(item: item, title: title, isEn: widget.isEn))),
      ]);
}

class _Thumb extends StatelessWidget {
  final String thumb;
  final MediaType type;
  final bool hovered;
  const _Thumb(
      {required this.thumb, required this.type, required this.hovered});
  @override
  Widget build(BuildContext ctx) => Stack(fit: StackFit.expand, children: [
        // Image
        AnimatedScale(
            scale: hovered ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 250),
            child: thumb.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: thumb,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AzizColors.backgroundMedium),
                    errorWidget: (_, __, ___) => _PlaceholderThumb(type: type))
                : thumb.isNotEmpty
                    ? OptimizedImage(
                        assetPath: thumb,
                        fit: BoxFit.cover,
                        errorWidget: _PlaceholderThumb(type: type))
                    : _PlaceholderThumb(type: type)),
        // Overlay play/article icon
        Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.55)
              ])),
        ),
        Positioned(
            bottom: 10,
            right: 10,
            child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.9),
                    shape: BoxShape.circle),
                child: Icon(type.icon, color: Colors.white, size: 16))),
      ]);
}

class _PlaceholderThumb extends StatelessWidget {
  final MediaType type;
  const _PlaceholderThumb({required this.type});
  @override
  Widget build(BuildContext ctx) => Container(
      color: AzizColors.backgroundMedium,
      child: Center(
          child: Icon(type.icon,
              color: type.color.withValues(alpha: 0.4), size: 40)));
}

class _CardInfo extends StatelessWidget {
  final MediaItem item;
  final String title;
  final bool isEn;
  const _CardInfo(
      {required this.item, required this.title, required this.isEn});
  @override
  Widget build(BuildContext ctx) {
    final description = item.getDescription(ctx);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Badge type
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: item.type.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3)),
              child: Text(item.type.getLabel(ctx),
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: item.type.color))),
          const SizedBox(height: 8),
          // Titre
          // FIX : maxLines réduit de 3 à 2 pour laisser la place à la
          // description ci-dessous sans risquer un débordement.
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AzizColors.textPrimary,
                  height: 1.35)),
          // FIX : sous-titre/description — présent dans les données
          // (subtitleFr/subtitleEn du JSON) mais jamais affiché avant.
          // Une seule ligne avec ellipsis pour rester sûr dans une
          // carte de taille fixe.
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11,
                    color: AzizColors.textSecondary,
                    height: 1.2)),
          ],
        ]),
        // Pied de carte : source + année
        Row(children: [
          if (item.source.isNotEmpty) ...[
            Expanded(
                child: Text(item.source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10, color: AzizColors.textSecondary))),
          ],
          if (item.year.isNotEmpty)
            Text(item.year,
                style: const TextStyle(
                    fontSize: 10, color: AzizColors.textSecondary)),
          if (item.url.isNotEmpty) ...[
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new,
                size: 12, color: AzizColors.textSecondary),
          ],
        ]),
      ],
    );
  }
}
