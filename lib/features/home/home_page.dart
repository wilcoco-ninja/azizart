import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../core/localization/language_provider.dart';
import '../../services/media_url_resolver.dart';
import '../../theme/aziz_colors.dart';
import '../../widgets/artwork_card.dart';
import '../../widgets/artwork_viewer.dart';
import '../atelier/models/atelier_model.dart';
import '../gallery/models/artwork.dart';
import '../media/models/media_model.dart';
import 'artist_preview.dart';
import 'explore_section.dart';
import 'featured_section.dart';
import 'footer_section.dart';
import 'hero_section.dart';
import 'models/home_model.dart';
import 'news_events_section.dart';
import 'press_section.dart';
import 'quote_section.dart';
import 'shared_components.dart';
import 'workshop_section.dart';

class HomePage extends StatefulWidget {
  final Function(int) onNavigate;
  final HomeData homeData;
  final List<AtelierPhoto> atelierPhotos;
  final List<MediaItem> mediaItems;
  final ScrollController? scrollController;

  const HomePage({
    super.key,
    required this.onNavigate,
    required this.homeData,
    this.atelierPhotos = const [],
    this.mediaItems = const [],
    this.scrollController,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late _HeroFeed _cachedHeroFeed;

  @override
  void initState() {
    super.initState();
    _cachedHeroFeed = _computeHeroFeed();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.homeData != widget.homeData ||
        oldWidget.atelierPhotos != widget.atelierPhotos) {
      _cachedHeroFeed = _computeHeroFeed();
    }
  }

  _HeroFeed _computeHeroFeed() {
    final images = <String>[];
    final captions = <String>[];

    void add(String image, String caption) {
      final url = image.trim();
      if (url.isEmpty || images.contains(url) || images.length >= 6) return;
      images.add(url);
      captions.add(caption.trim());
    }

    for (final artwork in widget.homeData.featuredArtworks.take(5)) {
      add(artwork.displayImage, artwork.title);
    }
    for (final photo in widget.atelierPhotos) {
      add(photo.displayImage, '');
    }

    if (images.isEmpty) {
      const defaultPaths = <String>[
        'atelier/artist0.jpeg',
        'atelier/artist1.jpeg',
        'atelier/banner.jpeg',
        'atelier/profil.jpeg',
      ];
      for (final path in defaultPaths) {
        add(MediaUrlResolver.resolve(path), '');
      }
    }
    return _HeroFeed(images, captions);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    final width = MediaQuery.sizeOf(context).width;
    final gridLimit = homeGridLimit(homeGridColumns(width));
    final featured = widget.homeData.featuredArtworks;

    final gridWorks = featured.take(gridLimit).toList();
    final gridIds = gridWorks.map((a) => a.id).toSet();
    final spotlightWorks =
        featured.where((a) => !gridIds.contains(a.id)).take(6).toList();

    return ColoredBox(
      color: AzizColors.lightBackground,
      child: CustomScrollView(
        key: const PageStorageKey('aziz_home_scroll'),
        controller: widget.scrollController,
        physics: const ClampingScrollPhysics(),
        scrollCacheExtent: const ScrollCacheExtent.pixels(900.0),
        slivers: [
          SliverToBoxAdapter(
            child: HeroSection(
              key: const ValueKey('home_hero'),
              onNavigate: widget.onNavigate,
              carouselImages: _cachedHeroFeed.images,
              captions: _cachedHeroFeed.captions,
            ),
          ),
          if (gridWorks.isNotEmpty)
            _ShowcaseSliver(
              key: const ValueKey('home_showcase'),
              onNavigate: widget.onNavigate,
              artworks: gridWorks,
            ),
          if (spotlightWorks.isNotEmpty)
            SliverToBoxAdapter(
              child: FeaturedSection(
                key: const ValueKey('home_featured'),
                onNavigate: widget.onNavigate,
                artworks: spotlightWorks,
              ),
            ),
          SliverToBoxAdapter(
            child: WorkshopSection(
              key: const ValueKey('home_workshop'),
              onNavigate: widget.onNavigate,
              atelierPhotos: widget.atelierPhotos,
            ),
          ),
          SliverToBoxAdapter(
            child: ArtistPreviewSection(
              key: const ValueKey('home_artist'),
              onNavigate: widget.onNavigate,
              atelierPhotos: widget.atelierPhotos,
            ),
          ),
          SliverToBoxAdapter(
            child: NewsEventsSection(
              key: const ValueKey('home_news'),
              onNavigate: widget.onNavigate,
            ),
          ),
          if (widget.mediaItems.isNotEmpty)
            SliverToBoxAdapter(
              child: PressSection(
                key: const ValueKey('home_press'),
                onNavigate: widget.onNavigate,
                mediaItems: widget.mediaItems,
              ),
            ),
          const SliverToBoxAdapter(
            child: QuoteSection(key: ValueKey('home_quote')),
          ),
          SliverToBoxAdapter(
            child: ExploreSection(
              key: const ValueKey('home_explore'),
              onNavigate: widget.onNavigate,
            ),
          ),
          const SliverToBoxAdapter(
            child: FooterSection(key: ValueKey('home_footer')),
          ),
        ],
      ),
    );
  }
}

class _HeroFeed {
  final List<String> images;
  final List<String> captions;
  const _HeroFeed(this.images, this.captions);
}

class _ShowcaseSliver extends StatelessWidget {
  final Function(int) onNavigate;
  final List<Artwork> artworks;

  const _ShowcaseSliver({
    super.key,
    required this.onNavigate,
    required this.artworks,
  });

  /// Proportion des cadres (largeur / hauteur).
  static const double _matRatio = 0.8;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = homeGridColumns(width);
    final isMobile = homeIsMobile(context);
    final isEn = homeIsEn(context);
    final allLabel =
        isEn ? 'View full collection' : 'Voir toute la collection';

    final contentWidth =
        math.min(width - 2 * homeHPad(context), kHomeMaxWidth);
    final gutter = (width - contentWidth) / 2;

    const columnGap = 28.0;
    final tileWidth = (contentWidth - columnGap * (columns - 1)) / columns;
    final tileHeight = tileWidth / _matRatio + ArtworkCard.labelHeight;

    final verticalPad = switch (homeBreakpoint(context)) {
      HomeBreakpoint.mobile => 72.0,
      HomeBreakpoint.tablet => 96.0,
      HomeBreakpoint.desktop => 128.0,
    };

    return DecoratedSliver(
      decoration: const BoxDecoration(color: AzizColors.lightBackground),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: verticalPad)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: HomeHeading(
                title: context.tr('home.our_creations'),
                trailing: TextLinkBtn(
                  label: allLabel,
                  onTap: () => onNavigate(1),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: isMobile ? 36 : 56),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 40,
                crossAxisSpacing: columnGap,
                mainAxisExtent: tileHeight,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => ArtworkCard(
                  artwork: artworks[index],
                  heroTagPrefix: 'home',
                  onTap: () => ArtworkViewer.open(
                    context,
                    artworks: artworks,
                    initialIndex: index,
                    isEn: isEn,
                    heroTagPrefix: 'home',
                  ),
                ),
                childCount: artworks.length,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: verticalPad)),
        ],
      ),
    );
  }
}