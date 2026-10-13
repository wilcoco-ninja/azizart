import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/localization/language_provider.dart';
import '../../theme/aziz_colors.dart';
import '../../widgets/optimized_image.dart';
import 'shared_components.dart';

/// Ouverture du site : le nom de la galerie, et une œuvre présentée comme au
/// mur d'un musée (passe-partout blanc + cartel). Une seule séquence d'entrée.
class HeroSection extends StatefulWidget {
  final Function(int) onNavigate;
  final List<String> carouselImages;
  final List<String> captions;

  const HeroSection({
    super.key,
    required this.onNavigate,
    required this.carouselImages,
    this.captions = const [],
  });

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static const Duration _slideDelay = Duration(seconds: 7);

  late final AnimationController _intro;
  late final Animation<double> _nameOneAnim;
  late final Animation<double> _nameTwoAnim;
  late final Animation<double> _taglineAnim;
  late final Animation<double> _actionsAnim;
  late final Animation<double> _frameAnim;
  late final Animation<double> _captionAnim;

  Timer? _timer;
  int _index = 0;
  bool _introStarted = false;
  double _screenHeight = 800;

  @override
  bool get wantKeepAlive => true;

  Animation<double> _interval(double begin, double end) {
    return _intro.drive(
      CurveTween(curve: Interval(begin, end, curve: Curves.easeOutCubic)),
    );
  }

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _nameOneAnim = _interval(0.00, 0.40);
    _nameTwoAnim = _interval(0.10, 0.50);
    _taglineAnim = _interval(0.30, 0.65);
    _actionsAnim = _interval(0.45, 0.80);
    _frameAnim = _interval(0.20, 0.75);
    _captionAnim = _interval(0.60, 1.00);
    _restartTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_introStarted) return;
    _introStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
    }
  }

  @override
  void didUpdateWidget(HeroSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final count = widget.carouselImages.length;
    if (_index >= count) _index = 0;
    if (oldWidget.carouselImages.length != count) _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = null;
    if (widget.carouselImages.length < 2) return;
    _timer = Timer.periodic(_slideDelay, (_) {
      if (!mounted || !_isNearTop()) return;
      setState(() => _index = (_index + 1) % widget.carouselImages.length);
    });
  }

  bool _isNearTop() {
    final position = Scrollable.maybeOf(context)?.position;
    if (position == null || !position.hasPixels) return true;
    return position.pixels < _screenHeight * 1.2;
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    _restartTimer();
  }

  void _step(int delta) {
    final count = widget.carouselImages.length;
    if (count < 2) return;
    _select((_index + delta + count) % count);
  }

  Widget _reveal(Animation<double> animation, Widget child, {double dy = 22}) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = homeClamp01(animation.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * dy),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final size = MediaQuery.sizeOf(context);
    _screenHeight = size.height;
    final width = size.width;
    final bp = homeBreakpoint(context);
    final isWide = bp == HomeBreakpoint.desktop;
    final isMobile = bp == HomeBreakpoint.mobile;
    final hPad = homeGutter(context);
    final count = widget.carouselImages.length;
    final index = count == 0 ? 0 : math.min(_index, count - 1);

    final minHeight = isWide
        ? math.max(620.0, math.min(size.height * 0.88, 960.0))
        : 0.0;

    final text = _buildText(
      context,
      bp: bp,
      isMobile: isMobile,
      width: width,
    );
    final frame = _buildFrame(
      context,
      isWide: isWide,
      isMobile: isMobile,
      size: size,
      index: index,
    );

    return ColoredBox(
      color: AzizColors.trueIndigoDark,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          const Positioned.fill(child: _HeroBackdrop()),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                hPad,
                isWide ? 88 : 72,
                hPad,
                isWide ? 64 : 56,
              ),
              child: Align(
                alignment: isWide ? Alignment.center : Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: kHomeMaxWidth),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(flex: 6, child: text),
                            SizedBox(width: homeColumnGap(context)),
                            Expanded(flex: 5, child: Center(child: frame)),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            text,
                            const SizedBox(height: 48),
                            Center(child: frame),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildText(
    BuildContext context, {
    required HomeBreakpoint bp,
    required bool isMobile,
    required double width,
  }) {
    // Le titre suit le point de rupture réel (cohérent avec la mise en page).
    final titleSize = switch (bp) {
      HomeBreakpoint.mobile => 52.0,
      HomeBreakpoint.tablet => 76.0,
      HomeBreakpoint.desktop => width < 1440 ? 96.0 : 112.0,
    };
    final titleStyle = homeSerif(
      size: titleSize,
      color: AzizColors.lightBackground,
      weight: FontWeight.w400,
      height: 0.96,
      letterSpacing: titleSize * -0.015,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          label: 'AZIZART COLORS',
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _reveal(_nameOneAnim, Text('AZIZART', style: titleStyle), dy: 30),
              Padding(
                padding: EdgeInsets.only(left: titleSize * 0.42),
                child: _reveal(
                  _nameTwoAnim,
                  Text('COLORS', style: titleStyle),
                  dy: 30,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 24 : 32),
        _reveal(
          _taglineAnim,
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isMobile ? 340 : 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('home.tagline'),
                  style: homeSans(
                    size: isMobile ? 15.5 : 17,
                    color: AzizColors.lightBackground.withValues(alpha: 0.86),
                    weight: FontWeight.w300,
                    height: 1.75,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  homeText(
                    context,
                    fr: 'Olga Indigo, artiste batik à Cotonou',
                    en: 'Olga Indigo, batik artist in Cotonou',
                  ),
                  style: homeSerif(
                    size: 16,
                    color: AzizColors.lightBackground.withValues(alpha: 0.7),
                    style: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isMobile ? 28 : 40),
        _reveal(
          _actionsAnim,
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              HeroBtn(
                label: context.tr('home.discover_gallery'),
                leading: const Icon(HomeIcons.gallery),
                onTap: () => widget.onNavigate(1),
              ),
              GhostBtn(
                label: context.tr('home.workshop_cta'),
                color: AzizColors.lightBackground,
                leading: const Icon(HomeIcons.studio),
                onTap: () => widget.onNavigate(2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrame(
    BuildContext context, {
    required bool isWide,
    required bool isMobile,
    required Size size,
    required int index,
  }) {
    final captions = widget.captions;
    final caption = index < captions.length ? captions[index] : '';

    final targetHeight = isWide
        ? math.max(440.0, math.min(size.height * 0.64, 700.0))
        : isMobile
            ? math.max(300.0, math.min(size.height * 0.46, 440.0))
            : math.max(360.0, math.min(size.height * 0.52, 520.0));

    return LayoutBuilder(
      builder: (context, constraints) {
        var frameWidth = targetHeight * 0.8;
        var frameHeight = targetHeight;
        if (constraints.maxWidth.isFinite && frameWidth > constraints.maxWidth) {
          frameWidth = constraints.maxWidth;
          frameHeight = frameWidth / 0.8;
        }

        return SizedBox(
          width: frameWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _reveal(
                _frameAnim,
                SizedBox(
                  width: frameWidth,
                  height: frameHeight,
                  child: HomeMat(
                    raised: true,
                    padding: isMobile ? 10 : 16,
                    child: _buildSlides(index, caption),
                  ),
                ),
                dy: 18,
              ),
              const SizedBox(height: 14),
              _reveal(_captionAnim, _buildCaptionRow(index, caption), dy: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlides(int index, String caption) {
    final images = widget.carouselImages;
    const fallback =
        SizedBox.expand(child: ColoredBox(color: AzizColors.lightSurface));

    final Widget currentSlide = images.isEmpty
        ? fallback
        : OptimizedImage(
            url: images[index],
            // Jamais recadrée : l'œuvre est montrée en entier.
            fit: BoxFit.contain,
            memCacheWidth: 1200,
            errorWidget: fallback,
          );

    return Semantics(
      image: true,
      label: caption.isEmpty ? 'AZIZART COLORS' : caption,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ...previousChildren,
            ?currentChild,
          ],
        ),
        child: SizedBox.expand(
          key: ValueKey<int>(index),
          child: currentSlide,
        ),
      ),
    );
  }

  /// Cartel : titre de l'œuvre à gauche, navigation à droite.
  Widget _buildCaptionRow(int index, String caption) {
    final count = widget.carouselImages.length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: AnimatedOpacity(
            opacity: caption.isEmpty ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 350),
            child: Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: homeSerif(
                size: 15,
                color: AzizColors.lightBackground.withValues(alpha: 0.82),
                style: FontStyle.italic,
                height: 1.35,
              ),
            ),
          ),
        ),
        if (count > 1) ...[
          const SizedBox(width: 16),
          HomeCircleBtn(
            icon: HomeIcons.back,
            onDark: true,
            size: 40,
            semanticLabel: homeText(context, fr: 'Œuvre précédente', en: 'Previous work'),
            onTap: () => _step(-1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${index + 1} / $count',
              style: homeSans(
                size: 13,
                color: AzizColors.lightBackground.withValues(alpha: 0.8),
                weight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
          HomeCircleBtn(
            icon: HomeIcons.next,
            onDark: true,
            size: 40,
            semanticLabel: homeText(context, fr: 'Œuvre suivante', en: 'Next work'),
            onTap: () => _step(1),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FOND
// ═══════════════════════════════════════════════════════════════════════════

class _HeroBackdrop extends StatelessWidget {
  const _HeroBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.62, -0.1),
          radius: 1.05,
          colors: [AzizColors.trueIndigo, AzizColors.trueIndigoDark],
        ),
      ),
    );
  }
}