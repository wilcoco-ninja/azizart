import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import './models/atelier_model.dart';
import '../../theme/aziz_colors.dart';
import '../../core/localization/language_provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Responsive Helper - Keep it simple, all in one file
// ══════════════════════════════════════════════════════════════════════════════

enum ScreenType { mobile, tablet, desktop }

extension ScreenTypeExtension on double {
  ScreenType get screenType {
    if (this < 600) return ScreenType.mobile;
    if (this < 1200) return ScreenType.tablet;
    return ScreenType.desktop;
  }
}

class ResponsiveConstraints {
  final double width;
  final ScreenType screenType;

  ResponsiveConstraints(this.width) : screenType = width.screenType;

  double get horizontalPadding {
    return switch (screenType) {
      ScreenType.mobile => 24.0,
      ScreenType.tablet => 40.0,
      ScreenType.desktop => 60.0,
    };
  }

  int get photoGridColumns {
    return switch (screenType) {
      ScreenType.mobile => 1,
      ScreenType.tablet => 2,
      ScreenType.desktop => 3,
    };
  }

  double get photoMaxWidth => 350.0;
}

// ══════════════════════════════════════════════════════════════════════════════
// AtelierPage - Main Widget
// ══════════════════════════════════════════════════════════════════════════════

class AtelierPage extends StatelessWidget {
  final VoidCallback onContact;
  final List<AtelierPhoto>? photos;
  const AtelierPage({super.key, required this.onContact, this.photos});

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final size = MediaQuery.sizeOf(context);
    final responsiveConstraints = ResponsiveConstraints(size.width);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _BannerSection(responsiveConstraints: responsiveConstraints),
        ),
        SliverToBoxAdapter(
          child: _IntroSection(
            responsiveConstraints: responsiveConstraints,
            onContact: onContact,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              responsiveConstraints.horizontalPadding,
              0,
              responsiveConstraints.horizontalPadding,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('atelier.gallery_title'),
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 5,
                    color: AzizColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('atelier.gallery_subtitle'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AzizColors.textPrimary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 48,
                  height: 2,
                  color: AzizColors.gold,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: responsiveConstraints.horizontalPadding,
          ),
          // FIX PERFORMANCE : le Builder retourne maintenant un sliver
          // directement (SliverToBoxAdapter ou SliverGrid via
          // _ResponsivePhotoGrid), au lieu d'être enveloppé dans un
          // SliverToBoxAdapter qui forçait un GridView "boîte" en
          // shrinkWrap — voir le commentaire détaillé dans
          // _ResponsivePhotoGrid ci-dessous.
          sliver: Builder(builder: (context) {
            // CORRECTION ICI : Remplacement de atelierPhotos par une liste vide
            final displayPhotos = (photos != null && photos!.isNotEmpty)
                ? photos!
                : const <AtelierPhoto>[];

            return displayPhotos.isEmpty
                ? const SliverToBoxAdapter(child: _AtelierEmptyState())
                : _ResponsivePhotoGrid(
                    photos: displayPhotos,
                    responsiveConstraints: responsiveConstraints,
                  );
          }),
        ),
        SliverToBoxAdapter(
          child: _BottomCta(
            onContact: onContact,
            responsiveConstraints: responsiveConstraints,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 60)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Banner Section - Responsive
// ══════════════════════════════════════════════════════════════════════════════

class _BannerSection extends StatelessWidget {
  final ResponsiveConstraints responsiveConstraints;
  const _BannerSection({required this.responsiveConstraints});

  @override
  Widget build(BuildContext context) {
    final isMobile = responsiveConstraints.screenType == ScreenType.mobile;

    return Container(
      height: isMobile ? 180 : 240,
      decoration: BoxDecoration(
        gradient: AzizColors.bannerGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              color: AzizColors.gold,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.tr('atelier.title'),
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 5,
                    color: AzizColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('atelier.banner_subtitle'),
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: isMobile ? 28 : 42,
                    color: AzizColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 0.5,
                      color: AzizColors.gold,
                    ),
                    const SizedBox(width: 10),
                    Transform.rotate(
                      angle: 0.785,
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AzizColors.gold,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 40,
                      height: 0.5,
                      color: AzizColors.gold,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Intro Section - Responsive
// ══════════════════════════════════════════════════════════════════════════════

class _IntroSection extends StatelessWidget {
  final ResponsiveConstraints responsiveConstraints;
  final VoidCallback onContact;
  const _IntroSection({
    required this.responsiveConstraints,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = responsiveConstraints.screenType == ScreenType.mobile;

    return Container(
      color: AzizColors.background,
      padding: EdgeInsets.symmetric(
        horizontal: responsiveConstraints.horizontalPadding,
        vertical: 56,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: isMobile ? _buildColumn(context) : _buildRow(context),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildText(context)),
        const SizedBox(width: 60),
        Expanded(flex: 2, child: _buildKeyFacts(context)),
      ],
    );
  }

  Widget _buildColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildText(context),
        const SizedBox(height: 40),
        _buildKeyFacts(context),
      ],
    );
  }

  Widget _buildText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('atelier.our_atelier'),
          style: GoogleFonts.cormorantGaramond(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: AzizColors.textPrimary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 52,
          height: 2,
          color: AzizColors.gold,
        ),
        const SizedBox(height: 24),
        Text(
          context.tr('atelier.our_atelier_desc'),
          style: GoogleFonts.lato(
            fontSize: 15,
            color: AzizColors.textSecondary,
            height: 1.8,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          context.tr('atelier.philosophy'),
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AzizColors.terracotta,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('atelier.philosophy_desc'),
          style: GoogleFonts.lato(
            fontSize: 15,
            color: AzizColors.textSecondary,
            height: 1.8,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 36),
        _AnimatedCtaButton(onTap: onContact),
      ],
    );
  }

  Widget _buildKeyFacts(BuildContext context) {
    final facts = [
      ('10+', context.tr('atelier.years_exp')),
      ('500+', context.tr('atelier.works_created')),
      ('100%', context.tr('atelier.natural_dyes')),
      ('3', context.tr('atelier.generations')),
    ];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AzizColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AzizColors.divider),
      ),
      child: Column(
        children: facts.map((f) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(
                  f.$1,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AzizColors.gold,
                  ),
                ),
                Text(
                  f.$2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AzizColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const Divider(
                  height: 24,
                  color: AzizColors.divider,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Animated CTA Button
// ══════════════════════════════════════════════════════════════════════════════

class _AnimatedCtaButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AnimatedCtaButton({required this.onTap});

  @override
  State<_AnimatedCtaButton> createState() => _AnimatedCtaButtonState();
}

class _AnimatedCtaButtonState extends State<_AnimatedCtaButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          _controller.forward().then((_) => _controller.reverse());
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AzizColors.terracottaGradient,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: AzizColors.terracotta.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Builder(
                  builder: (context) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr('atelier.contact_cta'),
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w700,
                          color: AzizColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.arrow_forward,
                        color: AzizColors.textPrimary,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// État vide — aucune photo d'atelier disponible
// ══════════════════════════════════════════════════════════════════════════════
class _AtelierEmptyState extends StatelessWidget {
  const _AtelierEmptyState();

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Icon(
            Icons.photo_camera_back_outlined,
            size: 48,
            color: AzizColors.gold.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            isEn
                ? 'No workshop photos yet'
                : 'Aucune photo d\'atelier pour le moment',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              color: AzizColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEn
                ? 'New behind-the-scenes shots will appear here soon.'
                : 'De nouvelles images des coulisses arriveront bientôt ici.',
            style: const TextStyle(
              fontSize: 13,
              color: AzizColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Responsive Photo Grid - SliverGrid + SliverGridDelegateWithMaxCrossAxisExtent
// (fix perf : ancien GridView.builder(shrinkWrap:true) remplacé par un
// vrai sliver paresseux, voir commentaire détaillé dans build() ci-dessous)
// ══════════════════════════════════════════════════════════════════════════════

class _ResponsivePhotoGrid extends StatelessWidget {
  final List<AtelierPhoto> photos;
  final ResponsiveConstraints responsiveConstraints;
  const _ResponsivePhotoGrid({
    required this.photos,
    required this.responsiveConstraints,
  });

  @override
  Widget build(BuildContext context) {
    // FIX PERFORMANCE (page Atelier lente) : l'ancien code utilisait
    // GridView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics())
    // imbriqué dans le CustomScrollView parent. `shrinkWrap: true` oblige
    // Flutter à construire ET mesurer TOUTES les photos d'un coup pour
    // calculer la hauteur de la grille — ce qui déclenche le
    // téléchargement simultané de TOUTES les images réseau dès
    // l'ouverture de la page, au lieu de charger uniquement celles
    // visibles à l'écran. C'était l'une des causes concrètes de lenteur
    // sur cette page (dizaines de photos = dizaines de téléchargements
    // simultanés).
    //
    // Un SliverGrid inséré directement dans les slivers du
    // CustomScrollView (voir atelier_page.dart, AtelierPage.build)
    // redonne à Flutter un vrai chargement paresseux : seules les
    // tuiles proches de l'écran sont construites et leurs images
    // chargées, exactement comme le fait déjà GalleryPage/MediaPage.
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: responsiveConstraints.photoMaxWidth,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) => _PhotoTile(
          photo: photos[i],
          onTap: () => _openLightbox(context, i),
        ),
        childCount: photos.length,
      ),
    );
  }

  void _openLightbox(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (_) => _Lightbox(
        photos: photos,
        initialIndex: initialIndex,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Photo Tile - Fixed height to prevent layout shifts
// ══════════════════════════════════════════════════════════════════════════════

class _PhotoTile extends StatefulWidget {
  final AtelierPhoto photo;
  final VoidCallback onTap;
  const _PhotoTile({required this.photo, required this.onTap});

  @override
  State<_PhotoTile> createState() => _PhotoTileState();
}

class _PhotoTileState extends State<_PhotoTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxWidth * 0.85;

        return MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.photo.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.photo.imageUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 600,
                            placeholder: (_, __) =>
                                Container(color: AzizColors.surface),
                            errorWidget: (_, __, ___) => Container(
                              color: AzizColors.surface,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AzizColors.textSecondary,
                                  size: 32,
                                ),
                              ),
                            ),
                          )
                        : Image.asset(
                            widget.photo.imagePath,
                            fit: BoxFit.cover,
                            cacheWidth: 600,
                            cacheHeight:
                                (height * 600 / constraints.maxWidth).round(),
                            errorBuilder: (_, __, ___) => Container(
                              color: AzizColors.surface,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AzizColors.textSecondary,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: _hovered ? 1.0 : 0.0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AzizColors.terracotta.withValues(alpha: 0.75),
                            ],
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.photo.caption,
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 13,
                                    color: AzizColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.photo.detail,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                    fontSize: 10,
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 220),
                        opacity: _hovered ? 1.0 : 0.0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AzizColors.gold.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.zoom_in,
                            color: AzizColors.background,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Lightbox - Responsive Dialog
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
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _prev() {
    if (_current > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _next() {
    if (_current < widget.photos.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (KeyEvent e) {
        if (e is KeyDownEvent) {
          final key = e.physicalKey;
          if (key == PhysicalKeyboardKey.arrowLeft) _prev();
          if (key == PhysicalKeyboardKey.arrowRight) _next();
          if (key == PhysicalKeyboardKey.escape) Navigator.of(context).pop();
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(isMobile ? 8 : 16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: size.width * (isMobile ? 0.95 : 0.9),
                maxHeight: size.height * (isMobile ? 0.8 : 0.85),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: widget.photos.length,
                      onPageChanged: (i) => setState(() => _current = i),
                      itemBuilder: (_, i) {
                        final photo = widget.photos[i];
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: photo.imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: photo.imageUrl,
                                        fit: BoxFit.contain,
                                        placeholder: (_, __) => SizedBox(
                                          width: double.infinity,
                                          height: isMobile ? 200 : 300,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: AzizColors.gold,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          color: AzizColors.surface,
                                          width: double.infinity,
                                          height: isMobile ? 200 : 300,
                                          child: const Center(
                                            child: Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: AzizColors.textSecondary,
                                              size: 48,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Image.asset(
                                        photo.imagePath,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: AzizColors.surface,
                                          width: double.infinity,
                                          height: isMobile ? 200 : 300,
                                          child: const Center(
                                            child: Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                              color: AzizColors.textSecondary,
                                              size: 48,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              photo.caption,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: isMobile ? 16 : 18,
                                color: AzizColors.textPrimary,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              photo.detail,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: isMobile ? 12 : 13,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${_current + 1} / ${widget.photos.length}',
                              style: GoogleFonts.lato(
                                fontSize: 11,
                                color: Colors.white38,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              child: _NavButton(
                icon: Icons.chevron_left,
                onTap: _current > 0 ? _prev : null,
              ),
            ),
            Positioned(
              right: 0,
              child: _NavButton(
                icon: Icons.chevron_right,
                onTap: _current < widget.photos.length - 1 ? _next : null,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Navigation Button
// ══════════════════════════════════════════════════════════════════════════════

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.25,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(
              color: AzizColors.gold.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Bottom CTA - Responsive
// ══════════════════════════════════════════════════════════════════════════════

class _BottomCta extends StatelessWidget {
  final VoidCallback onContact;
  final ResponsiveConstraints responsiveConstraints;
  const _BottomCta({
    required this.onContact,
    required this.responsiveConstraints,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = responsiveConstraints.screenType == ScreenType.mobile;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: responsiveConstraints.horizontalPadding,
        vertical: 48,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        gradient: AzizColors.bannerGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            context.tr('atelier.visit_title'),
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: isMobile ? 22 : 28,
              color: AzizColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('atelier.visit_desc'),
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 14,
              color: Colors.white70,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onContact,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: AzizColors.gold,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                context.tr('atelier.book_appointment'),
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                  color: AzizColors.background,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
