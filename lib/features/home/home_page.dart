import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/localization/language_provider.dart';
import '../gallery/models/artwork.dart';
import '../gallery/models/gallery_category.dart';
import '../atelier/models/atelier_model.dart';
import '../media/models/media_model.dart';
import 'models/home_model.dart';
import 'services/home_event_service.dart';
import '../../theme/aziz_colors.dart';
import '../../widgets/optimized_image.dart';
import 'dart:math' as math;
import 'dart:async';

class HomePage extends StatelessWidget {
  final Function(int) onNavigate;
  final HomeData homeData;
  final List<AtelierPhoto> atelierPhotos;
  final List<MediaItem> mediaItems;

  const HomePage({
    super.key,
    required this.onNavigate,
    required this.homeData,
    this.atelierPhotos = const [],
    this.mediaItems = const [],
  });

  /// Construit la liste d'images du carrousel héro à partir des VRAIES
  /// données de l'app (Galerie + Atelier), au lieu d'une liste figée
  /// d'assets qui pouvait référencer des fichiers inexistants/déplacés.
  List<String> get _heroImages {
    // FIX: utilise displayImage pour les photos d'atelier (imageUrl Firestore
    // ou imagePath local) au lieu de toujours prendre imagePath.
    final images = <String>[
      ...homeData.featuredArtworks.map((a) => a.displayImage),
      ...atelierPhotos.take(4).map(
            (p) => p.imageUrl.isNotEmpty ? p.imageUrl : p.imagePath,
          ),
    ].where((p) => p.isNotEmpty).toSet().toList();

    if (images.isEmpty) {
      // Repli minimal sur des assets confirmés présents dans le projet.
      // Uniquement des œuvres de galerie ici : les visuels d'atelier sont
      // déjà réservés aux replis des sections Atelier / Artiste plus bas,
      // pour qu'aucune image ne se répète sur la page en mode hors-ligne.
      return const [
        'assets/images/gallery/tableau3.jpeg',
        'assets/images/gallery/tableau4.jpeg',
        'assets/images/gallery/tableau5.jpeg',
      ];
    }
    return images;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroSection(
            onNavigate: onNavigate,
            artworkCount: homeData.featuredArtworks.length,
            carouselImages: _heroImages,
          ),
          const SizedBox(height: 120),
          RepaintBoundary(child: _CategoriesSection(onNavigate: onNavigate)),
          const SizedBox(height: 120),
          RepaintBoundary(child: _BentoShowcaseSection(onNavigate: onNavigate)),
          const SizedBox(height: 120),
          RepaintBoundary(
            child: _WorkshopSection(
              onNavigate: onNavigate,
              atelierPhotos: atelierPhotos,
            ),
          ),
          const SizedBox(height: 120),
          RepaintBoundary(
            child: _FeaturedSection(
              onNavigate: onNavigate,
              artworks: homeData.featuredArtworks,
            ),
          ),
          const SizedBox(height: 120),
          // ── Section actualités/événements publiés par l'admin ──────────
          _NewsEventsSection(onNavigate: onNavigate),
          const SizedBox(height: 120),
          RepaintBoundary(
            child: _ArtistPreviewSection(onNavigate: onNavigate),
          ),
          const SizedBox(height: 120),
          if (mediaItems.isNotEmpty) ...[
            _PressSection(onNavigate: onNavigate, mediaItems: mediaItems),
            const SizedBox(height: 120),
          ],
          const _QuoteSection(),
          const SizedBox(height: 120),
          _SocialFollowSection(onNavigate: onNavigate),
          const SizedBox(height: 120),
          _ExploreSection(onNavigate: onNavigate),
          const SizedBox(height: 100),
          const _FooterSection(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPOSANTS PARTAGÉS
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTag extends StatelessWidget {
  final String label;
  const _SectionTag(this.label);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 1,
            color: AzizColors.saffron,
          ),
          const SizedBox(width: 12),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 10,
              letterSpacing: 4.8,
              color: AzizColors.saffron,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 1 · HERO SECTION IMMERSIVE
// ─────────────────────────────────────────────────────────────────────────────
class _HeroSection extends StatefulWidget {
  final Function(int) onNavigate;
  final int artworkCount;
  final List<String> carouselImages;
  const _HeroSection({
    required this.onNavigate,
    required this.artworkCount,
    required this.carouselImages,
  });

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  Timer? _carouselTimer;
  int _currentImageIndex = 0;

  List<String> get _carouselImages => widget.carouselImages;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();

    _carouselTimer = Timer.periodic(
      const Duration(seconds: 6), // Ralenti légèrement pour l'élégance
      (_) {
        if (!mounted) return;
        setState(() {
          _currentImageIndex =
              (_currentImageIndex + 1) % _carouselImages.length;
        });
      },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  // FIX défensif : si la liste d'images change de taille pendant que la
  // page est déjà affichée (ex. une œuvre "vedette" est retirée par
  // l'admin), on ramène l'index courant dans les limites pour éviter un
  // RangeError au prochain build, en attendant le prochain tick du timer.
  @override
  void didUpdateWidget(_HeroSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentImageIndex >= widget.carouselImages.length) {
      _currentImageIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return SizedBox(
      height: screenHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 1500),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Stack(
              key: ValueKey<int>(_currentImageIndex),
              fit: StackFit.expand,
              children: [
                OptimizedImage(
                  assetPath: _carouselImages[_currentImageIndex],
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AzizColors.lightBackground.withValues(alpha: 0.35),
                        AzizColors.lightBackground.withValues(alpha: 0.78),
                        AzizColors.lightBackground.withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
          FadeTransition(
            opacity: _fade,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'OLGA',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: isMobile ? 56 : 96,
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                      color: AzizColors.lightTextPrimary,
                      letterSpacing: isMobile ? 4 : 8,
                      height: 0.9,
                    ),
                  ),
                  _StrokeTextPainter.paintStrokeText(
                    'INDIGO',
                    isMobile: isMobile,
                  ),
                  SizedBox(height: isMobile ? 24 : 36),
                  _LogoOrnament(width: isMobile ? 160 : 260),
                  SizedBox(height: isMobile ? 24 : 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      context.tr('home.tagline'),
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: isMobile ? 12 : 14,
                        color: AzizColors.lightTextSecondary,
                        letterSpacing: 2.5,
                        height: 1.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: isMobile ? 40 : 56),
                  _HeroBtn(
                    label: context.tr('home.discover_gallery'),
                    onTap: () => widget.onNavigate(1),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _carouselImages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 32 : 8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? AzizColors.saffron
                        : AzizColors.lightTextPrimary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StrokeTextPainter extends StatelessWidget {
  final String text;
  final bool isMobile;

  const _StrokeTextPainter({required this.text, required this.isMobile});

  static Widget paintStrokeText(String text, {required bool isMobile}) {
    return CustomPaint(
      painter: _TextStrokePainter(
        text: text,
        fontSize: isMobile ? 56.0 : 96.0,
        strokeWidth: isMobile ? 0.8 : 1.2,
        color: AzizColors.saffron,
      ),
      size: Size(isMobile ? 300 : 500, isMobile ? 70 : 120),
    );
  }

  @override
  Widget build(BuildContext context) =>
      paintStrokeText(text, isMobile: isMobile);
}

class _TextStrokePainter extends CustomPainter {
  final String text;
  final double fontSize;
  final double strokeWidth;
  final Color color;

  _TextStrokePainter({
    required this.text,
    required this.fontSize,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
          fontStyle: FontStyle.italic,
          letterSpacing: 4,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;

    textPainter.paint(canvas, Offset.zero);

    textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Georgia',
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        letterSpacing: 4,
        foreground: paint,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant _TextStrokePainter old) {
    return old.text != text || old.fontSize != fontSize || old.color != color;
  }
}

class _LogoOrnament extends StatelessWidget {
  final double width;
  const _LogoOrnament({required this.width});

  @override
  Widget build(BuildContext context) {
    final lineWidth = (width - 20) / 2;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: lineWidth,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AzizColors.saffron.withValues(alpha: 0.8)
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AzizColors.saffron,
              boxShadow: [
                BoxShadow(
                  color: AzizColors.saffron.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: lineWidth,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AzizColors.saffron.withValues(alpha: 0.8),
                Colors.transparent
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _HeroBtn({required this.label, required this.onTap});

  @override
  State<_HeroBtn> createState() => _HeroBtnState();
}

class _HeroBtnState extends State<_HeroBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: _ctrl.reverse,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
          decoration: BoxDecoration(
            color: AzizColors.saffron,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: AzizColors.saffron.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            widget.label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 12,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
              color: AzizColors.lightTextPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  final Function(int) onNavigate;
  const _CategoriesSection({required this.onNavigate});

  void _openCategory(GalleryCategory category) {
    GalleryNavigationRequest.requestCategory(category);
    onNavigate(1); // 1 = Galerie
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final isTablet = width >= 768 && width < 1200;
    final hPad = isMobile ? 24.0 : 60.0;
    final columns = isMobile ? 2 : (isTablet ? 3 : 6);
    final isEn = Localizations.maybeLocaleOf(context)?.languageCode == 'en';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTag(isEn ? 'Explore' : 'Explorer'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  isEn ? 'Shop by category' : 'Acheter par catégorie',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: isMobile ? 28 : 44,
                    fontWeight: FontWeight.w300,
                    color: AzizColors.lightTextPrimary,
                    height: 1.1,
                  ),
                ),
              ),
              if (!isMobile)
                TextButton(
                  onPressed: () => onNavigate(1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEn ? 'See all' : 'Voir tout',
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 13,
                          letterSpacing: 1.5,
                          color: AzizColors.saffron,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward,
                          size: 16, color: AzizColors.saffron),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 40),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isMobile ? 0.85 : 0.95,
            ),
            itemCount: GalleryCategory.values.length,
            itemBuilder: (_, i) {
              final category = GalleryCategory.values[i];
              return _CategoryTile(
                category: category,
                onTap: () => _openCategory(category),
              );
            },
          ),
          if (isMobile) ...[
            const SizedBox(height: 28),
            Center(
              child: TextButton(
                onPressed: () => onNavigate(1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEn ? 'See all' : 'Voir tout',
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 13,
                        letterSpacing: 1.5,
                        color: AzizColors.saffron,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward,
                        size: 16, color: AzizColors.saffron),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final GalleryCategory category;
  final VoidCallback onTap;
  const _CategoryTile({required this.category, required this.onTap});

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AzizColors.saffron.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 300),
                  scale: _isHovered ? 1.08 : 1.0,
                  child: OptimizedImage(
                    assetPath: category.coverAsset,
                    fit: BoxFit.cover,
                    errorWidget: Container(color: AzizColors.lightCard),
                  ),
                ),
                // Voile sombre permanent pour garantir la lisibilité du texte
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black
                            .withValues(alpha: _isHovered ? 0.15 : 0.25),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      stops: const [0.3, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AzizColors.backgroundDark.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AzizColors.saffron.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(
                      category.icon,
                      size: 16,
                      color: AzizColors.saffron,
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category.label(context),
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _isHovered ? 1.0 : 0.0,
                        child: Text(
                          category.description(context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.3,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// 2 · BENTO BOX SHOWCASE
// ─────────────────────────────────────────────────────────────────────────────
class _BentoShowcaseSection extends StatelessWidget {
  final Function(int) onNavigate;
  const _BentoShowcaseSection({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final hPad = isMobile ? 24.0 : 60.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTag(context.tr('home.shop')),
          const SizedBox(height: 16),
          Text(
            context.tr('home.our_creations'),
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: isMobile ? 32 : 48,
              fontWeight: FontWeight.w300,
              color: AzizColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 56),
          isMobile
              ? _BentoColumn(onNavigate: onNavigate)
              : _BentoDesktopGrid(onNavigate: onNavigate),
        ],
      ),
    );
  }
}

class _BentoColumn extends StatelessWidget {
  final Function(int) onNavigate;
  const _BentoColumn({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BentoCardLarge(
          imagePath: 'assets/images/gallery/tableau2.jpeg',
          title: context.tr('home.original_paintings'),
          subtitle: context.tr('home.unique_pieces'),
          description: context.tr('home.paintings_desc'),
          onTap: () => onNavigate(1),
        ),
        const SizedBox(height: 16),
        _BentoCardSmall(
          imagePath: 'assets/images/gallery/a12.jpg',
          title: context.tr('home.artwear'),
          subtitle: context.tr('home.batik_clothing'),
          onTap: () => onNavigate(1),
        ),
        const SizedBox(height: 16),
        _BentoCardSmall(
          imagePath: 'assets/images/gallery/a4.jpg',
          title: context.tr('home.custom_orders'),
          subtitle: context.tr('home.personalized_decor'),
          onTap: () => onNavigate(4),
        ),
      ],
    );
  }
}

class _BentoDesktopGrid extends StatelessWidget {
  final Function(int) onNavigate;
  const _BentoDesktopGrid({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 600,
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: _BentoCardLarge(
              imagePath: 'assets/images/gallery/tableau2.jpeg',
              title: context.tr('home.original_paintings'),
              subtitle: context.tr('home.unique_pieces'),
              description: context.tr('home.paintings_desc'),
              onTap: () => onNavigate(1),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(
                  child: _BentoCardSmall(
                    imagePath: 'assets/images/gallery/tableau6.jpeg',
                    title: context.tr('home.artwear'),
                    subtitle: context.tr('home.batik_clothing'),
                    onTap: () => onNavigate(1),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _BentoCardSmall(
                    imagePath: 'assets/images/atelier/t13.jpg',
                    title: context.tr('home.custom_orders'),
                    subtitle: context.tr('home.personalized_decor'),
                    onTap: () => onNavigate(4),
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

class _BentoCardLarge extends StatefulWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final String description;
  final VoidCallback onTap;

  const _BentoCardLarge({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.onTap,
  });

  @override
  State<_BentoCardLarge> createState() => _BentoCardLargeState();
}

class _BentoCardLargeState extends State<_BentoCardLarge> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AzizColors.lightCard,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      OptimizedImage(
                        assetPath: widget.imagePath,
                        fit: BoxFit.cover,
                        errorWidget: Container(color: AzizColors.lightSurface),
                      ),
                      AnimatedOpacity(
                        opacity: _isHovered ? 0.0 : 0.1,
                        duration: const Duration(milliseconds: 400),
                        child: Container(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.subtitle.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 11,
                          letterSpacing: 3,
                          color: AzizColors.saffron,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 26,
                          fontWeight: FontWeight.w400,
                          color: AzizColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.description,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 14,
                          color: AzizColors.lightTextSecondary,
                          height: 1.8,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoCardSmall extends StatefulWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _BentoCardSmall({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  State<_BentoCardSmall> createState() => _BentoCardSmallState();
}

class _BentoCardSmallState extends State<_BentoCardSmall> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedScale(
                  scale: _isHovered ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  child: OptimizedImage(
                    assetPath: widget.imagePath,
                    fit: BoxFit.cover,
                    errorWidget: Container(color: AzizColors.lightSurface),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.6],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subtitle.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 10,
                            letterSpacing: 2,
                            color: AzizColors.saffron,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// SECTION : Atelier — Création du tissu (batik)
// ─────────────────────────────────────────────────────────────────────────────
class _WorkshopSection extends StatelessWidget {
  final Function(int) onNavigate;
  final List<AtelierPhoto> atelierPhotos;
  const _WorkshopSection({
    required this.onNavigate,
    this.atelierPhotos = const [],
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final hPad = isMobile ? 24.0 : 60.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: isMobile
          ? Column(
              children: [
                _WorkshopImageCollage(atelierPhotos: atelierPhotos),
                const SizedBox(height: 40),
                _WorkshopText(onNavigate: onNavigate, isMobile: true),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 5,
                  child: _WorkshopText(onNavigate: onNavigate, isMobile: false),
                ),
                const SizedBox(width: 64),
                Expanded(
                  flex: 6,
                  child: _WorkshopImageCollage(atelierPhotos: atelierPhotos),
                ),
              ],
            ),
    );
  }
}

class _WorkshopText extends StatelessWidget {
  final Function(int) onNavigate;
  final bool isMobile;
  const _WorkshopText({required this.onNavigate, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        _SectionTag(context.tr('home.workshop_tag')),
        const SizedBox(height: 16),
        Text(
          context.tr('home.workshop_title'),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: isMobile ? 30 : 42,
            fontWeight: FontWeight.w300,
            color: AzizColors.lightTextPrimary,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          context.tr('home.workshop_desc'),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: const TextStyle(
            fontSize: 14.5,
            height: 1.7,
            color: AzizColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 32),
        _WorkshopStepsRow(isMobile: isMobile),
        const SizedBox(height: 36),
        GestureDetector(
          onTap: () => onNavigate(2), // PageIndices.atelier
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: BoxDecoration(
                color: AzizColors.saffron,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('home.workshop_cta'),
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: AzizColors.textOnAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 16, color: AzizColors.textOnAccent),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkshopStepsRow extends StatelessWidget {
  final bool isMobile;
  const _WorkshopStepsRow({required this.isMobile});

  static const List<IconData> _icons = [
    Icons.brush_outlined,
    Icons.water_drop_outlined,
    Icons.local_fire_department_outlined,
  ];

  static const List<String> _labelKeys = [
    'about.step1_title',
    'about.step2_title',
    'about.step3_title',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
      spacing: 28,
      runSpacing: 16,
      children: [
        for (int i = 0; i < _icons.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icons[i], size: 16, color: AzizColors.greenBatik),
              const SizedBox(width: 8),
              Text(
                context.tr(_labelKeys[i]),
                style: const TextStyle(
                  fontSize: 12,
                  color: AzizColors.lightTextMuted,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _WorkshopImageCollage extends StatelessWidget {
  final List<AtelierPhoto> atelierPhotos;
  const _WorkshopImageCollage({this.atelierPhotos = const []});

  // ── Sélection de la bonne source d'image ────────────────────────────────
  // FIX: avant on passait toujours assetPath à OptimizedImage, même quand
  // l'image venait de Firebase Storage (URL https://). Maintenant on
  // distingue les deux cas correctement.
  Widget _buildImage(String pathOrUrl,
      {BorderRadius? borderRadius, Widget? placeholder}) {
    final clip = borderRadius ?? BorderRadius.circular(12);
    final ph = placeholder ?? Container(color: AzizColors.lightSurface);

    if (pathOrUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: clip,
        child: CachedNetworkImage(
          imageUrl: pathOrUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => ph,
          errorWidget: (_, __, ___) => ph,
        ),
      );
    }
    return ClipRRect(
      borderRadius: clip,
      child: OptimizedImage(
        assetPath: pathOrUrl,
        fit: BoxFit.cover,
        errorWidget: ph,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bigImage = atelierPhotos.isNotEmpty
        ? (atelierPhotos[0].imageUrl.isNotEmpty
            ? atelierPhotos[0].imageUrl
            : atelierPhotos[0].imagePath)
        : 'assets/images/atelier/t3.jpg';
    final smallImage = atelierPhotos.length > 1
        ? (atelierPhotos[1].imageUrl.isNotEmpty
            ? atelierPhotos[1].imageUrl
            : atelierPhotos[1].imagePath)
        : 'assets/images/atelier/t7.jpg';

    return AspectRatio(
      aspectRatio: 1.15,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(left: 36, top: 36),
              child: _buildImage(
                bigImage,
                placeholder: Container(color: AzizColors.lightSurface),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            width: 190,
            height: 190,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AzizColors.lightBackground, width: 6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: _buildImage(
                smallImage,
                borderRadius: BorderRadius.circular(8),
                placeholder: Container(color: AzizColors.lightCard),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4 · ŒUVRES À LA UNE
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturedSection extends StatelessWidget {
  final Function(int) onNavigate;
  final List<Artwork> artworks;
  const _FeaturedSection({
    required this.onNavigate,
    required this.artworks,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final hPad = isMobile ? 24.0 : 60.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTag(context.tr('home.selection')),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('home.featured'),
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: isMobile ? 32 : 48,
                      fontWeight: FontWeight.w300,
                      color: AzizColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => onNavigate(1),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr('home.view_all').toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 11,
                          letterSpacing: 2,
                          color: AzizColors.saffron,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AzizColors.saffron,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        SizedBox(
          height: 480,
          child: artworks.isEmpty
              ? Center(
                  child: Text(
                    context.tr('home.no_artworks'),
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: AzizColors.lightTextSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 20),
                  itemCount: artworks.length,
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.only(
                      right: i < artworks.length - 1 ? 32 : 0,
                    ),
                    child: _ArtworkCard(artwork: artworks[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION : Abonnement réseaux sociaux — YouTube, Instagram, TikTok
// ─────────────────────────────────────────────────────────────────────────────
class _SocialFollowSection extends StatelessWidget {
  final Function(int) onNavigate;
  const _SocialFollowSection({required this.onNavigate});

  static const String _youtubeUrl = 'https://www.youtube.com/@azizart-color';
  static const String _instagramUrl =
      'https://www.instagram.com/indigoolga25?igsh=MTdjbGk1NW80bmtmaw==';
  static const String _tiktokUrl = 'https://www.tiktok.com/@olga.indigo';
  static const String _facebookUrl =
      'https://www.facebook.com/profile.php?id=100074832580615';

  // FIX : `canLaunchUrl` n'est pas fiable sur Flutter Web (voir
  // contact_page.dart pour le détail) — il bloquait l'ouverture des
  // réseaux sociaux même quand `launchUrl` aurait fonctionné.
  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        debugPrint('SocialFollowSection: launchUrl a échoué pour $uri');
      }
    } catch (e) {
      debugPrint('SocialFollowSection: impossible d\'ouvrir $uri — $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final hPad = isMobile ? 24.0 : 60.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hPad),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 32 : 64,
        vertical: isMobile ? 56 : 80,
      ),
      decoration: BoxDecoration(
        color: AzizColors.lightBackgroundAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AzizColors.saffron.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          _SectionTag(context.tr('home.follow_tag')),
          const SizedBox(height: 20),
          Text(
            context.tr('home.follow_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: isMobile ? 28 : 40,
              fontWeight: FontWeight.w300,
              color: AzizColors.lightTextPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('home.follow_subtitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 14,
              color: AzizColors.lightTextSecondary,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: isMobile ? 16 : 24,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _SocialCard(
                icon: FontAwesomeIcons.youtube,
                platform: 'YouTube',
                handle: '@azizart-color',
                description: context.tr('home.follow_youtube_desc'),
                color: const Color(0xFFFF0000),
                onTap: () => _launch(_youtubeUrl),
              ),
              _SocialCard(
                icon: FontAwesomeIcons.instagram,
                platform: 'Instagram',
                handle: '@indigoolga25',
                description: context.tr('home.follow_instagram_desc'),
                color: const Color(0xFFE1306C),
                onTap: () => _launch(_instagramUrl),
              ),
              _SocialCard(
                icon: FontAwesomeIcons.tiktok,
                platform: 'TikTok',
                handle: '@olga.indigo',
                description: context.tr('home.follow_tiktok_desc'),
                color: AzizColors.lightTextPrimary,
                onTap: () => _launch(_tiktokUrl),
              ),
              _SocialCard(
                icon: FontAwesomeIcons.facebook,
                platform: 'Facebook',
                handle: 'Olga Indigo',
                description: context.tr('home.follow_facebook_desc'),
                color: const Color(0xFF1877F2),
                onTap: () => _launch(_facebookUrl),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialCard extends StatefulWidget {
  final FaIconData icon;
  final String platform;
  final String handle;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _SocialCard({
    required this.icon,
    required this.platform,
    required this.handle,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  State<_SocialCard> createState() => _SocialCardState();
}

class _SocialCardState extends State<_SocialCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final cardWidth = isMobile ? double.infinity : 220.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: cardWidth,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.08)
                : AzizColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.5)
                  : AzizColors.lightBorder.withValues(alpha: 0.4),
              width: _hovered ? 1.5 : 0.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: FaIcon(widget.icon, size: 20, color: widget.color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.platform,
                          style: const TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AzizColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          widget.handle,
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.color,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AzizColors.lightTextMuted,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Builder(
                    builder: (context) {
                      final isEn =
                          Localizations.maybeLocaleOf(context)?.languageCode ==
                              'en';
                      return Text(
                        isEn ? 'FOLLOW' : 'SUIVRE',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                          color: widget.color,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      size: 12, color: widget.color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION : Aperçu biographique — Olga Indigo
// À insérer dans home_page.dart, entre _FeaturedSection et _QuoteSection.
//
// Usage dans HomePage.build() :
//   _FeaturedSection(...),
//   const SizedBox(height: 120),
//   _ArtistPreviewSection(onNavigate: onNavigate),   // ← AJOUTEZ CETTE LIGNE
//   const SizedBox(height: 120),
//   const _QuoteSection(),
// ─────────────────────────────────────────────────────────────────────────────

// ═══════════════════════════════════════════════════════════════════════════════
// _ArtistPreviewSection  — bloc principal
// ═══════════════════════════════════════════════════════════════════════════════
class _ArtistPreviewSection extends StatelessWidget {
  final Function(int) onNavigate;
  const _ArtistPreviewSection({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;
    final hPad = isMobile ? 24.0 : 60.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: isMobile
          ? _ArtistPreviewMobile(onNavigate: onNavigate)
          : _ArtistPreviewDesktop(onNavigate: onNavigate),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Layout DESKTOP — image à gauche, texte + stats + techniques à droite
// ═══════════════════════════════════════════════════════════════════════════════
class _ArtistPreviewDesktop extends StatelessWidget {
  final Function(int) onNavigate;
  const _ArtistPreviewDesktop({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Collage photo (50 %) ─────────────────────────────────────────────
        const Expanded(
          flex: 5,
          child: _ArtistPhotoCollage(),
        ),
        const SizedBox(width: 72),
        // ── Texte biographique (50 %) ────────────────────────────────────────
        Expanded(
          flex: 5,
          child: _ArtistBioContent(onNavigate: onNavigate),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Layout MOBILE — empilé verticalement
// ═══════════════════════════════════════════════════════════════════════════════
class _ArtistPreviewMobile extends StatelessWidget {
  final Function(int) onNavigate;
  const _ArtistPreviewMobile({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ArtistBioContent(onNavigate: onNavigate, isMobile: true),
        const SizedBox(height: 48),
        const _ArtistPhotoCollage(isMobile: true),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Collage photographique — 3 images superposées (atelier)
//   • Principale  : assets/images/atelier/t1.jpg  (grande, arrière-plan)
//   • Secondaire  : assets/images/atelier/t9.jpg  (cadre flottant haut-gauche)
//   • Accentuation: assets/images/atelier/t5.jpeg (bandeau bas)
// Chaque image est unique sur la page (pas de répétition avec le collage
// de la section Atelier ni avec le carrousel héro).
// ═══════════════════════════════════════════════════════════════════════════════
class _ArtistPhotoCollage extends StatelessWidget {
  final bool isMobile;
  const _ArtistPhotoCollage({this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: isMobile ? 1.0 : 0.85,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Image principale (pleine hauteur, légèrement décalée à droite) ──
          Positioned(
            left: isMobile ? 0 : 40,
            right: 0,
            top: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: OptimizedImage(
                assetPath: 'assets/images/atelier/t1.jpg',
                fit: BoxFit.cover,
                errorWidget: Container(color: AzizColors.lightSurface),
              ),
            ),
          ),

          // ── Cadre flottant haut-gauche (portrait ou gros plan atelier) ──────
          Positioned(
            left: 0,
            top: isMobile ? 16 : 32,
            width: isMobile ? 130 : 180,
            height: isMobile ? 165 : 225,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AzizColors.lightBackground, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: OptimizedImage(
                  assetPath: 'assets/images/atelier/t9.jpg',
                  fit: BoxFit.cover,
                  errorWidget: Container(color: AzizColors.lightCard),
                ),
              ),
            ),
          ),

          // ── Étiquette flottante "30+ ans de pratique" ────────────────────────
          Positioned(
            right: isMobile ? 0 : -10,
            bottom: isMobile ? 90 : 110,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AzizColors.saffron,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AzizColors.saffron.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '30+',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AzizColors.lightTextPrimary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Builder(builder: (context) {
                    final isEn =
                        Localizations.maybeLocaleOf(context)?.languageCode ==
                            'en';
                    return Text(
                      isEn ? 'YEARS\nOF PRACTICE' : 'ANS\nDE PRATIQUE',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 9,
                        letterSpacing: 1.8,
                        fontWeight: FontWeight.w700,
                        color: AzizColors.lightTextPrimary,
                        height: 1.4,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // ── Bandeau bas : image actualités ──────────────────────────────────
          Positioned(
            left: isMobile ? 0 : 40,
            right: 0,
            bottom: 0,
            height: isMobile ? 80 : 100,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  OptimizedImage(
                    assetPath: 'assets/images/atelier/t5.jpg',
                    fit: BoxFit.cover,
                    errorWidget: Container(color: AzizColors.lightSurface),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.75),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 14,
                    child: Builder(builder: (context) {
                      final isEn =
                          Localizations.maybeLocaleOf(context)?.languageCode ==
                              'en';
                      return Text(
                        isEn
                            ? 'FINAB 2026 · Cotonou, Benin'
                            : 'FINAB 2026 · Cotonou, Bénin',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: isMobile ? 10 : 12,
                          letterSpacing: 1.5,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }),
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

// ═══════════════════════════════════════════════════════════════════════════════
// Contenu biographique — texte + compteurs + techniques + CTA
// ═══════════════════════════════════════════════════════════════════════════════
class _ArtistBioContent extends StatelessWidget {
  final Function(int) onNavigate;
  final bool isMobile;
  const _ArtistBioContent({
    required this.onNavigate,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tag section ────────────────────────────────────────────────────
        _SectionTag(context.tr('home.about_tag')),
        const SizedBox(height: 16),

        // ── Titre ──────────────────────────────────────────────────────────
        Text(
          context.tr('home.about_title'),
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: isMobile ? 30 : 42,
            fontWeight: FontWeight.w300,
            color: AzizColors.lightTextPrimary,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),

        // ── Sous-titre : héritage Dahomey ───────────────────────────────────
        Builder(builder: (context) {
          final isEn =
              Localizations.maybeLocaleOf(context)?.languageCode == 'en';
          return Text(
            isEn
                ? 'Bohicon, Benin · 1975  ·  Heir to the Kingdom of Dahomey'
                : 'Bohicon, Bénin · 1975  ·  Héritière du Royaume du Dahomey',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: isMobile ? 11 : 12,
              letterSpacing: 1.2,
              color: AzizColors.saffron,
              fontStyle: FontStyle.italic,
            ),
          );
        }),
        const SizedBox(height: 28),

        // ── Ligne décorative ────────────────────────────────────────────────
        Container(width: 40, height: 1, color: AzizColors.saffron),
        const SizedBox(height: 28),

        // ── Bio courte ──────────────────────────────────────────────────────
        Builder(builder: (context) {
          final isEn =
              Localizations.maybeLocaleOf(context)?.languageCode == 'en';
          return Text(
            isEn
                ? 'A Beninese visual artist born in Bohicon, Olga Indigo has '
                    'spent over thirty years building a body of work at the '
                    'crossroads of batik, textile art, and natural dyes — '
                    'indigo, kola, baobab, and teak pigments. Her work explores '
                    'collective memory, feminine heritage, and African '
                    'cosmologies.'
                : 'Artiste visuelle béninoise née à Bohicon, Olga Indigo développe '
                    'depuis plus de trente ans une œuvre à la croisée du batik, de '
                    'l\'art textile et des teintures naturelles — pigments d\'indigo, '
                    'de cola, de baobab et de teck. Son travail explore la mémoire '
                    'collective, les héritages féminins et les cosmologies africaines.',
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              height: 1.8,
              color: AzizColors.lightTextSecondary,
            ),
          );
        }),
        const SizedBox(height: 40),

        // ── Compteurs clés ──────────────────────────────────────────────────
        _ArtistStats(isMobile: isMobile),
        const SizedBox(height: 40),

        // ── Techniques (chips) ──────────────────────────────────────────────
        _TechniqueChips(isMobile: isMobile),
        const SizedBox(height: 40),

        // ── Représentation ──────────────────────────────────────────────────
        Row(
          children: [
            Icon(
              Icons.business_outlined,
              size: 14,
              color: AzizColors.saffron.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Builder(builder: (context) {
              final isEn =
                  Localizations.maybeLocaleOf(context)?.languageCode == 'en';
              return Text(
                isEn ? 'Galerie SAGA, France' : 'Galerie SAGA, France',
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 12,
                  letterSpacing: 1,
                  color: AzizColors.lightTextMuted,
                  fontStyle: FontStyle.italic,
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 36),

        // ── CTA ─────────────────────────────────────────────────────────────
        GestureDetector(
          onTap: () => onNavigate(4), // PageIndices.about
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AzizColors.saffron.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr('home.about_cta').toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 11,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w600,
                          color: AzizColors.saffron,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AzizColors.saffron,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Compteurs statistiques (expositions, pays, années de pratique)
// Données issues de aboutData.exhibitions (about_model.dart)
// ═══════════════════════════════════════════════════════════════════════════════
class _ArtistStats extends StatelessWidget {
  final bool isMobile;
  const _ArtistStats({this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    // Données calculées depuis aboutData :
    //   • 15 expositions listées dans exhibitions[]
    //   • 7 pays / villes : Bénin, Burkina Faso, Côte d'Ivoire, France (Paris/Lille),
    //                        Allemagne, Mali + FINAB récents
    // Note : le compteur "30 ans de pratique" est déjà affiché sur l'étiquette
    // flottante du collage photo — on ne le répète pas ici pour éviter la
    // redondance de texte.
    final isEn = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    final stats = [
      _StatItem(
        value: '15+',
        label: isEn ? 'Exhibitions' : 'Expositions',
      ),
      _StatItem(
        value: '7',
        label: isEn ? 'Countries & cities' : 'Pays & villes',
      ),
    ];

    return Wrap(
      spacing: isMobile ? 24 : 40,
      runSpacing: 20,
      children: stats,
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 36,
            fontWeight: FontWeight.w300,
            color: AzizColors.saffron,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 9,
            letterSpacing: 2.5,
            color: AzizColors.lightTextMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Chips de techniques — issues de aboutData.techniques
// ═══════════════════════════════════════════════════════════════════════════════
class _TechniqueChips extends StatelessWidget {
  final bool isMobile;
  const _TechniqueChips({this.isMobile = false});

  // aboutData.techniques (about_model.dart) — FR / EN
  static const List<String> _techniquesFr = [
    'Batik sur toile',
    'Tissu Aho',
    'Teintures naturelles',
    'Pigments organiques',
    'Réserve à la cire',
  ];
  static const List<String> _techniquesEn = [
    'Batik on canvas',
    'Aho cloth',
    'Natural dyes',
    'Organic pigments',
    'Wax resist',
  ];

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    final techniques = isEn ? _techniquesEn : _techniquesFr;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: techniques.map((t) => _Chip(label: t)).toList(),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AzizColors.greenBatik.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Georgia',
          fontSize: 11,
          letterSpacing: 0.8,
          color: AzizColors.greenBatik,
        ),
      ),
    );
  }
}

//─────────────────────────────────────────────────────────────────────────────

class _ArtworkCard extends StatefulWidget {
  final Artwork artwork;
  const _ArtworkCard({required this.artwork});

  @override
  State<_ArtworkCard> createState() => _ArtworkCardState();
}

class _ArtworkCardState extends State<_ArtworkCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Modale de détail de l'œuvre ─────────────────────────────────────────
  // FIX BUG 1 : avant, aucun GestureDetector n'enveloppait la carte.
  // Le curseur "click" était affiché mais rien ne se passait au clic.
  void _showDetail(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'fermer',
      barrierColor: Colors.black.withValues(alpha: 0.88),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, anim, _, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.93, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOut),
          ),
          child: child,
        ),
      ),
      pageBuilder: (context, _, __) => _ArtworkDetailDialog(
        artwork: widget.artwork,
        isEn: Localizations.maybeLocaleOf(context)?.languageCode == 'en',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _ctrl.forward(),
      onExit: (_) => _ctrl.reverse(),
      cursor: SystemMouseCursors.click,
      // FIX BUG 1 : GestureDetector ajouté pour ouvrir la modale de détail
      child: GestureDetector(
        onTap: () => _showDetail(context),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 320,
            decoration: BoxDecoration(
              color: AzizColors.lightCard,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(8)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        widget.artwork.hasNetworkImage
                            ? CachedNetworkImage(
                                imageUrl: widget.artwork.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    Container(color: AzizColors.lightSurface),
                                errorWidget: (_, __, ___) =>
                                    Container(color: AzizColors.lightSurface),
                              )
                            : OptimizedImage(
                                assetPath: widget.artwork.imagePath,
                                fit: BoxFit.cover,
                              ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.artwork.isAvailable
                                  ? AzizColors.saffron.withValues(alpha: 0.95)
                                  : AzizColors.terraCotta
                                      .withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.artwork.isAvailable
                                  ? context.tr('home.available').toUpperCase()
                                  : context.tr('home.sold').toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 9,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w700,
                                color: widget.artwork.isAvailable
                                    ? AzizColors.lightTextPrimary
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                        // Indicateur "Tap to expand"
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.open_in_full_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.artwork.title,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          color: AzizColors.lightTextPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.artwork.category,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 13,
                          color: AzizColors.lightTextSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// 4bis · PRESSE & MÉDIAS — bandeau horizontal façon Art Paris
// (rangée de vignettes vidéo/reportage avec légende, comme la section
// "Vidéos" du site artparis.com)
// ─────────────────────────────────────────────────────────────────────────────
class _PressSection extends StatelessWidget {
  final Function(int) onNavigate;
  final List<MediaItem> mediaItems;
  const _PressSection({required this.onNavigate, required this.mediaItems});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final hPad = isMobile ? 24.0 : 60.0;
    final items = mediaItems.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTag(
                      Localizations.maybeLocaleOf(context)?.languageCode == 'en'
                          ? 'MEDIA & PRESS'
                          : 'MÉDIAS & PRESSE'),
                  const SizedBox(height: 14),
                  Text(
                    Localizations.maybeLocaleOf(context)?.languageCode == 'en'
                        ? 'In the Spotlight'
                        : 'Sous les projecteurs',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: isMobile ? 26 : 36,
                      fontWeight: FontWeight.w300,
                      color: AzizColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => onNavigate(3), // PageIndices.media
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    Localizations.maybeLocaleOf(context)?.languageCode == 'en'
                        ? 'SEE ALL'
                        : 'VOIR TOUT',
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                      color: AzizColors.saffron,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: isMobile ? 220 : 260,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 20),
            itemBuilder: (context, index) =>
                _PressCard(item: items[index], onNavigate: onNavigate),
          ),
        ),
      ],
    );
  }
}

class _PressCard extends StatefulWidget {
  final MediaItem item;
  final Function(int) onNavigate;
  const _PressCard({required this.item, required this.onNavigate});

  @override
  State<_PressCard> createState() => _PressCardState();
}

class _PressCardState extends State<_PressCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isMobile = MediaQuery.of(context).size.width < 768;
    final width = isMobile ? 200.0 : 240.0;
    final thumb =
        item.thumbnailUrl.isNotEmpty ? item.thumbnailUrl : item.thumbnailPath;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onNavigate(3), // PageIndices.media
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // FIX BUG 4: OptimizedImage(assetPath) ne peut pas
                      // charger des URLs Firebase Storage (https://).
                      // On utilise CachedNetworkImage pour les URLs réseau.
                      AnimatedScale(
                        scale: _hovered ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        child: thumb.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: thumb,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    Container(color: AzizColors.lightSurface),
                                errorWidget: (_, __, ___) =>
                                    Container(color: AzizColors.lightSurface),
                              )
                            : OptimizedImage(
                                assetPath: thumb,
                                fit: BoxFit.cover,
                                errorWidget:
                                    Container(color: AzizColors.lightSurface),
                              ),
                      ),
                      if (item.type == MediaType.video)
                        const Center(
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AzizColors.lightBackground
                                .withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            item.type.getLabel(context),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AzizColors.saffronDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.getTitle(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AzizColors.lightTextPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.source,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AzizColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ARTWORK DETAIL DIALOG — modale de détail d'une œuvre
// ─────────────────────────────────────────────────────────────────────────────
class _ArtworkDetailDialog extends StatelessWidget {
  final Artwork artwork;
  final bool isEn;
  const _ArtworkDetailDialog({required this.artwork, required this.isEn});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final available = artwork.isAvailable;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 48,
            vertical: isMobile ? 24 : 48,
          ),
          constraints: const BoxConstraints(maxWidth: 880),
          decoration: BoxDecoration(
            color: AzizColors.lightBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Image ────────────────────────────────────────────────────
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: isMobile ? 260 : 400,
                  ),
                  child: artwork.hasNetworkImage
                      ? CachedNetworkImage(
                          imageUrl: artwork.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              color: AzizColors.lightSurface, height: 300),
                          errorWidget: (_, __, ___) => Container(
                              color: AzizColors.lightSurface, height: 300),
                        )
                      : OptimizedImage(
                          assetPath: artwork.imagePath,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                              color: AzizColors.lightSurface, height: 300),
                        ),
                ),
              ),
              // ── Info ─────────────────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              artwork.title,
                              style: const TextStyle(
                                fontFamily: 'Playfair Display',
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AzizColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: available
                                  ? AzizColors.saffron
                                  : AzizColors.terraCotta,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              available
                                  ? (isEn ? 'AVAILABLE' : 'DISPONIBLE')
                                  : (isEn ? 'SOLD' : 'VENDU'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        artwork.category,
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AzizColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // ── Infos techniques ──────────────────────────────────
                      _DetailRow(
                        label: isEn ? 'TECHNIQUE' : 'TECHNIQUE',
                        value: artwork.technique.isNotEmpty
                            ? artwork.technique
                            : 'Batik',
                      ),
                      if (artwork.dimensions.isNotEmpty)
                        _DetailRow(
                          label: isEn ? 'DIMENSIONS' : 'DIMENSIONS',
                          value: artwork.dimensions,
                        ),
                      if (artwork.year.isNotEmpty)
                        _DetailRow(
                          label: isEn ? 'YEAR' : 'ANNÉE',
                          value: artwork.year,
                        ),
                      if (artwork.price != null && artwork.price! > 0)
                        _DetailRow(
                          label: isEn ? 'PRICE' : 'PRIX',
                          value: '${artwork.price!.toStringAsFixed(0)} €',
                        )
                      else
                        _DetailRow(
                          label: isEn ? 'PRICE' : 'PRIX',
                          value: isEn ? 'On request' : 'Sur demande',
                        ),
                      if (artwork.descriptionFr.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          isEn ? artwork.descriptionEn : artwork.descriptionFr,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AzizColors.lightTextSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // ── Bouton fermer ────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              isEn ? 'Close' : 'Fermer',
                              style: const TextStyle(
                                color: AzizColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AzizColors.saffronDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AzizColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEWS & EVENTS SECTION — actualités publiées depuis l'admin hub
// FIX: HomeEventService.watchPublished() n'était jamais utilisé.
// Cette section écoute le stream Firestore et s'auto-rafraîchit en temps réel.
// ─────────────────────────────────────────────────────────────────────────────
//
// FIX PERFORMANCE (page d'accueil lente) : cette section était un
// StatelessWidget qui appelait `HomeEventService().watchPublished()`
// directement dans build(). Or build() est ré-exécuté à chaque fois que
// AppDataProvider notifie un changement — y compris pour des données qui
// n'ont rien à voir avec les actualités (nouvelle œuvre, nouvelle photo
// d'atelier…). Résultat : une TOUTE NOUVELLE requête/écoute Firestore
// était recréée à chaque fois, provoquant un clignotement de la section
// et de nombreuses lectures Firestore inutiles.
// Passage en StatefulWidget : le Stream est désormais créé UNE SEULE
// FOIS, dans initState (via `late final`), puis réutilisé à chaque
// rebuild.
class _NewsEventsSection extends StatefulWidget {
  final void Function(int) onNavigate;
  const _NewsEventsSection({required this.onNavigate});

  @override
  State<_NewsEventsSection> createState() => _NewsEventsSectionState();
}

class _NewsEventsSectionState extends State<_NewsEventsSection> {
  final _service = HomeEventService();
  List<HomeEvent> _events = [];
  StreamSubscription<List<HomeEvent>>? _sub;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _sub = _service.watchPublished().listen(
      (events) {
        if (mounted) setState(() => _events = events);
      },
      onError: (e) {
        debugPrint('_NewsEventsSection: flux temps réel indisponible ($e) — '
            'passage en actualisation périodique.');
        _startFallbackPolling();
      },
    );
  }

  // FIX (robustesse) : si le flux temps réel Supabase échoue (ex. réseau
  // qui bloque les connexions WebSocket — c'est le cas le plus fréquent
  // sur certains réseaux d'entreprise/VPN/antivirus), on ne reste plus
  // bloqué sans données pour toujours : on interroge la base normalement
  // (HTTPS classique, pas de WebSocket) toutes les 45 secondes à la place.
  void _startFallbackPolling() {
    if (_pollTimer != null) return; // déjà en mode dégradé
    _pollOnce();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 45), (_) => _pollOnce());
  }

  Future<void> _pollOnce() async {
    try {
      final events = await _service.fetchPublished();
      if (mounted) setState(() => _events = events);
    } catch (e) {
      debugPrint('_NewsEventsSection: échec actualisation périodique — $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.maybeLocaleOf(context)?.languageCode == 'en';

    // Rien à afficher s'il n'y a pas d'événements publiés
    if (_events.isEmpty) {
      return const SizedBox.shrink();
    }
    final events = _events;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête ─────────────────────────────────────────────────
          Text(
            isEn ? 'NEWS & EVENTS' : 'ACTUALITÉS & ÉVÉNEMENTS',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              color: AzizColors.saffron,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AzizColors.lightBorder, thickness: 0.5),
          const SizedBox(height: 24),
          // ── Cartes ──────────────────────────────────────────────────
          SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, i) =>
                  _EventCard(event: events[i], isEn: isEn),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final HomeEvent event;
  final bool isEn;
  const _EventCard({required this.event, required this.isEn});

  String get _typeLabel {
    switch (event.type) {
      case 'event':
        return isEn ? 'EVENT' : 'ÉVÉNEMENT';
      case 'exhibition':
        return isEn ? 'EXHIBITION' : 'EXPOSITION';
      default:
        return isEn ? 'NEWS' : 'ACTUALITÉ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = isEn ? event.titleEn : event.titleFr;
    final desc = isEn ? event.descriptionEn : event.descriptionFr;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AzizColors.lightCard,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image ou placeholder coloré selon le type
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: event.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: event.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AzizColors.lightSurface),
                      errorWidget: (_, __, ___) =>
                          Container(color: AzizColors.lightSurface),
                    )
                  : Container(
                      color: AzizColors.saffron.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.campaign_outlined,
                        size: 40,
                        color: AzizColors.saffron,
                      ),
                    ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AzizColors.saffron.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      _typeLabel,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AzizColors.saffronDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title.isNotEmpty ? title : event.titleFr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AzizColors.lightTextPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      desc.isNotEmpty ? desc : event.descriptionFr,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AzizColors.lightTextSecondary,
                        height: 1.4,
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

// ─────────────────────────────────────────────────────────────────────────────
// 5 · CITATION
// ─────────────────────────────────────────────────────────────────────────────
class _QuoteSection extends StatelessWidget {
  const _QuoteSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final hPad = isMobile ? 24.0 : 120.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: AzizColors.saffron.withValues(alpha: 0.3),
            size: isMobile ? 48 : 64,
          ),
          const SizedBox(height: 32),
          Text(
            context.tr('home.quote'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontStyle: FontStyle.italic,
              fontSize: isMobile ? 22 : 36,
              height: 1.6,
              color: AzizColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 40, height: 1, color: AzizColors.saffron),
              const SizedBox(width: 16),
              const Text(
                'OLGA INDIGO',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 12,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w600,
                  color: AzizColors.saffron,
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 40, height: 1, color: AzizColors.saffron),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6 · SECTION EXPLORATION
// ─────────────────────────────────────────────────────────────────────────────
class _ExploreSection extends StatelessWidget {
  final Function(int) onNavigate;

  const _ExploreSection({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final hPad = isMobile ? 24.0 : 60.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: hPad),
      padding: EdgeInsets.symmetric(vertical: isMobile ? 60 : 100),
      decoration: BoxDecoration(
        color: AzizColors.lightBackgroundAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AzizColors.saffron.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _SectionTag(context.tr('home.explore_tag')),
          const SizedBox(height: 24),
          Text(
            context.tr('home.explore_title'),
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: isMobile ? 32 : 48,
              fontWeight: FontWeight.w300,
              color: AzizColors.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              context.tr('home.explore_subtitle'),
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 15,
                color: AzizColors.lightTextSecondary,
                height: 1.8,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),
          _HeroBtn(
            label: context.tr('home.view_full_gallery'),
            onTap: () => onNavigate(1),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FOOTER
// ─────────────────────────────────────────────────────────────────────────────
class _FooterSection extends StatelessWidget {
  const _FooterSection();

  static const String _whatsappUrl = 'https://wa.me/2290166495217';
  static const String _email = 'olga_indigo@yahoo.com';
  static const String _youtubeUrl = 'https://www.youtube.com/@azizart-color';
  static const String _instagramUrl =
      'https://www.instagram.com/indigoolga25?igsh=MTdjbGk1NW80bmtmaw==';
  static const String _tiktokUrl = 'https://www.tiktok.com/@olga.indigo';
  static const String _facebookUrl =
      'https://www.facebook.com/profile.php?id=100074832580615';

  // FIX : même correction que ContactPage/_SocialFollowSection —
  // `canLaunchUrl` bloquait silencieusement WhatsApp/e-mail/réseaux
  // sociaux dans le pied de page.
  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        debugPrint('FooterSection: launchUrl a échoué pour $uri');
      }
    } catch (e) {
      debugPrint('FooterSection: impossible d\'ouvrir $uri — $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 60,
        vertical: 80,
      ),
      decoration: BoxDecoration(
        color: AzizColors.lightBackgroundAlt,
        border: Border(
          top: BorderSide(
            color: AzizColors.saffron.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 32 : 48),
            decoration: BoxDecoration(
              color: AzizColors.lightCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AzizColors.saffron.withValues(alpha: 0.1),
              ),
            ),
            child: isMobile
                ? Column(
                    children: [
                      _footerContactText(context),
                      const SizedBox(height: 32),
                      _footerContactBtns(context, isMobile: true),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _footerContactText(context)),
                      const SizedBox(width: 48),
                      _footerContactBtns(context, isMobile: false),
                    ],
                  ),
          ),
          const SizedBox(height: 80),
          Text(
            'AZIZART',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 28,
              letterSpacing: 8,
              color: AzizColors.lightTextPrimary.withValues(alpha: 0.9),
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('home.footer_tagline'),
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 13,
              color: AzizColors.lightTextSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _footerSocialIcon(
                  FontAwesomeIcons.whatsapp, () => _launch(_whatsappUrl)),
              const SizedBox(width: 16),
              _footerSocialIcon(
                  FontAwesomeIcons.youtube, () => _launch(_youtubeUrl)),
              const SizedBox(width: 16),
              _footerSocialIcon(
                  FontAwesomeIcons.instagram, () => _launch(_instagramUrl)),
              const SizedBox(width: 16),
              _footerSocialIcon(
                  FontAwesomeIcons.tiktok, () => _launch(_tiktokUrl)),
              const SizedBox(width: 16),
              _footerSocialIcon(
                  FontAwesomeIcons.facebook, () => _launch(_facebookUrl)),
              const SizedBox(width: 16),
              _footerSocialIcon(
                  FontAwesomeIcons.envelope, () => _launch('mailto:$_email')),
            ],
          ),
          const SizedBox(height: 48),
          Container(
            width: 60,
            height: 1,
            color: AzizColors.saffron.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 32),
          Text(
            '© ${DateTime.now().year} Olga Indigo · AzizArt · Cotonou, Bénin',
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 11,
              color: AzizColors.lightTextMuted,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Boutons WhatsApp + Email ─────────────────────────────────────────────
  Widget _footerContactBtns(BuildContext context, {required bool isMobile}) {
    final waBtn = _FooterBtn(
      icon: FontAwesomeIcons.whatsapp,
      label: 'WhatsApp',
      onTap: () => _launch(_whatsappUrl),
      isPrimary: true,
    );
    final emailBtn = _FooterBtn(
      icon: FontAwesomeIcons.envelope,
      label: context.tr('home.footer_email_btn'),
      onTap: () => _launch('mailto:$_email'),
    );
    if (isMobile) {
      return Column(children: [
        waBtn,
        const SizedBox(height: 12),
        emailBtn,
      ]);
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      waBtn,
      const SizedBox(width: 12),
      emailBtn,
    ]);
  }

  Widget _footerContactText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('home.footer_cta_title'),
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: AzizColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('home.footer_cta_subtitle'),
          style: const TextStyle(
            fontSize: 15,
            color: AzizColors.lightTextSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _footerSocialIcon(FaIconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AzizColors.saffron.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: FaIcon(icon, size: 18, color: AzizColors.saffron),
        ),
      ),
    );
  }
}

class _FooterBtn extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _FooterBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: isMobile ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? AzizColors.saffron : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary
                ? Colors.transparent
                : AzizColors.saffron.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment:
              isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            FaIcon(icon,
                color:
                    isPrimary ? AzizColors.backgroundDark : AzizColors.saffron,
                size: 16),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color:
                    isPrimary ? AzizColors.backgroundDark : AzizColors.saffron,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
