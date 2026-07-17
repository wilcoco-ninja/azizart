import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/localization/language_provider.dart';
import '../gallery/models/artwork.dart';
import '../gallery/models/gallery_category.dart';
import '../../theme/aziz_colors.dart';
import '../../widgets/optimized_image.dart';
import 'package:provider/provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
// GalleryPage — galerie complète avec filtres catégorie + disponibilité
//
// FIX vs ancienne version :
//   • Les cartes œuvres sont maintenant cliquables (GestureDetector → modale)
//   • Les images Firebase Storage (imageUrl) sont chargées via
//     CachedNetworkImage — plus d'affichage blanc pour les œuvres admin
//   • GalleryNavigationRequest permet à la home page de pré-sélectionner
//     une catégorie avant que cette page soit construite
// ══════════════════════════════════════════════════════════════════════════════
class GalleryPage extends StatefulWidget {
  final List<Artwork> artworkList;
  const GalleryPage({super.key, required this.artworkList});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  GalleryCategory? _selectedCategory;
  // 'all' | 'available' | 'sold'
  String _availFilter = 'all';

  @override
  void initState() {
    super.initState();
    // Récupère la demande de filtrage catégorie depuis la home page
    _selectedCategory = GalleryNavigationRequest.consume();
  }

  List<Artwork> get _filtered {
    var list = widget.artworkList;

    // Filtre catégorie
    if (_selectedCategory != null) {
      final vals = _selectedCategory!.filterValues;
      list = list.where((a) => vals.contains(a.category)).toList();
    }

    // Filtre disponibilité
    if (_availFilter == 'available') list = list.where((a) => a.isAvailable).toList();
    if (_availFilter == 'sold')      list = list.where((a) => !a.isAvailable).toList();

    return list;
  }

  void _showDetail(BuildContext context, Artwork artwork) {
    final isEn = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'fermer',
      barrierColor: Colors.black.withValues(alpha: 0.88),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) =>
          _ArtworkDetailModal(artwork: artwork, isEn: isEn),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final isEn   = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    final width  = MediaQuery.of(context).size.width;
    final mobile = width < 640;
    final cols   = mobile ? 2 : (width < 1024 ? 3 : 4);
    final hPad   = mobile ? 16.0 : 40.0;
    final list   = _filtered;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [

        // ── Bannière ────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _GalleryBanner(isEn: isEn),
        ),

        // ── Barre de filtres (sticky) ────────────────────────────────────
        SliverPersistentHeader(
          pinned: true,
          delegate: _FilterBarDelegate(
            isEn: isEn,
            selectedCategory: _selectedCategory,
            availFilter: _availFilter,
            onCategoryChanged: (cat) =>
                setState(() => _selectedCategory = cat),
            onAvailChanged: (f) => setState(() => _availFilter = f),
          ),
        ),

        // ── Compteur ────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 8),
            child: Text(
              '${list.length} ${isEn ? "artwork${list.length > 1 ? "s" : ""}" : "œuvre${list.length > 1 ? "s" : ""}"}',
              style: const TextStyle(
                color: AzizColors.lightTextSecondary,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),

        // ── Grille ─────────────────────────────────────────────────────────
        list.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Text(
                    isEn ? 'No artworks in this category.'
                         : 'Aucune œuvre dans cette catégorie.',
                    style: const TextStyle(
                      color: AzizColors.lightTextSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            : SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ArtworkCard(
                      artwork: list[i],
                      isEn: isEn,
                      onTap: () => _showDetail(context, list[i]),
                    ),
                    childCount: list.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:    cols,
                    crossAxisSpacing:  mobile ? 10 : 16,
                    mainAxisSpacing:   mobile ? 10 : 16,
                    childAspectRatio:  mobile ? 0.72 : 0.78,
                  ),
                ),
              ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ── Bannière ──────────────────────────────────────────────────────────────────
class _GalleryBanner extends StatelessWidget {
  final bool isEn;
  const _GalleryBanner({required this.isEn});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(40, 60, 40, 40),
      color: AzizColors.lightBackground,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          isEn ? 'GALLERY' : 'GALERIE',
          style: const TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 48,
            fontWeight: FontWeight.w300,
            color: AzizColors.lightTextPrimary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isEn ? 'Original Works · Batik on canvas & fabric · Cotonou, Benin'
               : 'Œuvres Originales · Batik sur toile & tissu · Cotonou, Bénin',
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 13,
            color: AzizColors.lightTextSecondary,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.5,
          ),
        ),
      ]),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────
class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final bool isEn;
  final GalleryCategory? selectedCategory;
  final String availFilter;
  final ValueChanged<GalleryCategory?> onCategoryChanged;
  final ValueChanged<String> onAvailChanged;

  _FilterBarDelegate({
    required this.isEn, required this.selectedCategory,
    required this.availFilter, required this.onCategoryChanged,
    required this.onAvailChanged,
  });

  @override double get maxExtent => 116;
  @override double get minExtent => 116;
  @override bool shouldRebuild(_FilterBarDelegate old) =>
      old.selectedCategory != selectedCategory ||
      old.availFilter != availFilter ||
      old.isEn != isEn;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AzizColors.lightBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Rangée 1 : catégories
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: isEn ? 'All' : 'Tout',
                  selected: selectedCategory == null,
                  onTap: () => onCategoryChanged(null),
                ),
                const SizedBox(width: 8),
                ...GalleryCategory.values.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: cat.label(ctx),
                    selected: selectedCategory == cat,
                    onTap: () => onCategoryChanged(
                        selectedCategory == cat ? null : cat),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Rangée 2 : disponibilité
          Row(children: [
            _SmallChip(
              label: isEn ? 'All' : 'Tout',
              selected: availFilter == 'all',
              onTap: () => onAvailChanged('all'),
            ),
            const SizedBox(width: 8),
            _SmallChip(
              label: isEn ? 'Available' : 'Disponibles',
              selected: availFilter == 'available',
              onTap: () => onAvailChanged('available'),
              color: AzizColors.greenBatik,
            ),
            const SizedBox(width: 8),
            _SmallChip(
              label: isEn ? 'Sold' : 'Vendus',
              selected: availFilter == 'sold',
              onTap: () => onAvailChanged('sold'),
              color: AzizColors.terraCotta,
            ),
          ]),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AzizColors.saffron : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AzizColors.saffron : AzizColors.lightBorder,
          width: selected ? 0 : 0.5,
        ),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5,
        color: selected ? Colors.black : AzizColors.lightTextSecondary,
      )),
    ),
  );
}

class _SmallChip extends StatelessWidget {
  final String label; final bool selected;
  final VoidCallback onTap; final Color? color;
  const _SmallChip({required this.label, required this.selected,
      required this.onTap, this.color});
  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? (color ?? AzizColors.lightTextPrimary).withValues(alpha: 0.12)
                        : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: selected ? (color ?? AzizColors.lightTextPrimary) : AzizColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2,
        color: selected ? (color ?? AzizColors.lightTextPrimary)
                        : AzizColors.lightTextSecondary,
      )),
    ),
  );
}

// ── Artwork Card ──────────────────────────────────────────────────────────────
class _ArtworkCard extends StatefulWidget {
  final Artwork artwork; final bool isEn; final VoidCallback onTap;
  const _ArtworkCard({required this.artwork, required this.isEn, required this.onTap});
  @override State<_ArtworkCard> createState() => _ArtworkCardState();
}

class _ArtworkCardState extends State<_ArtworkCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 250));
    _scale = Tween<double>(begin: 1.0, end: 1.02)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final art = widget.artwork;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) { setState(() => _hovered = true);  _ctrl.forward(); },
      onExit:  (_) { setState(() => _hovered = false); _ctrl.reverse(); },
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            decoration: BoxDecoration(
              color: AzizColors.lightCard,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? 0.22 : 0.10),
                blurRadius: _hovered ? 20 : 8,
                offset: const Offset(0, 4),
              )],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Image
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: Stack(fit: StackFit.expand, children: [
                    art.hasNetworkImage
                        ? CachedNetworkImage(
                            imageUrl: art.imageUrl, fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AzizColors.lightSurface),
                            errorWidget: (_, __, ___) => Container(color: AzizColors.lightSurface))
                        : OptimizedImage(assetPath: art.imagePath, fit: BoxFit.cover),
                    // Badge dispo
                    Positioned(top: 10, right: 10, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: art.isAvailable
                            ? AzizColors.saffron.withValues(alpha: 0.95)
                            : AzizColors.terraCotta.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(3)),
                      child: Text(
                        art.isAvailable
                            ? (widget.isEn ? 'AVAILABLE' : 'DISPONIBLE')
                            : (widget.isEn ? 'SOLD' : 'VENDU'),
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                            letterSpacing: 1.2, color: Colors.white)),
                    )),
                    // Loupe
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _hovered ? 1.0 : 0.0,
                      child: Positioned(bottom: 10, right: 10, child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle),
                        child: const Icon(Icons.open_in_full_rounded,
                            color: Colors.white, size: 13),
                      )),
                    ),
                  ]),
                ),
              ),
              // Titre + catégorie
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(art.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Georgia', fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AzizColors.lightTextPrimary)),
                    const SizedBox(height: 3),
                    Text(art.category, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10,
                            color: AzizColors.lightTextSecondary,
                            fontStyle: FontStyle.italic)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Artwork Detail Modal ──────────────────────────────────────────────────────
class _ArtworkDetailModal extends StatelessWidget {
  final Artwork artwork; final bool isEn;
  const _ArtworkDetailModal({required this.artwork, required this.isEn});

  @override
  Widget build(BuildContext context) {
    final art    = artwork;
    final mobile = MediaQuery.of(context).size.width < 700;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: EdgeInsets.symmetric(
              horizontal: mobile ? 12 : 48, vertical: mobile ? 20 : 48),
          constraints: const BoxConstraints(maxWidth: 900),
          decoration: BoxDecoration(
              color: AzizColors.lightBackground,
              borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: mobile ? 240 : 380),
                child: art.hasNetworkImage
                    ? CachedNetworkImage(
                        imageUrl: art.imageUrl, width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AzizColors.lightSurface, height: 300),
                        errorWidget:  (_, __, ___) => Container(color: AzizColors.lightSurface, height: 300))
                    : OptimizedImage(assetPath: art.imagePath, fit: BoxFit.cover,
                        errorWidget: Container(color: AzizColors.lightSurface, height: 300)),
              ),
            ),
            // Infos
            Flexible(child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(art.title, style: const TextStyle(
                      fontFamily: 'Playfair Display', fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AzizColors.lightTextPrimary))),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: art.isAvailable ? AzizColors.saffron : AzizColors.terraCotta,
                      borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      art.isAvailable
                          ? (isEn ? 'AVAILABLE' : 'DISPONIBLE')
                          : (isEn ? 'SOLD' : 'VENDU'),
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                          letterSpacing: 1.5, color: Colors.white)),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(art.category, style: const TextStyle(fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AzizColors.lightTextSecondary)),
                const SizedBox(height: 18),
                if (art.technique.isNotEmpty) _Row(isEn ? 'TECHNIQUE' : 'TECHNIQUE', art.technique),
                if (art.dimensions.isNotEmpty) _Row(isEn ? 'DIMENSIONS' : 'DIMENSIONS', art.dimensions),
                if (art.year.isNotEmpty) _Row(isEn ? 'YEAR' : 'ANNÉE', art.year),
                _Row(
                  isEn ? 'PRICE' : 'PRIX',
                  (art.price != null && art.price! > 0)
                      ? '${art.price!.toStringAsFixed(0)} €'
                      : (isEn ? 'On request' : 'Sur demande'),
                ),
                if ((isEn ? art.descriptionEn : art.descriptionFr).isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(isEn ? art.descriptionEn : art.descriptionFr,
                      style: const TextStyle(fontSize: 14, height: 1.6,
                          color: AzizColors.lightTextSecondary)),
                ],
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(isEn ? 'Close' : 'Fermer',
                        style: const TextStyle(color: AzizColors.lightTextSecondary)),
                  ),
                ),
              ]),
            )),
          ]),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5,
          color: AzizColors.saffronDark))),
      Expanded(child: Text(value, style: const TextStyle(
          fontSize: 13, color: AzizColors.lightTextPrimary))),
    ]),
  );
}