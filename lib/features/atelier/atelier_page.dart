import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_data_provider.dart';
import '../../core/localization/language_provider.dart';
import '../../theme/aziz_colors.dart';
import '../../widgets/optimized_image.dart';
import '../home/shared_components.dart';
import 'models/atelier_model.dart';
import 'photo_tile.dart';

// ══════════════════════════════════════════════════════════════════════════════
// RESPONSIVE (conservé pour compatibilité avec le reste du projet)
// ══════════════════════════════════════════════════════════════════════════════

enum ScreenType { mobile, tablet, desktop }

extension ScreenTypeExtension on double {
  ScreenType get screenType {
    if (this < 768) return ScreenType.mobile;
    if (this < 1024) return ScreenType.tablet;
    return ScreenType.desktop;
  }
}

class ResponsiveConstraints {
  final double width;
  final ScreenType screenType;

  ResponsiveConstraints(this.width) : screenType = width.screenType;

  bool get isMobile => screenType == ScreenType.mobile;
  bool get isTablet => screenType == ScreenType.tablet;
  bool get isDesktop => screenType == ScreenType.desktop;

  double get horizontalPadding {
    return switch (screenType) {
      ScreenType.mobile => 24.0,
      ScreenType.tablet => 48.0,
      ScreenType.desktop => width * 0.12,
    };
  }

  double get photoMaxWidth => isMobile ? 400.0 : 350.0;
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE PRINCIPALE : ATELIER
// ══════════════════════════════════════════════════════════════════════════════

class AtelierPage extends StatelessWidget {
  final VoidCallback onContact;
  const AtelierPage({super.key, required this.onContact});

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final appData = context.watch<AppDataProvider>();
    final photos = appData.atelierPhotos;
    final loading = !appData.isReady;

    final width = MediaQuery.sizeOf(context).width;
    final isMobile = homeIsMobile(context);
    final gutter = homeGutter(context);

    final columns = width < 640 ? 2 : (width < 1100 ? 3 : 4);
    final columnGap = isMobile ? 14.0 : 28.0;
    final tileWidth =
        (width - 2 * gutter - columnGap * (columns - 1)) / columns;
    final tileHeight = tileWidth / 0.8 + PhotoTile.captionHeight;

    return ColoredBox(
      color: AzizColors.lightBackground,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: _BannerSection()),
          SliverToBoxAdapter(child: _IntroSection(onContact: onContact)),
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  EdgeInsets.fromLTRB(gutter, isMobile ? 8 : 24, gutter, 0),
              child: HomeHeading(
                title: context.tr('atelier.gallery_title'),
                subtitle: context.tr('atelier.gallery_subtitle'),
              ),
            ),
          ),
          if (loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 100),
                child: Center(
                  child: CircularProgressIndicator(color: AzizColors.saffron),
                ),
              ),
            )
          else if (photos.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: const _AtelierEmptyState(),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                gutter,
                isMobile ? 32 : 48,
                gutter,
                isMobile ? 72 : 112,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: columnGap,
                  mainAxisSpacing: 32,
                  mainAxisExtent: tileHeight,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => PhotoTile(
                    photo: photos[i],
                    onTap: () => _openLightbox(context, photos, i),
                  ),
                  childCount: photos.length,
                ),
              ),
            ),
          SliverToBoxAdapter(child: _BottomCta(onContact: onContact)),
        ],
      ),
    );
  }
}

void _openLightbox(
  BuildContext context,
  List<AtelierPhoto> photos,
  int initialIndex,
) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.9),
    builder: (_) => _Lightbox(photos: photos, initialIndex: initialIndex),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// BANNIÈRE
// ══════════════════════════════════════════════════════════════════════════════

class _BannerSection extends StatelessWidget {
  const _BannerSection();

  @override
  Widget build(BuildContext context) {
    final bp = homeBreakpoint(context);
    final gutter = homeGutter(context);
    final height = switch (bp) {
      HomeBreakpoint.mobile => 320.0,
      HomeBreakpoint.tablet => 400.0,
      HomeBreakpoint.desktop => 480.0,
    };
    final titleSize = switch (bp) {
      HomeBreakpoint.mobile => 44.0,
      HomeBreakpoint.tablet => 64.0,
      HomeBreakpoint.desktop => 84.0,
    };

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          publishedImage(
            'atelier/banner.jpeg',
            fit: BoxFit.cover,
            memCacheWidth: 1600,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AzizColors.trueIndigoDark.withValues(alpha: 0.35),
                  AzizColors.trueIndigoDark.withValues(alpha: 0.88),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              0,
              gutter,
              bp == HomeBreakpoint.mobile ? 32 : 56,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      context.tr('atelier.title'),
                      style: homeSerif(
                        size: titleSize,
                        color: AzizColors.lightBackground,
                        height: 1.02,
                        letterSpacing: -1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Text(
                      context.tr('atelier.banner_subtitle'),
                      style: homeSans(
                        size: 17,
                        color:
                            AzizColors.lightBackground.withValues(alpha: 0.86),
                        weight: FontWeight.w300,
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// INTRODUCTION + CHIFFRES CLÉS
// ══════════════════════════════════════════════════════════════════════════════

class _IntroSection extends StatelessWidget {
  final VoidCallback onContact;

  const _IntroSection({required this.onContact});

  @override
  Widget build(BuildContext context) {
    final isDesktop = homeIsDesktop(context);
    final text = _IntroText(onContact: onContact);
    const facts = _KeyFacts();

    return HomeBand(
      color: AzizColors.lightBackground,
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: text),
                SizedBox(width: homeColumnGap(context)),
                const Expanded(flex: 5, child: facts),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [text, const SizedBox(height: 56), facts],
            ),
    );
  }
}

class _IntroText extends StatelessWidget {
  final VoidCallback onContact;

  const _IntroText({required this.onContact});

  @override
  Widget build(BuildContext context) {
    final isMobile = homeIsMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('atelier.our_atelier'),
          style: homeSerif(
            size: isMobile ? 34 : 46,
            height: 1.1,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            context.tr('atelier.our_atelier_desc'),
            style: homeSans(size: isMobile ? 16 : 17, height: 1.85),
          ),
        ),
        const SizedBox(height: 40),
        Text(
          context.tr('atelier.philosophy'),
          style: homeSerif(
            size: isMobile ? 24 : 28,
            style: FontStyle.italic,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            context.tr('atelier.philosophy_desc'),
            style: homeSans(size: isMobile ? 16 : 17, height: 1.85),
          ),
        ),
        const SizedBox(height: 40),
        HeroBtn(
          label: context.tr('atelier.contact_cta'),
          leading: const Icon(HomeIcons.email),
          onTap: onContact,
        ),
      ],
    );
  }
}

class _Fact {
  final String value;
  final String label;
  final IconData icon;
  const _Fact(this.value, this.label, this.icon);
}

class _KeyFacts extends StatelessWidget {
  const _KeyFacts();

  @override
  Widget build(BuildContext context) {
    final facts = <_Fact>[
      _Fact('10+', context.tr('atelier.years_exp'),
          Icons.hourglass_top_outlined),
      _Fact('500+', context.tr('atelier.works_created'),
          Icons.brush_outlined),
      _Fact('100%', context.tr('atelier.natural_dyes'), Icons.eco_outlined),
      _Fact('3', context.tr('atelier.generations'),
          Icons.family_restroom_outlined),
    ];

    return Column(
      children: [
        for (var row = 0; row < facts.length; row += 2)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _FactCell(fact: facts[row])),
              const SizedBox(width: 24),
              Expanded(
                child: row + 1 < facts.length
                    ? _FactCell(fact: facts[row + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
      ],
    );
  }
}

class _FactCell extends StatelessWidget {
  final _Fact fact;

  const _FactCell({required this.fact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AzizColors.lightBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fact.value,
            style: homeSerif(
              size: 52,
              color: AzizColors.trueIndigo,
              height: 1.0,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(fact.icon, size: 18, color: AzizColors.trueIndigoLight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fact.label,
                  style: homeSans(
                    size: 14,
                    color: AzizColors.lightTextSecondary,
                    weight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VISITE : bandeau indigo
// ══════════════════════════════════════════════════════════════════════════════

class _BottomCta extends StatelessWidget {
  final VoidCallback onContact;

  const _BottomCta({required this.onContact});

  @override
  Widget build(BuildContext context) {
    final isMobile = homeIsMobile(context);

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.tr('atelier.visit_title'),
          style: homeSerif(
            size: isMobile ? 32 : 46,
            color: AzizColors.lightBackground,
            height: 1.1,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            context.tr('atelier.visit_desc'),
            style: homeSans(
              size: isMobile ? 15.5 : 17,
              color: AzizColors.lightBackground.withValues(alpha: 0.78),
              height: 1.75,
            ),
          ),
        ),
      ],
    );

    // Calendrier : le bouton réserve une visite.
    final button = HeroBtn(
      label: context.tr('atelier.book_appointment'),
      leading: const Icon(Icons.event_available_outlined),
      onTap: onContact,
    );

    return HomeBand(
      color: AzizColors.trueIndigoDark,
      background: const BatikTexture(opacity: 0.09, seed: 44),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text,
                const SizedBox(height: 32),
                SizedBox(width: double.infinity, child: button),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: text),
                const SizedBox(width: 40),
                button,
              ],
            ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ÉTAT VIDE
// ══════════════════════════════════════════════════════════════════════════════

class _AtelierEmptyState extends StatelessWidget {
  const _AtelierEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: AzizColors.lightBorder),
              borderRadius: BorderRadius.circular(kHomeRadius),
            ),
            child: const Icon(
              Icons.photo_camera_back_outlined,
              size: 28,
              color: AzizColors.trueIndigoLight,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('atelier.empty_title'),
            style: homeSerif(size: 26, height: 1.2),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('atelier.empty_desc'),
            style: homeSans(size: 15, height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VISIONNEUSE
// ══════════════════════════════════════════════════════════════════════════════

class _Lightbox extends StatefulWidget {
  final List<AtelierPhoto> photos;
  final int initialIndex;
  const _Lightbox({required this.photos, required this.initialIndex});

  @override
  State<_Lightbox> createState() => _LightboxState();
}

class _LightboxState extends State<_Lightbox> {
  late final PageController _controller;
  late final FocusNode _focusNode;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _prev() {
    if (_current > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _next() {
    if (_current < widget.photos.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = homeIsMobile(context);
    final total = widget.photos.length;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent e) {
        if (e is KeyDownEvent) {
          final key = e.physicalKey;
          if (key == PhysicalKeyboardKey.arrowLeft) {
            _prev();
            return KeyEventResult.handled;
          }
          if (key == PhysicalKeyboardKey.arrowRight) {
            _next();
            return KeyEventResult.handled;
          }
          if (key == PhysicalKeyboardKey.escape) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: SizedBox.expand(
          child: ColoredBox(
            color: AzizColors.trueIndigoDark.withValues(alpha: 0.97),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: total,
                    onPageChanged: (i) => setState(() => _current = i),
                    itemBuilder: (_, i) {
                      final photo = widget.photos[i];
                      final caption = photo.caption;
                      final detail = photo.detail;

                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 96,
                          vertical: isMobile ? 72 : 40,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: OptimizedImage(
                                url: photo.displayImage,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                memCacheWidth: 1600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (caption.isNotEmpty)
                              Text(
                                caption,
                                textAlign: TextAlign.center,
                                style: homeSerif(
                                  size: isMobile ? 22 : 28,
                                  color: AzizColors.lightBackground,
                                  style: FontStyle.italic,
                                  height: 1.25,
                                ),
                              ),
                            if (detail.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 640),
                                child: Text(
                                  detail,
                                  textAlign: TextAlign.center,
                                  style: homeSans(
                                    size: isMobile ? 14 : 16,
                                    color: AzizColors.lightBackground
                                        .withValues(alpha: 0.8),
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Text(
                              '${_current + 1} / $total',
                              style: homeSans(
                                size: 13,
                                color: AzizColors.saffronLight,
                                weight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (!isMobile) ...[
                  Positioned(
                    left: 24,
                    child: HomeCircleBtn(
                      icon: HomeIcons.back,
                      onDark: true,
                      semanticLabel:
                          homeText(context, fr: 'Photo précédente', en: 'Previous photo'),
                      onTap: _current > 0 ? _prev : null,
                    ),
                  ),
                  Positioned(
                    right: 24,
                    child: HomeCircleBtn(
                      icon: HomeIcons.next,
                      onDark: true,
                      semanticLabel:
                          homeText(context, fr: 'Photo suivante', en: 'Next photo'),
                      onTap: _current < total - 1 ? _next : null,
                    ),
                  ),
                ],
                Positioned(
                  top: 20,
                  right: 20,
                  child: HomeCircleBtn(
                    icon: Icons.close_rounded,
                    onDark: true,
                    semanticLabel: homeText(context, fr: 'Fermer', en: 'Close'),
                    onTap: () => Navigator.of(context).pop(),
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