import 'package:flutter/material.dart';

import '../../theme/aziz_colors.dart';
import '../../widgets/artwork_viewer.dart';
import '../../widgets/optimized_image.dart';
import '../home/shared_components.dart';
import 'models/artwork.dart';
import 'models/gallery_category.dart';

class GalleryPage extends StatefulWidget {
  final List<Artwork> artworkList;

  const GalleryPage({super.key, required this.artworkList});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  GalleryCategory? _selectedCategory;
  String _availFilter = 'available';

  static const String _heroTagPrefix = 'gallery';

  /// Hauteur du cartel sous chaque œuvre.
  static const double _labelHeight = 96;

  /// Proportion des cadres (largeur / hauteur).
  static const double _matRatio = 0.8;

  @override
  void initState() {
    super.initState();
    _selectedCategory = GalleryNavigationRequest.consume();
  }

  List<Artwork> get _filteredArtworks {
    return widget.artworkList.where((artwork) {
      final matchesAvail = _availFilter == 'available'
          ? artwork.isAvailable
          : !artwork.isAvailable;
      if (!matchesAvail) return false;

      final category = _selectedCategory;
      if (category == null) return true;

      return category.matches(artwork.category);
    }).toList();
  }

  int _columnsFor(double width) {
    if (width < 600) return 2;
    if (width < 1280) return 3;
    return 4;
  }

  void _resetFilters() => setState(() {
        _selectedCategory = null;
        _availFilter = 'available';
      });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;
    final isEn = homeIsEn(context);
    final gutter = homeGutter(context);

    final columns = _columnsFor(width);
    final columnGap = isMobile ? 16.0 : 28.0;
    final rowGap = isMobile ? 28.0 : 44.0;
    final contentWidth = width - 2 * gutter;
    final tileWidth = (contentWidth - columnGap * (columns - 1)) / columns;
    final tileHeight = tileWidth / _matRatio + _labelHeight;

    final filteredArtworks = _filteredArtworks;

    return Scaffold(
      backgroundColor: AzizColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                gutter,
                isMobile ? 48 : 72,
                gutter,
                isMobile ? 32 : 48,
              ),
              child: _GalleryIntro(isEn: isEn, isMobile: isMobile),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterBarDelegate(
              isEn: isEn,
              gutter: gutter,
              count: filteredArtworks.length,
              selectedCategory: _selectedCategory,
              availFilter: _availFilter,
              onCategoryChanged: (cat) =>
                  setState(() => _selectedCategory = cat),
              onAvailChanged: (f) => setState(() => _availFilter = f),
            ),
          ),
          if (filteredArtworks.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: _EmptyState(isEn: isEn, onReset: _resetFilters),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                gutter,
                isMobile ? 28 : 40,
                gutter,
                isMobile ? 72 : 112,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: columnGap,
                  mainAxisSpacing: rowGap,
                  mainAxisExtent: tileHeight,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final artwork = filteredArtworks[index];
                    return _ArtworkTile(
                      key: ValueKey(artwork.id),
                      artwork: artwork,
                      heroTagPrefix: _heroTagPrefix,
                      isEn: isEn,
                      matRatio: _matRatio,
                      onTap: () => ArtworkViewer.open(
                        context,
                        artworks: filteredArtworks,
                        initialIndex: index,
                        isEn: isEn,
                        heroTagPrefix: _heroTagPrefix,
                      ),
                    );
                  },
                  childCount: filteredArtworks.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EN-TÊTE
// ═══════════════════════════════════════════════════════════════════════════

class _GalleryIntro extends StatelessWidget {
  final bool isEn;
  final bool isMobile;

  const _GalleryIntro({required this.isEn, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            isEn ? 'The collection' : 'La collection',
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
                ? 'Unique batik pieces, hand-dyed with natural pigments.'
                : 'Pièces uniques en batik, teintes à la main avec des pigments naturels.',
            style: homeSans(size: isMobile ? 15 : 17, height: 1.7),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ŒUVRE SUR SON PASSE-PARTOUT + CARTEL
// ═══════════════════════════════════════════════════════════════════════════

class _ArtworkTile extends StatefulWidget {
  final Artwork artwork;
  final String heroTagPrefix;
  final bool isEn;
  final double matRatio;
  final VoidCallback onTap;

  const _ArtworkTile({
    super.key,
    required this.artwork,
    required this.heroTagPrefix,
    required this.isEn,
    required this.matRatio,
    required this.onTap,
  });

  @override
  State<_ArtworkTile> createState() => _ArtworkTileState();
}

class _ArtworkTileState extends State<_ArtworkTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final artwork = widget.artwork;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Semantics(
        button: true,
        label: artwork.title,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: widget.matRatio,
                child: HomeMat(
                  raised: _hovered,
                  padding: 12,
                  child: Hero(
                    tag: '${widget.heroTagPrefix}-artwork-${artwork.id}',
                    child: OptimizedImage(
                      url: artwork.displayImage,
                      // Jamais recadrée : l'œuvre est montrée en entier.
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      memCacheWidth: 800,
                      errorWidget: Container(
                        color: AzizColors.lightSurface,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AzizColors.lightTextSecondary,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _WallLabel(artwork: artwork, isEn: widget.isEn),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cartel de musée : titre en italique, technique et année, dimensions,
/// disponibilité.
class _WallLabel extends StatelessWidget {
  final Artwork artwork;
  final bool isEn;

  const _WallLabel({required this.artwork, required this.isEn});

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (artwork.technique.trim().isNotEmpty) artwork.technique.trim(),
      if (artwork.year.trim().isNotEmpty) artwork.year.trim(),
    ].join(', ');
    final secondary = details.isNotEmpty ? details : artwork.category.trim();

    final price = artwork.price;
    final priceLabel = (price != null && price > 0)
        ? '${price.toStringAsFixed(0)} €'
        : (isEn ? 'Price on request' : 'Prix sur demande');
    final measure = artwork.dimensions.trim().isNotEmpty
        ? artwork.dimensions.trim()
        : priceLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          artwork.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: homeSerif(
            size: 17,
            style: FontStyle.italic,
            height: 1.25,
          ),
        ),
        if (secondary.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            secondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: homeSans(size: 13, height: 1.4),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                measure,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: homeSans(
                  size: 12.5,
                  color: AzizColors.lightTextMuted,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _Availability(available: artwork.isAvailable, isEn: isEn),
          ],
        ),
      ],
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
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: available ? AzizColors.saffron : AzizColors.terraCotta,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          available
              ? (isEn ? 'Available' : 'Disponible')
              : (isEn ? 'Sold' : 'Vendu'),
          style: homeSans(
            size: 12.5,
            color: AzizColors.lightTextPrimary,
            weight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ÉTAT VIDE
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final bool isEn;
  final VoidCallback onReset;

  const _EmptyState({required this.isEn, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEn
                ? 'No works in this selection.'
                : 'Aucune œuvre dans cette sélection.',
            style: homeSerif(size: 26, height: 1.2),
          ),
          const SizedBox(height: 10),
          Text(
            isEn
                ? 'Choose another category, or see the whole collection.'
                : 'Choisissez une autre catégorie, ou voyez toute la collection.',
            style: homeSans(size: 15, height: 1.6),
          ),
          const SizedBox(height: 24),
          GhostBtn(
            label: isEn ? 'See the whole collection' : 'Voir toute la collection',
            leading: const Icon(HomeIcons.gallery),
            onTap: onReset,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BARRE DE FILTRES (épinglée)
// ═══════════════════════════════════════════════════════════════════════════

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final bool isEn;
  final double gutter;
  final int count;
  final GalleryCategory? selectedCategory;
  final String availFilter;
  final ValueChanged<GalleryCategory?> onCategoryChanged;
  final ValueChanged<String> onAvailChanged;

  static const double _height = 104;

  const _FilterBarDelegate({
    required this.isEn,
    required this.gutter,
    required this.count,
    required this.selectedCategory,
    required this.availFilter,
    required this.onCategoryChanged,
    required this.onAvailChanged,
  });

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  String get _countLabel {
    if (isEn) return count == 1 ? '1 work' : '$count works';
    return count > 1 ? '$count œuvres' : '$count œuvre';
  }

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: _height,
      padding: EdgeInsets.symmetric(horizontal: gutter),
      decoration: BoxDecoration(
        color: AzizColors.lightBackground,
        border: Border(
          bottom: BorderSide(
            color: AzizColors.lightBorder
                .withValues(alpha: overlapsContent ? 0.9 : 0.5),
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                _FilterTab(
                  label: isEn ? 'All' : 'Tout',
                  selected: selectedCategory == null,
                  onTap: () => onCategoryChanged(null),
                ),
                for (final cat in GalleryCategory.values)
                  _FilterTab(
                    label: cat.label(context),
                    selected: selectedCategory == cat,
                    onTap: () => onCategoryChanged(cat),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 42,
            child: Row(
              children: [
                _FilterTab(
                  label: isEn ? 'Available' : 'Disponibles',
                  selected: availFilter == 'available',
                  compact: true,
                  onTap: () => onAvailChanged('available'),
                ),
                _FilterTab(
                  label: isEn ? 'Sold' : 'Vendues',
                  selected: availFilter == 'sold',
                  compact: true,
                  onTap: () => onAvailChanged('sold'),
                ),
                const Spacer(),
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
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FilterBarDelegate oldDelegate) {
    return isEn != oldDelegate.isEn ||
        gutter != oldDelegate.gutter ||
        count != oldDelegate.count ||
        selectedCategory != oldDelegate.selectedCategory ||
        availFilter != oldDelegate.availFilter;
  }
}

/// Onglet textuel : l'onglet actif est souligné.
class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
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
                      size: compact ? 13.5 : 15,
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