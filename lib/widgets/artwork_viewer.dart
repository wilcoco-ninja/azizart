import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/gallery/models/artwork.dart';
import '../features/home/shared_components.dart';
import '../theme/aziz_colors.dart';
import 'optimized_image.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ArtworkViewer — visionneuse plein écran : l'œuvre en entier, zoomable, avec
// son cartel (technique, dimensions, prix) et une action pour la demander.
// ══════════════════════════════════════════════════════════════════════════════
class ArtworkViewer extends StatefulWidget {
  final List<Artwork> artworks;
  final int initialIndex;
  final bool isEn;
  final String heroTagPrefix;

  const ArtworkViewer({
    super.key,
    required this.artworks,
    required this.initialIndex,
    required this.isEn,
    this.heroTagPrefix = 'gallery',
  });

  static void open(
    BuildContext context, {
    required List<Artwork> artworks,
    required int initialIndex,
    required bool isEn,
    String heroTagPrefix = 'gallery',
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) => ArtworkViewer(
          artworks: artworks,
          initialIndex: initialIndex,
          isEn: isEn,
          heroTagPrefix: heroTagPrefix,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<ArtworkViewer> createState() => _ArtworkViewerState();
}

class _ArtworkViewerState extends State<ArtworkViewer> {
  late int _index;
  final TransformationController _transformCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  Artwork get _artwork => widget.artworks[_index];
  bool get _hasPrev => _index > 0;
  bool get _hasNext => _index < widget.artworks.length - 1;

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.artworks.length) return;
    setState(() => _index = next);
    _transformCtrl.value = Matrix4.identity();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        Navigator.of(context).pop();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _go(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        _go(-1);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  Future<void> _inquire() {
    final art = _artwork;
    final message = widget.isEn
        ? 'Hello Olga, I am interested in the artwork “${art.title}”. '
            'Could you share more details?'
        : 'Bonjour Olga, je suis intéressé(e) par l’œuvre « ${art.title} ». '
            'Pouvez-vous me donner plus d’informations ?';
    return homeLaunch(HomeContact.whatsappWith(message));
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: AzizColors.trueIndigoDark,
        body: SafeArea(
          child: isWide
              ? Row(
                  children: [
                    Expanded(child: _imageArea(isWide: true)),
                    SizedBox(
                      width: 420,
                      child: ColoredBox(
                        color: AzizColors.lightBackground,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(36, 64, 36, 36),
                          child: _DetailsContent(
                            artwork: _artwork,
                            isEn: widget.isEn,
                            onInquire: _inquire,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: _imageArea(isWide: false)),
                    _MobileInfoSheet(
                      artwork: _artwork,
                      isEn: widget.isEn,
                      onInquire: _inquire,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _imageArea({required bool isWide}) {
    final art = _artwork;
    final count = widget.artworks.length;

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: InteractiveViewer(
              key: ValueKey(art.id),
              transformationController: _transformCtrl,
              minScale: 1,
              maxScale: 4,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 96 : 16,
                  isWide ? 72 : 64,
                  isWide ? 96 : 16,
                  isWide ? 48 : 16,
                ),
                child: Center(
                  child: Hero(
                    tag: '${widget.heroTagPrefix}-artwork-${art.id}',
                    child: _ViewerImage(artwork: art),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: HomeCircleBtn(
            icon: Icons.close_rounded,
            onDark: true,
            semanticLabel: homeText(context, fr: 'Fermer', en: 'Close'),
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        if (count > 1)
          Positioned(
            top: 12,
            right: 16,
            height: 44,
            child: Center(
              child: Text(
                '${_index + 1} / $count',
                style: homeSans(
                  size: 13.5,
                  color: AzizColors.lightBackground.withValues(alpha: 0.8),
                  weight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ),
        if (count > 1) ...[
          Positioned(
            left: isWide ? 24 : 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: HomeCircleBtn(
                icon: HomeIcons.back,
                onDark: true,
                semanticLabel:
                    homeText(context, fr: 'Œuvre précédente', en: 'Previous work'),
                onTap: _hasPrev ? () => _go(-1) : null,
              ),
            ),
          ),
          Positioned(
            right: isWide ? 24 : 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: HomeCircleBtn(
                icon: HomeIcons.next,
                onDark: true,
                semanticLabel:
                    homeText(context, fr: 'Œuvre suivante', en: 'Next work'),
                onTap: _hasNext ? () => _go(1) : null,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ViewerImage extends StatelessWidget {
  final Artwork artwork;
  const _ViewerImage({required this.artwork});

  @override
  Widget build(BuildContext context) {
    final src = artwork.displayImage;
    if (src.isEmpty) return const _ViewerFallback();

    if (src.startsWith('assets/')) {
      return Image.asset(
        src,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => const _ViewerFallback(),
      );
    }

    return OptimizedImage(
      url: src,
      // Jamais recadrée : l'œuvre est montrée en entier.
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      memCacheWidth: 1600,
      errorWidget: const _ViewerFallback(),
    );
  }
}

class _ViewerFallback extends StatelessWidget {
  const _ViewerFallback();

  @override
  Widget build(BuildContext context) => Container(
        color: AzizColors.trueIndigo,
        alignment: Alignment.center,
        child: Icon(
          Icons.broken_image_outlined,
          color: AzizColors.lightBackground.withValues(alpha: 0.5),
          size: 40,
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// MOBILE : cartel sous l'image (ne la recouvre jamais)
// ══════════════════════════════════════════════════════════════════════════════

class _MobileInfoSheet extends StatefulWidget {
  final Artwork artwork;
  final bool isEn;
  final Future<void> Function() onInquire;

  const _MobileInfoSheet({
    required this.artwork,
    required this.isEn,
    required this.onInquire,
  });

  @override
  State<_MobileInfoSheet> createState() => _MobileInfoSheetState();
}

class _MobileInfoSheetState extends State<_MobileInfoSheet> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant _MobileInfoSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artwork.id != widget.artwork.id) {
      setState(() => _expanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final art = widget.artwork;
    final isEn = widget.isEn;

    return Container(
      decoration: const BoxDecoration(
        color: AzizColors.lightBackground,
        border: Border(top: BorderSide(color: AzizColors.lightBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            art.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: homeSerif(
                              size: 19,
                              style: FontStyle.italic,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _Availability(
                            available: art.isAvailable,
                            isEn: isEn,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      color: AzizColors.trueIndigo,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              alignment: Alignment.topCenter,
              child: _expanded
                  ? ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        child: _DetailsContent(
                          artwork: art,
                          isEn: isEn,
                          onInquire: widget.onInquire,
                          showTitleBlock: false,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CARTEL
// ══════════════════════════════════════════════════════════════════════════════

class _DetailsContent extends StatelessWidget {
  final Artwork artwork;
  final bool isEn;
  final Future<void> Function() onInquire;
  final bool showTitleBlock;

  const _DetailsContent({
    required this.artwork,
    required this.isEn,
    required this.onInquire,
    this.showTitleBlock = true,
  });

  String _description() {
    final primary = isEn ? artwork.descriptionEn : artwork.descriptionFr;
    final secondary = isEn ? artwork.descriptionFr : artwork.descriptionEn;
    return (primary.trim().isNotEmpty ? primary : secondary).trim();
  }

  @override
  Widget build(BuildContext context) {
    final art = artwork;
    final price = art.price;
    final priceLabel = (price != null && price > 0)
        ? '${price.toStringAsFixed(0)} €'
        : (isEn ? 'On request' : 'Sur demande');
    final description = _description();

    final facts = <(String, String)>[
      if (art.technique.trim().isNotEmpty) ('Technique', art.technique.trim()),
      if (art.dimensions.trim().isNotEmpty)
        ('Dimensions', art.dimensions.trim()),
      if (art.year.trim().isNotEmpty) (isEn ? 'Year' : 'Année', art.year.trim()),
      (isEn ? 'Price' : 'Prix', priceLabel),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitleBlock) ...[
          _Availability(available: art.isAvailable, isEn: isEn),
          const SizedBox(height: 16),
          Text(
            art.title,
            style: homeSerif(size: 34, height: 1.1, letterSpacing: -0.5),
          ),
          if (art.category.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              art.category.trim(),
              style: homeSerif(
                size: 16,
                color: AzizColors.lightTextMuted,
                style: FontStyle.italic,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 28),
        ],
        for (var i = 0; i < facts.length; i++)
          _FactRow(
            label: facts[i].$1,
            value: facts[i].$2,
            last: i == facts.length - 1,
          ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(description, style: homeSans(size: 15, height: 1.75)),
        ],
        const SizedBox(height: 28),
        if (art.isAvailable)
          HeroBtn(
            label: isEn ? 'Enquire about this piece' : 'Demander cette œuvre',
            leading: const Icon(HomeIcons.inquire),
            onTap: onInquire,
          )
        else
          Text(
            isEn ? 'This piece has been sold.' : 'Cette œuvre est vendue.',
            style: homeSerif(
              size: 16,
              color: AzizColors.lightTextMuted,
              style: FontStyle.italic,
              height: 1.4,
            ),
          ),
      ],
    );
  }
}

class _FactRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _FactRow({
    required this.label,
    required this.value,
    required this.last,
  });

  @override
  Widget build(BuildContext context) {
    const line = BorderSide(color: AzizColors.lightBorder);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(top: line, bottom: last ? line : BorderSide.none),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: homeSans(
                size: 13.5,
                color: AzizColors.lightTextMuted,
                height: 1.4,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
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
    );
  }
}

class _Availability extends StatelessWidget {
  final bool available;
  final bool isEn;

  const _Availability({required this.available, required this.isEn});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
              ? (isEn ? 'Available' : 'Disponible')
              : (isEn ? 'Sold' : 'Vendu'),
          style: homeSans(
            size: 13.5,
            color: AzizColors.lightTextPrimary,
            weight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}