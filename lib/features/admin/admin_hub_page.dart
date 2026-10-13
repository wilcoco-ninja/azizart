import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/admin_colors.dart';
import '../../widgets/optimized_image.dart';
import 'layout/layout.dart';
import '../admin_about/admin_about_page.dart';
import '../admin_about/services/about_content_service.dart';
import '../admin_gallery/admin_gallery_page.dart';
import 'admin_account_page.dart';
import '../admin_atelier/admin_atelier_page.dart';
import '../admin_media/admin_media_page.dart';
import 'home_event_form_page.dart';
import 'gallery_form_page.dart';
import 'atelier_form_page.dart';
import 'media_form_page.dart';
import '../home/models/home_event_model.dart';
import '../home/services/home_event_service.dart';
import '../gallery/models/artwork.dart';
import '../gallery/services/gallery_service.dart';
import '../atelier/models/atelier_model.dart';
import '../atelier/services/atelier_service.dart';
import '../media/models/media_model.dart';
import '../media/services/media_service.dart';

const double _kHubMaxWidth = 900;

/// Vignettes affichées sur le tableau de bord (le reste : onglet Galerie).
const int _kDashboardImageLimit = 24;

// ══════════════════════════════════════════════════════════════════════════
// HUB ADMIN — point d'entrée du back-office (Shell persistant à 5 onglets)
// ══════════════════════════════════════════════════════════════════════════

class AdminHubPage extends StatefulWidget {
  const AdminHubPage({super.key});

  @override
  State<AdminHubPage> createState() => _AdminHubPageState();
}

class _AdminHubPageState extends State<AdminHubPage> {
  int _currentIndex = 0;

  /// Onglets déjà ouverts : les autres ne sont construits (et ne chargent
  /// leurs données) qu'à la première visite.
  final Set<int> _visited = <int>{0};

  final _eventService = HomeEventService();
  final _galleryService = GalleryService();
  final _atelierService = AtelierService();
  final _mediaService = MediaService();
  final _aboutContentService = AboutContentService();

  // ─── Données (source de vérité locale, alimentée par les souscriptions) ──
  List<HomeEvent> _events = const [];
  List<Artwork> _artworks = const [];
  List<AtelierPhoto> _atelierPhotos = const [];
  List<MediaItem> _mediaItems = const [];

  // ─── États de chargement / erreur par source ─────────────────────────────
  bool _loadingEvents = true;
  bool _loadingArtworks = true;
  bool _loadingMedia = true;

  Object? _eventsError;
  Object? _artworksError;
  Object? _mediaError;

  // ─── Souscriptions (annulées dans dispose) ───────────────────────────────
  StreamSubscription<List<HomeEvent>>? _eventsSub;
  StreamSubscription<List<Artwork>>? _artworksSub;
  StreamSubscription<List<AtelierPhoto>>? _atelierSub;
  StreamSubscription<List<MediaItem>>? _mediaSub;

  // ─── Profil affiché dans le header ───────────────────────────────────────
  String _artistName = 'Olga Indigo';
  String _artistTitle = 'Artiste Peintre & Batikiste';
  static const String _bioText =
      "Découvrez l'univers AzizArt. \nCréations uniques et artisanales.";
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadAboutContent();
    _subscribeAll();
  }

  void _subscribeAll() {
    _eventsSub = _eventService.watchAll().listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _events = list;
          _loadingEvents = false;
          _eventsError = null;
        });
      },
      onError: (Object e) {
        debugPrint('AdminHub: stream events error — $e');
        if (!mounted) return;
        setState(() {
          _loadingEvents = false;
          _eventsError = e;
        });
      },
    );

    _artworksSub = _galleryService.watchArtworks().listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _artworks = list;
          _loadingArtworks = false;
          _artworksError = null;
        });
      },
      onError: (Object e) {
        debugPrint('AdminHub: stream artworks error — $e');
        if (!mounted) return;
        setState(() {
          _loadingArtworks = false;
          _artworksError = e;
        });
      },
    );

    _atelierSub = _atelierService.watchPhotos(adminOnly: true).listen(
      (list) {
        if (!mounted) return;
        setState(() => _atelierPhotos = list);
      },
      onError: (Object e) {
        debugPrint('AdminHub: stream atelier error — $e');
      },
    );

    _mediaSub = _mediaService.watchAll().listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _mediaItems = list;
          _loadingMedia = false;
          _mediaError = null;
        });
      },
      onError: (Object e) {
        debugPrint('AdminHub: stream media error — $e');
        if (!mounted) return;
        setState(() {
          _loadingMedia = false;
          _mediaError = e;
        });
      },
    );
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _artworksSub?.cancel();
    _atelierSub?.cancel();
    _mediaSub?.cancel();
    super.dispose();
  }

  /// Relance tous les flux après une erreur (les anciens sont annulés).
  void _retryStreams() {
    _eventsSub?.cancel();
    _artworksSub?.cancel();
    _atelierSub?.cancel();
    _mediaSub?.cancel();
    setState(() {
      _loadingEvents = true;
      _loadingArtworks = true;
      _loadingMedia = true;
      _eventsError = null;
      _artworksError = null;
      _mediaError = null;
    });
    _subscribeAll();
  }

  Future<void> _loadAboutContent() async {
    try {
      final data = await _aboutContentService.getContent();
      if (data == null || !mounted) return;

      final rawAvatar = (data['avatar_path'] ?? data['avatar_url']) as String?;
      final avatar =
          (rawAvatar == null || rawAvatar.trim().isEmpty) ? null : rawAvatar.trim();
      final name = (data['artist_name'] ?? data['artist_name_fr']) as String?;
      final title = (data['artist_title'] ?? data['artist_title_fr']) as String?;

      setState(() {
        if (avatar != null && avatar.isNotEmpty) _avatarUrl = avatar;
        if (name != null && name.isNotEmpty) _artistName = name;
        if (title != null && title.isNotEmpty) _artistTitle = title;
      });
    } catch (e, stack) {
      debugPrint('AdminHub: échec chargement about_content — $e\n$stack');
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // NAVIGATION & ACTIONS
  // ══════════════════════════════════════════════════════════════════════
  void _handleNavTap(int index) {
    final leavingAbout = _currentIndex == 4 && index != 4;
    setState(() {
      _currentIndex = index;
      _visited.add(index);
    });
    // L'avatar, le nom et le titre du bandeau suivent l'onglet « À propos ».
    if (leavingAbout) _loadAboutContent();
  }

  void _onAddPressed(BuildContext context) {
    _showGlobalPublicationMenu(context);
  }

  void _openMediaForm({MediaItem? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MediaFormPage(existing: existing)),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required VoidCallback onAdd,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kHubMaxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminColors.current,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.accent.withValues(alpha: 0.15),
                  foregroundColor: AdminColors.accent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: onAdd,
                icon: Icon(Icons.add_rounded, size: _getIconSize(context, 20)),
                label: const Text('Ajouter',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGlobalPublicationMenu(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 600;
    final navigator = Navigator.of(context);

    void open(Widget page) {
      navigator.pop();
      navigator.push(MaterialPageRoute(builder: (_) => page));
    }

    final publicationOptions = [
      _PublicationOption(
        icon: Icons.campaign_rounded,
        color: AdminColors.accent,
        title: 'Actualité / Événement',
        subtitle: 'Publier sur la page d\'accueil publique',
        onTap: () => open(const HomeEventFormPage()),
      ),
      _PublicationOption(
        icon: Icons.palette_rounded,
        color: AdminColors.current,
        title: 'Œuvre de la Galerie',
        subtitle: 'Ajouter une création au catalogue & boutique',
        onTap: () => open(const GalleryFormPage()),
      ),
      _PublicationOption(
        icon: Icons.handyman_rounded,
        color: const Color(0xFFE57373),
        title: 'Photo d\'Atelier',
        subtitle: 'Partager les coulisses et le geste artisanal',
        onTap: () => open(const AtelierFormPage()),
      ),
      _PublicationOption(
        icon: Icons.play_circle_fill_rounded,
        color: const Color(0xFF81C784),
        title: 'Média & Vidéo',
        subtitle: 'Ajouter un reportage, article de presse ou vidéo',
        onTap: () => open(const MediaFormPage()),
      ),
    ];

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AdminColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.add_circle_outline_rounded,
                  color: AdminColors.accent),
              SizedBox(width: 12),
              Text(
                'Gestion globale de publication',
                style: TextStyle(
                  color: AdminColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: publicationOptions,
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: AdminColors.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  height: 5,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AdminColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Publier un nouveau contenu',
                    style: TextStyle(
                      color: AdminColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...publicationOptions,
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
    }
  }

  double _getIconSize(BuildContext context, double baseSize) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1024) return baseSize + 4;
    if (width >= 600) return baseSize + 2;
    return baseSize;
  }

  Widget _lazyTab(int index, Widget Function() builder) =>
      _visited.contains(index) ? builder() : const SizedBox.shrink();

  // ══════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final unpublishedCount = _events.where((e) => !e.isPublished).length +
        _artworks.where((a) => !a.isPublished).length +
        _atelierPhotos.where((p) => !p.isPublished).length +
        _mediaItems.where((m) => !m.isPublished).length;
    return AdminScaffold(
      currentIndex: _currentIndex,
      onTap: _handleNavTap,
      onAdd: () => _onAddPressed(context),
      onAccount: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AdminAccountPage()),
      ),
      badgeCounts: {0: unpublishedCount},
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(context),
          _lazyTab(1, () => const AdminGalleryPage(embedded: true)),
          _lazyTab(2, () => const AdminAtelierPage()),
          _lazyTab(3, () => const AdminMediaPage()),
          _lazyTab(4, () => const AdminAboutPage(embedded: true)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // DASHBOARD PRINCIPAL (ONGLET 0)
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildDashboard(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Container(
        color: AdminColors.bg,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildDashboardHeader(context),
              TabBar(
                indicatorColor: AdminColors.current,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 3,
                dividerColor: Colors.transparent,
                labelColor: AdminColors.current,
                unselectedLabelColor: AdminColors.textMuted,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
                tabs: [
                  Tab(
                      icon: Icon(Icons.grid_view_rounded,
                          size: _getIconSize(context, 22)),
                      text: 'Images'),
                  Tab(
                      icon: Icon(Icons.play_circle_fill_rounded,
                          size: _getIconSize(context, 22)),
                      text: 'Vidéos'),
                  Tab(
                      icon: Icon(Icons.campaign_rounded,
                          size: _getIconSize(context, 22)),
                      text: 'Actus'),
                ],
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (BuildContext builderContext) {
                  final tabController =
                      DefaultTabController.of(builderContext);
                  return AnimatedBuilder(
                    animation: tabController,
                    builder: (context, _) {
                      switch (tabController.index) {
                        case 0:
                          return Column(children: [
                            _buildSectionHeader(
                              context,
                              title: 'Images',
                              onAdd: () => _onAddPressed(context),
                            ),
                            _buildImageGrid(context),
                          ]);
                        case 1:
                          return Column(children: [
                            _buildSectionHeader(
                              context,
                              title: 'Vidéos & médias',
                              onAdd: () => _openMediaForm(),
                            ),
                            _buildVideoGrid(context),
                          ]);
                        case 2:
                          return _buildEventList(context);
                        default:
                          return const SizedBox.shrink();
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // HEADER (profil + stats)
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildDashboardHeader(BuildContext context) {
    final artworksCount = _artworks.where((a) => a.isPublished).length;
    final atelierCount = _atelierPhotos.where((p) => p.isPublished).length;
    final mediaCount = _mediaItems.where((m) => m.isPublished).length;
    final eventsCount = _events.where((e) => e.isPublished).length;
    final publications = artworksCount + atelierCount + mediaCount;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kHubMaxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                  color: AdminColors.current.withValues(alpha: 0.3),
                  width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Builder(builder: (context) {
                      final avatarUrl = _avatarUrl;
                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AdminColors.accentHi,
                              AdminColors.accent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AdminColors.accent.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: SizedBox(
                            width: 68,
                            height: 68,
                            child: avatarUrl != null && avatarUrl.isNotEmpty
                                ? OptimizedImage(
                                    url: avatarUrl,
                                    folder: 'about_avatars',
                                    fit: BoxFit.cover,
                                    memCacheWidth: 200,
                                    borderRadius: BorderRadius.circular(34),
                                    errorWidget: Container(
                                      color: AdminColors.bg,
                                      child: Icon(
                                        Icons.person_rounded,
                                        size: _getIconSize(context, 32),
                                        color: AdminColors.textMuted,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: AdminColors.bg,
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: _getIconSize(context, 32),
                                      color: AdminColors.textMuted,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _artistName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AdminColors.text,
                                fontSize: 20,
                                letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AdminColors.surfaceHi
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _artistTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AdminColors.current,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  _bioText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AdminColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.image_rounded,
                        iconSize: _getIconSize(context, 20),
                        count: '$publications',
                        label: 'Publications',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.event_available_rounded,
                        iconSize: _getIconSize(context, 20),
                        count: '$eventsCount',
                        label: 'Événements',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.smart_display_rounded,
                        iconSize: _getIconSize(context, 20),
                        count: '$mediaCount',
                        label: 'Vidéos',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: _ModernButton(
                    text: "Modifier le profil",
                    icon: Icons.edit_rounded,
                    iconSize: _getIconSize(context, 18),
                    onTap: () => _handleNavTap(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // ONGLET IMAGES
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildImageGrid(BuildContext context) {
    if (_loadingArtworks && _artworks.isEmpty && _atelierPhotos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(
              color: AdminColors.current),
        ),
      );
    }

    if (_artworksError != null && _artworks.isEmpty) {
      return _buildErrorState(
        context: context,
        message: 'Erreur de chargement des images',
        onRetry: _retryStreams,
      );
    }

    final images = <String>[
      ..._artworks.map((a) => a.displayImage),
      ..._atelierPhotos.map((p) => p.displayImage),
    ].where((url) => url.isNotEmpty).toList();

    final visible = images.take(_kDashboardImageLimit).toList();

    if (images.isEmpty) {
      return _buildEmptyState(
        context: context,
        icon: Icons.photo_camera_back_rounded,
        message: 'Aucune image publiée pour le moment',
      );
    }

    final grid = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kHubMaxWidth),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 150,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: visible.length,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: OptimizedImage(
                url: visible[index],
                fit: BoxFit.cover,
                memCacheWidth: 400,
                borderRadius: BorderRadius.circular(16),
                errorWidget: Container(
                  color: AdminColors.surfaceHi,
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded,
                        color: AdminColors.textMuted),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    return Column(
      children: [
        grid,
        if (images.length > visible.length)
          TextButton.icon(
            onPressed: () => _handleNavTap(1),
            icon: const Icon(Icons.grid_view_rounded, size: 18),
            label: Text('Voir les ${images.length} images'),
            style: TextButton.styleFrom(foregroundColor: AdminColors.accent),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // ONGLET VIDÉOS
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildVideoGrid(BuildContext context) {
    if (_loadingMedia && _mediaItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(
              color: AdminColors.current),
        ),
      );
    }

    if (_mediaError != null && _mediaItems.isEmpty) {
      return _buildErrorState(
        context: context,
        message: 'Erreur de chargement des vidéos',
        onRetry: _retryStreams,
      );
    }

    final items = _mediaItems;

    if (items.isEmpty) {
      return _buildEmptyState(
        context: context,
        icon: Icons.video_library_rounded,
        message: 'Aucune vidéo publiée pour le moment',
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kHubMaxWidth),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 16 / 10,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final thumb = item.displayThumb;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: AdminColors.surfaceHi,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (thumb.isNotEmpty)
                        OptimizedImage(
                          url: thumb,
                          folder: 'media',
                          fit: BoxFit.cover,
                          memCacheWidth: 500,
                        ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.8),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.7],
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: _getIconSize(context, 28),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Text(
                          item.titleFr.isNotEmpty
                              ? item.titleFr
                              : item.titleEn,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (!item.isPublished)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Brouillon',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                              onTap: () => _openMediaForm(existing: item)),
                        ),
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

  // ══════════════════════════════════════════════════════════════════════
  // ONGLET ACTUS & APPARITION DIFFÉRENCIÉE SELON LE TYPE
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildEventList(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kHubMaxWidth),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Actualités & Événements',
                        style: TextStyle(
                            color: AdminColors.current,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: -0.5)),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          AdminColors.accent.withValues(alpha: 0.15),
                      foregroundColor: AdminColors.accent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const HomeEventFormPage()),
                    ),
                    icon: Icon(Icons.add_rounded,
                        size: _getIconSize(context, 20)),
                    label: const Text('Ajouter',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            if (_loadingEvents && _events.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(
                      color: AdminColors.current),
                ),
              )
            else if (_eventsError != null && _events.isEmpty)
              _buildErrorState(
                context: context,
                message: 'Erreur de chargement des événements',
                onRetry: _retryStreams,
              )
            else if (_events.isEmpty)
              _buildEmptyState(
                context: context,
                icon: Icons.event_busy_rounded,
                message: 'Aucun événement pour le moment',
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _events.length,
                itemBuilder: (context, i) {
                  final event = _events[i];
                  // Rendu visuel spécifique et distinct selon le type (Actualité, Événement, Reportage)
                  switch (event.type) {
                    case HomeEventType.news:
                      return _buildNewsAdminCard(context, event);
                    case HomeEventType.event:
                      return _buildEventAdminCard(context, event);
                    case HomeEventType.reportage:
                      return _buildReportageAdminCard(context, event);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── 1. Style Admin ACTUALITÉ : Éditorial / Article de presse ─────────────────
  Widget _buildNewsAdminCard(BuildContext context, HomeEvent event) {
    final title = event.titleFr.isNotEmpty ? event.titleFr : event.titleEn;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: event.type.color.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showEventMenu(event),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Vignette carrée style article de presse
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: event.type.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: event.imageUrl.isNotEmpty
                      ? OptimizedImage(
                          url: event.imageUrl,
                          folder: 'home_events',
                          fit: BoxFit.cover,
                          memCacheWidth: 200,
                          errorWidget: Icon(
                            event.type.icon,
                            color: event.type.color,
                            size: 26,
                          ),
                        )
                      : Icon(
                          event.type.icon,
                          color: event.type.color,
                          size: 26,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${title.isEmpty ? '(sans titre)' : title}'
                        '${event.isPublished ? '' : '  · [Brouillon]'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AdminColors.text,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      // Badge style éditorial carré / net
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: event.type.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.type.getLabel(context),
                          style: TextStyle(
                              color: event.type.color,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    !event.isPublished
                        ? Icons.visibility_off_rounded
                        : Icons.more_vert_rounded,
                    color: AdminColors.textMuted,
                    size: _getIconSize(context, 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 2. Style Admin ÉVÉNEMENT : Style agenda / billet avec bloc date ───────────
  Widget _buildEventAdminCard(BuildContext context, HomeEvent event) {
    final title = event.titleFr.isNotEmpty ? event.titleFr : event.titleEn;
    final date = event.eventDate;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: event.type.color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showEventMenu(event),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Bloc date style calendrier / billet agenda
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: event.type.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: event.type.color.withValues(alpha: 0.3)),
                  ),
                  child: date != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                  color: event.type.color,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getMonthShort(date.month),
                              style: TextStyle(
                                  color: event.type.color.withValues(alpha: 0.9),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        )
                      : Icon(event.type.icon, color: event.type.color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${title.isEmpty ? '(sans titre)' : title}'
                        '${event.isPublished ? '' : '  · [Brouillon]'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AdminColors.text,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      // Badge style pilule événement
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: event.type.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_available_rounded, size: 12, color: event.type.color),
                            const SizedBox(width: 4),
                            Text(
                              event.type.getLabel(context),
                              style: TextStyle(
                                  color: event.type.color,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    !event.isPublished
                        ? Icons.visibility_off_rounded
                        : Icons.more_vert_rounded,
                    color: AdminColors.textMuted,
                    size: _getIconSize(context, 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 3. Style Admin REPORTAGE : Multimédia / Vidéo immersive ─────────────────
  Widget _buildReportageAdminCard(BuildContext context, HomeEvent event) {
    final title = event.titleFr.isNotEmpty ? event.titleFr : event.titleEn;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: event.type.color.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showEventMenu(event),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Vignette avec icône de lecture vidéo superposée
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: event.type.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: event.imageUrl.isNotEmpty
                          ? OptimizedImage(
                              url: event.imageUrl,
                              folder: 'home_events',
                              fit: BoxFit.cover,
                              memCacheWidth: 200,
                              errorWidget: Icon(
                                event.type.icon,
                                color: event.type.color,
                                size: 26,
                              ),
                            )
                          : Icon(
                              event.type.icon,
                              color: event.type.color,
                              size: 26,
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${title.isEmpty ? '(sans titre)' : title}'
                        '${event.isPublished ? '' : '  · [Brouillon]'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AdminColors.text,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      // Badge style capsule multimédia
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: event.type.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_circle_fill_rounded, size: 12, color: event.type.color),
                            const SizedBox(width: 4),
                            Text(
                              event.type.getLabel(context),
                              style: TextStyle(
                                  color: event.type.color,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    !event.isPublished
                        ? Icons.visibility_off_rounded
                        : Icons.more_vert_rounded,
                    color: AdminColors.textMuted,
                    size: _getIconSize(context, 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthShort(int month) {
    const months = ['JAN', 'FÉV', 'MAR', 'AVR', 'MAI', 'JUIN', 'JUIL', 'AOÛT', 'SEP', 'OCT', 'NOV', 'DÉC'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  // ══════════════════════════════════════════════════════════════════════
  // ÉTATS VIDES / ERREURS
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildEmptyState({
    required BuildContext context,
    required IconData icon,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AdminColors.surfaceHi.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(icon,
                  size: _getIconSize(context, 48),
                  color: AdminColors.textMuted.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 20),
            Text(message,
                style: const TextStyle(
                    color: AdminColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState({
    required BuildContext context,
    required String message,
    required VoidCallback onRetry,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: _getIconSize(context, 40),
                color: AdminColors.danger),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(
                    color: AdminColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AdminColors.accent,
                side: BorderSide(
                    color: AdminColors.accent.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // MENU CONTEXTUEL ÉVÉNEMENT
  // ══════════════════════════════════════════════════════════════════════
  Future<void> _togglePublishEvent(HomeEvent event) async {
    try {
      await _eventService.setPublished(event.id, !event.isPublished);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(event.isPublished
              ? 'Événement retiré de la publication'
              : 'Événement republié'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec : $e'),
          backgroundColor: AdminColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEventMenu(HomeEvent event) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 600;
    final navigator = Navigator.of(context);

    final menuItems = [
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AdminColors.surfaceHi.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.edit_rounded,
              color: AdminColors.current,
              size: _getIconSize(context, 20)),
        ),
        title: const Text('Modifier',
            style: TextStyle(
                color: AdminColors.text, fontWeight: FontWeight.w600)),
        onTap: () {
          navigator.pop();
          navigator.push(
            MaterialPageRoute(
                builder: (_) => HomeEventFormPage(existing: event)),
          );
        },
      ),
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (event.isPublished ? AdminColors.danger : AdminColors.success)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            event.isPublished
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color:
                event.isPublished ? AdminColors.danger : AdminColors.success,
            size: _getIconSize(context, 20),
          ),
        ),
        title: Text(
          event.isPublished ? 'Retirer de la publication' : 'Republier',
          style: const TextStyle(
              color: AdminColors.text, fontWeight: FontWeight.w600),
        ),
        onTap: () {
          navigator.pop();
          _togglePublishEvent(event);
        },
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Divider(color: AdminColors.border.withValues(alpha: 0.5)),
      ),
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AdminColors.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.delete_rounded,
              color: AdminColors.danger, size: _getIconSize(context, 20)),
        ),
        title: const Text('Supprimer',
            style: TextStyle(
                color: AdminColors.danger, fontWeight: FontWeight.bold)),
        onTap: () {
          navigator.pop();
          _confirmDeleteEvent(event);
        },
      ),
      const SizedBox(height: 8),
    ];

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AdminColors.bg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Options de l\'événement',
              style: TextStyle(
                  color: AdminColors.text, fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: menuItems),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: AdminColors.bg,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                height: 5,
                width: 48,
                decoration: BoxDecoration(
                  color: AdminColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              ...menuItems,
            ],
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteEvent(HomeEvent event) async {
    final title = event.titleFr.isNotEmpty ? event.titleFr : event.titleEn;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Supprimer cet événement ?',
            style: TextStyle(
                color: AdminColors.text, fontWeight: FontWeight.bold)),
        content: Text(
          title.isEmpty
              ? 'Cet événement sera définitivement supprimé.'
              : '« $title » sera définitivement supprimé.',
          style:
              const TextStyle(color: AdminColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(
                    color: AdminColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _eventService.deleteEvent(event.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Événement supprimé'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Échec de la suppression : $e'),
                backgroundColor: AdminColors.danger,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          );
        }
      }
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIAIRES
// ══════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final String count;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconSize,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AdminColors.surfaceHi.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AdminColors.current.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: AdminColors.current),
          const SizedBox(height: 8),
          Text(count,
              style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -0.5,
                  color: AdminColors.text)),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 11,
                color: AdminColors.textSecondary,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ModernButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final double iconSize;
  final VoidCallback onTap;

  const _ModernButton({
    required this.text,
    required this.icon,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AdminColors.accentGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AdminColors.accent.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: iconSize, color: AdminColors.textOnAccent),
                const SizedBox(width: 10),
                Text(
                  text,
                  style: const TextStyle(
                    color: AdminColors.textOnAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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

class _PublicationOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PublicationOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AdminColors.text,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AdminColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing:
          const Icon(Icons.chevron_right_rounded, color: AdminColors.textMuted),
      onTap: onTap,
    );
  }
}