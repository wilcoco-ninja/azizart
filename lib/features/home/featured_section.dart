import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/localization/language_provider.dart';
import '../../theme/aziz_colors.dart';
import '../../widgets/artwork_viewer.dart';
import '../../widgets/optimized_image.dart';
import '../gallery/models/artwork.dart';
import 'shared_components.dart';

class FeaturedSection extends StatefulWidget {
  final Function(int) onNavigate;
  final List<Artwork> artworks;

  const FeaturedSection({
    super.key,
    required this.onNavigate,
    required this.artworks,
  });

  @override
  State<FeaturedSection> createState() => _FeaturedSectionState();
}

class _FeaturedSectionState extends State<FeaturedSection> {
  int _index = 0;

  @override
  void didUpdateWidget(FeaturedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.artworks.length) _index = 0;
  }

  void _step(int delta) {
    final count = widget.artworks.length;
    if (count < 2) return;
    setState(() => _index = (_index + delta + count) % count);
  }

  void _openViewer(int index, bool isEn) {
    ArtworkViewer.open(
      context,
      artworks: widget.artworks,
      initialIndex: index,
      isEn: isEn,
    );
  }

  Future<void> _inquire(Artwork artwork, bool isEn) {
    final message = isEn
        ? 'Hello Olga, I am interested in the artwork “${artwork.title}”. '
            'Could you share more details?'
        : 'Bonjour Olga, je suis intéressé(e) par l’œuvre « ${artwork.title} ». '
            'Pouvez-vous me donner plus d’informations ?';
    return homeLaunch(HomeContact.whatsappWith(message));
  }

  @override
  Widget build(BuildContext context) {
    final artworks = widget.artworks;
    if (artworks.isEmpty) return const SizedBox.shrink();

    final isMobile = homeIsMobile(context);
    final isEn = homeIsEn(context);
    final index = math.min(_index, artworks.length - 1);
    final artwork = artworks[index];
    final many = artworks.length > 1;

    final controls = many
        ? _SpotlightControls(
            index: index,
            count: artworks.length,
            onPrevious: () => _step(-1),
            onNext: () => _step(1),
          )
        : null;
    final viewAll = TextLinkBtn(
      label: context.tr('home.view_all'),
      onTap: () => widget.onNavigate(1),
    );

    final media = _SpotlightMedia(
      artwork: artwork,
      index: index,
      isMobile: isMobile,
      onTap: () => _openViewer(index, isEn),
    );
    final details = AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOut,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topLeft,
        children: <Widget>[
          ...previousChildren,
          ?currentChild,
        ],
      ),
      child: _SpotlightDetails(
        key: ValueKey<int>(index),
        artwork: artwork,
        isMobile: isMobile,
        isEn: isEn,
        onInquire: () => _inquire(artwork, isEn),
        onOpen: () => _openViewer(index, isEn),
      ),
    );

    return HomeBand(
      color: AzizColors.lightBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeHeading(
            title: context.tr('home.featured'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                viewAll,
                if (controls != null) ...[
                  SizedBox(width: homeColumnGap(context)),
                  controls,
                ],
              ],
            ),
          ),
          SizedBox(height: isMobile ? 32 : 56),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                media,
                const SizedBox(height: 32),
                details,
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    controls ?? const SizedBox.shrink(),
                    viewAll,
                  ],
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 6, child: media),
                // Espace adaptatif : 40 px (tablette) ou 72 px (desktop).
                SizedBox(width: homeColumnGap(context)),
                Expanded(flex: 5, child: details),
              ],
            ),
        ],
      ),
    );
  }
}

class _SpotlightMedia extends StatelessWidget {
  final Artwork artwork;
  final int index;
  final bool isMobile;
  final VoidCallback onTap;

  const _SpotlightMedia({
    required this.artwork,
    required this.index,
    required this.isMobile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: artwork.title,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: isMobile ? 0.95 : 0.9,
            child: HomeMat(
              raised: true,
              padding: isMobile ? 12 : 24,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                layoutBuilder: (currentChild, previousChildren) => Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ...previousChildren,
                    ?currentChild,
                  ],
                ),
                child: SizedBox.expand(
                  key: ValueKey<int>(index),
                  child: OptimizedImage(
                    url: artwork.displayImage,
                    // Jamais recadrée : l'œuvre est montrée en entier.
                    fit: BoxFit.contain,
                    memCacheWidth: 1200,
                    errorWidget: Container(
                      color: AzizColors.lightSurface,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_rounded,
                        color: AzizColors.lightTextMuted,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Fact {
  final String label;
  final String value;
  const _Fact(this.label, this.value);
}

class _SpotlightDetails extends StatelessWidget {
  final Artwork artwork;
  final bool isMobile;
  final bool isEn;
  final VoidCallback onInquire;
  final VoidCallback onOpen;

  const _SpotlightDetails({
    super.key,
    required this.artwork,
    required this.isMobile,
    required this.isEn,
    required this.onInquire,
    required this.onOpen,
  });

  String _description() {
    final primary = isEn ? artwork.descriptionEn : artwork.descriptionFr;
    final secondary = isEn ? artwork.descriptionFr : artwork.descriptionEn;
    return (primary.trim().isNotEmpty ? primary : secondary).trim();
  }

  @override
  Widget build(BuildContext context) {
    final available = artwork.isAvailable;
    final description = _description();
    final price = artwork.price;
    final priceLabel = (price != null && price > 0)
        ? '${price.toStringAsFixed(0)} €'
        : (isEn ? 'On request' : 'Sur demande');

    final facts = <_Fact>[
      _Fact(
        'Technique',
        artwork.technique.isNotEmpty ? artwork.technique : 'Batik',
      ),
      if (artwork.dimensions.isNotEmpty)
        _Fact('Dimensions', artwork.dimensions),
      if (artwork.year.isNotEmpty)
        _Fact(isEn ? 'Year' : 'Année', artwork.year),
      _Fact(isEn ? 'Price' : 'Prix', priceLabel),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: available ? AzizColors.saffron : AzizColors.terraCotta,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              available
                  ? context.tr('home.available')
                  : context.tr('home.sold'),
              style: homeSans(
                size: 13.5,
                color: AzizColors.lightTextPrimary,
                weight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            if (artwork.category.isNotEmpty) ...[
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  artwork.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: homeSans(
                    size: 13.5,
                    style: FontStyle.italic,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        Text(
          artwork.title,
          style: homeSerif(
            size: isMobile ? 32 : 46,
            height: 1.1,
            letterSpacing: -0.4,
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            description,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: homeSans(size: 15.5, height: 1.75),
          ),
        ],
        const SizedBox(height: 28),
        _SpotlightFacts(facts: facts),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (available)
              HeroBtn(
                label: isEn
                    ? 'Enquire about this piece'
                    : 'Demander cette œuvre',
                leading: const Icon(HomeIcons.inquire),
                onTap: onInquire,
              ),
            GhostBtn(
              label: isEn ? 'View larger' : 'Voir en grand',
              leading: const Icon(HomeIcons.viewLarge),
              onTap: onOpen,
            ),
          ],
        ),
      ],
    );
  }
}

class _SpotlightFacts extends StatelessWidget {
  final List<_Fact> facts;

  const _SpotlightFacts({required this.facts});

  @override
  Widget build(BuildContext context) {
    const line = AzizColors.lightBorder;

    return Column(
      children: [
        for (var i = 0; i < facts.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              border: Border(
                top: const BorderSide(color: line),
                bottom: i == facts.length - 1
                    ? const BorderSide(color: line)
                    : BorderSide.none,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 124,
                  child: Text(
                    facts[i].label,
                    style: homeSans(
                      size: 13.5,
                      color: AzizColors.lightTextMuted,
                      height: 1.4,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    facts[i].value,
                    style: homeSans(
                      size: 15,
                      color: AzizColors.lightTextPrimary,
                      weight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SpotlightControls extends StatelessWidget {
  final int index;
  final int count;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _SpotlightControls({
    required this.index,
    required this.count,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeCircleBtn(
          icon: HomeIcons.back,
          semanticLabel:
              homeText(context, fr: 'Œuvre précédente', en: 'Previous work'),
          onTap: onPrevious,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            '${index + 1} / $count',
            style: homeSans(
              size: 13.5,
              color: AzizColors.lightTextPrimary,
              weight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
        HomeCircleBtn(
          icon: HomeIcons.next,
          semanticLabel:
              homeText(context, fr: 'Œuvre suivante', en: 'Next work'),
          onTap: onNext,
        ),
      ],
    );
  }
}