import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/language_provider.dart';
import '../../theme/aziz_colors.dart';
import '../home/shared_components.dart';
import '../media/models/media_model.dart';
import 'media_card.dart';

String? _extractYouTubeId(String url) {
  final regExp = RegExp(
    r'(?:youtube\.com/(?:[^/\n]+/[^/\n]+/|(?:v|e(?:mbed)?|shorts)/|.*[?&]v=)|youtu\.be/)([^"&?/\n]{11})',
  );
  return regExp.firstMatch(url)?.group(1);
}

bool _isYouTubeUrl(String url) =>
    url.contains('youtube.com') || url.contains('youtu.be');

class MediaPage extends StatefulWidget {
  final List<MediaItem> mediaItems;
  const MediaPage({super.key, required this.mediaItems});

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  MediaType? _filter;

  List<MediaItem> get _filtered => _filter == null
      ? widget.mediaItems
      : widget.mediaItems.where((m) => m.type == _filter).toList();

  Future<void> _open(String url) async {
    if (url.isEmpty) return;

    Uri? targetUri;

    if (_isYouTubeUrl(url)) {
      final videoId = _extractYouTubeId(url);
      if (videoId != null) {
        targetUri = Uri.tryParse('https://www.youtube.com/watch?v=$videoId');
      }
    }

    targetUri ??= Uri.tryParse(url);

    if (targetUri == null) {
      _showErrorSnackBar();
      return;
    }

    try {
      final launched = await launchUrl(
        targetUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showErrorSnackBar();
      }
    } catch (e) {
      debugPrint('MediaPage: impossible d\'ouvrir $targetUri — $e');
      if (mounted) {
        _showErrorSnackBar();
      }
    }
  }

  void _showErrorSnackBar() {
    final isEn = homeIsEn(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEn
              ? 'Could not open the link. Check your connection and try again.'
              : 'Impossible d’ouvrir le lien. Vérifiez votre connexion puis réessayez.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final isEn = homeIsEn(context);
    final isMobile = homeIsMobile(context);
    final gutter = homeGutter(context);
    final filtered = _filtered;

    final Widget body;
    if (widget.mediaItems.isEmpty) {
      body = SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 96),
          child: _EmptyState(
            isEn: isEn,
            title: isEn
                ? 'No media yet.'
                : 'Aucun média pour le moment.',
            message: isEn
                ? 'Videos and press articles will appear here.'
                : 'Les vidéos et articles de presse apparaîtront ici.',
          ),
        ),
      );
    } else if (filtered.isEmpty) {
      body = SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 96),
          child: _EmptyState(
            isEn: isEn,
            title: isEn
                ? 'Nothing in this category.'
                : 'Rien dans cette catégorie.',
            message: isEn
                ? 'Choose another category, or see all media.'
                : 'Choisissez une autre catégorie, ou voyez tous les médias.',
            onReset: () => setState(() => _filter = null),
          ),
        ),
      );
    } else {
      body = SliverPadding(
        padding: EdgeInsets.fromLTRB(gutter, 32, gutter, 104),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => MediaCard(
              item: filtered[i],
              isEn: isEn,
              onTap: () => _open(filtered[i].displayUrl),
            ),
            childCount: filtered.length,
          ),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: isMobile ? 640 : 380,
            mainAxisExtent: isMobile
                ? MediaCard.horizontalLayoutHeight
                : MediaCard.verticalLayoutHeight,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
        ),
      );
    }

    return ColoredBox(
      color: AzizColors.lightBackground,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                gutter,
                isMobile ? 48 : 72,
                gutter,
                isMobile ? 32 : 48,
              ),
              child: _MediaIntro(isEn: isEn, isMobile: isMobile),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterDelegate(
              isEn: isEn,
              gutter: gutter,
              count: widget.mediaItems.isEmpty ? 0 : filtered.length,
              selected: _filter,
              onSelected: (f) => setState(() => _filter = f),
            ),
          ),
          body,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EN-TÊTE
// ═══════════════════════════════════════════════════════════════════════════

class _MediaIntro extends StatelessWidget {
  final bool isEn;
  final bool isMobile;

  const _MediaIntro({required this.isEn, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            isEn ? 'Media and press' : 'Médias et presse',
            style: homeSerif(
              size: isMobile ? 40 : 64,
              height: 1.04,
              letterSpacing: isMobile ? -0.8 : -1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            isEn
                ? 'Videos, articles and documentaries about the work.'
                : 'Vidéos, articles et documentaires autour de l’œuvre.',
            style: homeSans(size: isMobile ? 15 : 17, height: 1.7),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isEn;
  final String title;
  final String message;
  final VoidCallback? onReset;

  const _EmptyState({
    required this.isEn,
    required this.title,
    required this.message,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: homeSerif(size: 26, height: 1.2)),
          const SizedBox(height: 10),
          Text(message, style: homeSans(size: 15, height: 1.6)),
          if (onReset != null) ...[
            const SizedBox(height: 24),
            GhostBtn(
              label: isEn ? 'See all media' : 'Voir tous les médias',
              leading: const Icon(HomeIcons.gallery),
              onTap: onReset!,
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FILTRES (onglets soulignés)
// ═══════════════════════════════════════════════════════════════════════════

class _FilterDelegate extends SliverPersistentHeaderDelegate {
  final bool isEn;
  final double gutter;
  final int count;
  final MediaType? selected;
  final ValueChanged<MediaType?> onSelected;

  static const double _height = 58;

  const _FilterDelegate({
    required this.isEn,
    required this.gutter,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  @override
  double get maxExtent => _height;
  @override
  double get minExtent => _height;

  @override
  bool shouldRebuild(_FilterDelegate old) =>
      old.selected != selected ||
      old.isEn != isEn ||
      old.count != count ||
      old.gutter != gutter;

  String get _countLabel {
    if (isEn) return count == 1 ? '1 item' : '$count items';
    return count > 1 ? '$count médias' : '$count média';
  }

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlaps) {
    return Container(
      height: _height,
      padding: EdgeInsets.symmetric(horizontal: gutter),
      decoration: BoxDecoration(
        color: AzizColors.lightBackground,
        border: Border(
          bottom: BorderSide(
            color: AzizColors.lightBorder
                .withValues(alpha: overlaps ? 0.9 : 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _Tab(
                  label: isEn ? 'All' : 'Tout',
                  selected: selected == null,
                  onTap: () => onSelected(null),
                ),
                _Tab(
                  label: isEn ? 'Videos' : 'Vidéos',
                  selected: selected == MediaType.video,
                  onTap: () => onSelected(
                    selected == MediaType.video ? null : MediaType.video,
                  ),
                ),
                _Tab(
                  label: isEn ? 'Press' : 'Presse',
                  selected: selected == MediaType.press,
                  onTap: () => onSelected(
                    selected == MediaType.press ? null : MediaType.press,
                  ),
                ),
                _Tab(
                  label: isEn ? 'Documentaries' : 'Documentaires',
                  selected: selected == MediaType.documentary,
                  onTap: () => onSelected(
                    selected == MediaType.documentary
                        ? null
                        : MediaType.documentary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _countLabel,
            style: homeSans(
              size: 13,
              color: AzizColors.lightTextMuted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(right: 26),
          child: Align(
            alignment: Alignment.center,
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    label,
                    style: homeSans(
                      size: 15,
                      color: selected
                          ? AzizColors.lightTextPrimary
                          : AzizColors.lightTextMuted,
                      weight: selected ? FontWeight.w700 : FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 2,
                    color: selected ? AzizColors.saffron : Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}