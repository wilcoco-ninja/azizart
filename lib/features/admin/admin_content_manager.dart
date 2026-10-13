import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';

import '../../theme/admin_colors.dart';
import '../gallery/models/artwork.dart';
import '../gallery/services/gallery_service.dart';
import '../atelier/models/atelier_model.dart';
import '../atelier/services/atelier_service.dart';
import '../media/models/media_model.dart';
import '../media/services/media_service.dart';
import '../home/models/home_event_model.dart';
import '../home/services/home_event_service.dart';
import '../admin_about/admin_about_page.dart';
import '../admin_gallery/admin_gallery_page.dart';
import 'atelier_form_page.dart';
import 'home_event_form_page.dart';
import 'gallery_form_page.dart';
import 'media_form_page.dart';
import 'admin_gate.dart';
import 'layout/admin_app_bar.dart';
import 'layout/admin_bottom_nav.dart';

class AdminContentManager extends StatefulWidget {
  final int initialTab;

  const AdminContentManager({super.key, this.initialTab = 0});

  @override
  State<AdminContentManager> createState() => _AdminContentManagerState();
}

class _AdminContentManagerState extends State<AdminContentManager> {
  late int _currentTab;
  final _selectedIds = <String>{};
  bool _selectAll = false;

  final _galleryService = GalleryService();
  final _atelierService = AtelierService();
  final _mediaService = MediaService();
  final _homeEventService = HomeEventService();

  List<Artwork> _artworks = [];
  List<AtelierPhoto> _atelierPhotos = [];
  List<MediaItem> _mediaItems = [];
  List<HomeEvent> _homeEvents = [];
  bool _loading = true;

  bool _artworksError = false;
  bool _mediaError = false;
  bool _eventsError = false;
  String? _artworksErrorMsg;
  String? _mediaErrorMsg;
  String? _eventsErrorMsg;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    await Future.wait([
      _loadArtworks(),
      _loadMedia(),
      _loadEvents(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadArtworks() async {
    try {
      final artworks = await _galleryService.fetchArtworks();
      final atelier = await _atelierService.fetchPhotos();
      if (mounted) {
        setState(() {
          _artworks = artworks;
          _atelierPhotos = atelier;
          _artworksError = false;
          _artworksErrorMsg = null;
        });
      }
    } catch (e) {
      debugPrint('AdminContentManager: erreur artworks/atelier: $e');
      if (mounted) {
        setState(() {
          _artworksError = true;
          _artworksErrorMsg = e.toString();
        });
      }
    }
  }

  Future<void> _loadMedia() async {
    try {
      final media = await _mediaService.fetchAll();
      if (mounted) {
        setState(() {
          _mediaItems = media;
          _mediaError = false;
          _mediaErrorMsg = null;
        });
      }
    } catch (e) {
      debugPrint('AdminContentManager: erreur media: $e');
      if (mounted) {
        setState(() {
          _mediaError = true;
          _mediaErrorMsg = e.toString();
        });
      }
    }
  }

  Future<void> _loadEvents() async {
    try {
      // watchAll() inclut les événements non publiés (l'admin doit pouvoir
      // les republier) ; fetchPublished() les masquait.
      final events = await _homeEventService.watchAll().first;
      if (mounted) {
        setState(() {
          _homeEvents = events;
          _eventsError = false;
          _eventsErrorMsg = null;
        });
      }
    } catch (e) {
      debugPrint('AdminContentManager: erreur events: $e');
      if (mounted) {
        setState(() {
          _eventsError = true;
          _eventsErrorMsg = e.toString();
        });
      }
    }
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      _selectAll = _selectedIds.length == _getCurrentCount();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(_getCurrentIds());
      }
      _selectAll = !_selectAll;
    });
  }

  List<String> _getCurrentIds() {
    switch (_currentTab) {
      case 0:
        return [
          ..._artworks.map((a) => a.id),
          ..._atelierPhotos.map((p) => p.id),
        ].whereType<String>().toList();
      case 1:
        return _mediaItems.map((m) => m.id).whereType<String>().toList();
      case 2:
        return _homeEvents.map((e) => e.id).toList();
      default:
        return [];
    }
  }

  int _getCurrentCount() => _getCurrentIds().length;

  int get _navIndexForTab => switch (_currentTab) {
        0 => 2,
        1 => 3,
        2 => 0,
        _ => 0,
      };

  void _onNavTap(BuildContext context, int index) {
    if (index == _navIndexForTab) return;
    final navigator = Navigator.of(context);
    if (index == 0) {
      navigator.popUntil(ModalRoute.withName('/admin'));
      return;
    }
    final Widget page = switch (index) {
      1 => const AdminGalleryPage(),
      2 => const AdminContentManager(initialTab: 0),
      3 => const AdminContentManager(initialTab: 1),
      4 => const AdminAboutPage(),
      _ => const AdminGate(),
    };
    navigator.popUntil(ModalRoute.withName('/admin'));
    navigator.push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AdminColors.bg,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kAdminAppBarHeight),
          child: AdminAppBar(
            title: 'Gestion du contenu',
            onBack: () => Navigator.of(context).maybePop(),
            actions: [
              if (_selectedIds.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AdminColors.danger,
                  tooltip: 'Supprimer la sélection',
                  onPressed: _deleteMultiple,
                ),
            ],
          ),
        ),
        bottomNavigationBar: isWideScreen
            ? null
            : AdminBottomNav(
                currentIndex: _navIndexForTab,
                onTap: (index) => _onNavTap(context, index),
              ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  if (isWideScreen)
                    NavigationRail(
                      backgroundColor: AdminColors.surfaceHi,
                      selectedIndex: _navIndexForTab,
                      onDestinationSelected: (index) =>
                          _onNavTap(context, index),
                      selectedIconTheme:
                          const IconThemeData(color: AdminColors.accent),
                      unselectedIconTheme: const IconThemeData(
                          color: AdminColors.textSecondary),
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(
                            icon: Icon(Icons.dashboard), label: Text('Hub')),
                        NavigationRailDestination(
                            icon: Icon(Icons.image), label: Text('Galerie')),
                        NavigationRailDestination(
                            icon: Icon(Icons.brush), label: Text('Atelier')),
                        NavigationRailDestination(
                            icon: Icon(Icons.video_library),
                            label: Text('Médias')),
                        NavigationRailDestination(
                            icon: Icon(Icons.info), label: Text('Infos')),
                      ],
                    ),
                  if (isWideScreen)
                    const VerticalDivider(
                        thickness: 1, width: 1, color: AdminColors.border),
                  Expanded(
                    child: Column(
                      children: [
                        _buildTabs(),
                        if (_getCurrentCount() > 0) _buildSelectAll(),
                        Expanded(child: _buildContentList()),
                      ],
                    ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_admin_content_manager',
          backgroundColor: AdminColors.accent,
          foregroundColor: AdminColors.textOnAccent,
          tooltip: switch (_currentTab) {
            0 => "Ajouter du contenu",
            1 => "Ajouter un média",
            2 => "Ajouter un événement",
            _ => "Ajouter",
          },
          onPressed: () async {
            if (_currentTab == 0) {
              await showModalBottomSheet(
                context: context,
                backgroundColor: AdminColors.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        height: 4,
                        width: 36,
                        decoration: BoxDecoration(
                          color: AdminColors.textSecondary
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Text(
                          'Que souhaitez-vous ajouter ?',
                          style: TextStyle(
                            color: AdminColors.text,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.image_outlined,
                            color: AdminColors.accent),
                        title: const Text('Œuvre (Galerie)',
                            style: TextStyle(color: AdminColors.text)),
                        subtitle: const Text(
                            'Tableau, peinture ou création batik',
                            style: TextStyle(
                                color: AdminColors.textSecondary,
                                fontSize: 12)),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const GalleryFormPage()),
                          );
                          _loadData();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.brush_outlined,
                            color: AdminColors.accent),
                        title: const Text('Photo (Atelier)',
                            style: TextStyle(color: AdminColors.text)),
                        subtitle: const Text(
                            'Coulisses et processus de création',
                            style: TextStyle(
                                color: AdminColors.textSecondary,
                                fontSize: 12)),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AtelierFormPage()),
                          );
                          _loadData();
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            } else {
              final Widget page = _currentTab == 1
                  ? const MediaFormPage()
                  : const HomeEventFormPage();
              await Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => page));
              _loadData();
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: AdminColors.surfaceHi,
      child: Row(
        children: [
          _TabButton(
            label: 'Images',
            count: _artworks.length + _atelierPhotos.length,
            isSelected: _currentTab == 0,
            onTap: () {
              setState(() {
                _currentTab = 0;
                _selectedIds.clear();
                _selectAll = false;
              });
            },
          ),
          _TabButton(
            label: 'Vidéos',
            count: _mediaItems.length,
            isSelected: _currentTab == 1,
            onTap: () {
              setState(() {
                _currentTab = 1;
                _selectedIds.clear();
                _selectAll = false;
              });
            },
          ),
          _TabButton(
            label: 'Événements',
            count: _homeEvents.length,
            isSelected: _currentTab == 2,
            onTap: () {
              setState(() {
                _currentTab = 2;
                _selectedIds.clear();
                _selectAll = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectAll() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AdminColors.surface,
      child: Row(
        children: [
          Checkbox(
            value: _selectAll,
            onChanged: (_) => _toggleSelectAll(),
            activeColor: AdminColors.accent,
          ),
          const Text('Tout sélectionner'),
          const Spacer(),
          Text('${_selectedIds.length} sélectionné(s)'),
        ],
      ),
    );
  }

  Widget _buildContentList() {
    switch (_currentTab) {
      case 0:
        return _buildImagesTab();
      case 1:
        return _buildVideosTab();
      case 2:
        return _buildEventsTab();
      default:
        return const Center(child: Text('Aucun contenu'));
    }
  }

  Widget _buildErrorView(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: AdminColors.danger, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Une erreur est survenue',
              style: TextStyle(
                color: AdminColors.text,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.length > 100
                  ? '${message.substring(0, 100)}...'
                  : message,
              style: const TextStyle(
                color: AdminColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.accent,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesTab() {
    if (_artworksError) {
      return _buildErrorView(_artworksErrorMsg ?? 'Erreur', _loadArtworks);
    }

    final allImages = [
      ..._artworks.map((a) => _ContentItem(
            id: a.id,
            title: a.titleFr,
            imageUrl: a.displayImage,
            type: 'Galerie',
            category: a.category,
            isPublished: a.isPublished,
            selected: _selectedIds.contains(a.id),
            onSelect: () => _toggleSelect(a.id),
            onMenu: () => _showContentMenu(a.id, 'gallery', a.isPublished),
          )),
      ..._atelierPhotos.map((p) => _ContentItem(
            id: p.id,
            title: p.titleFr,
            imageUrl: p.displayImage,
            type: 'Atelier',
            category: 'Photo',
            isPublished: p.isPublished,
            selected: _selectedIds.contains(p.id),
            onSelect: () => _toggleSelect(p.id),
            onMenu: () => _showContentMenu(p.id, 'atelier', p.isPublished),
          )),
    ];

    if (allImages.isEmpty) {
      return const Center(
        child: Text('Aucune image',
            style: TextStyle(color: AdminColors.textSecondary)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: allImages.length,
      itemBuilder: (_, i) => allImages[i],
    );
  }

  Widget _buildVideosTab() {
    if (_mediaError) {
      return _buildErrorView(_mediaErrorMsg ?? 'Erreur', _loadMedia);
    }

    if (_mediaItems.isEmpty) {
      return const Center(
        child: Text('Aucune vidéo',
            style: TextStyle(color: AdminColors.textSecondary)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _mediaItems.length,
      itemBuilder: (_, i) {
        final item = _mediaItems[i];
        final title = item.titleFr.isNotEmpty ? item.titleFr : item.titleEn;
        return _ContentItem(
          id: item.id,
          title: title,
          imageUrl: item.displayThumb,
          type: item.type.getLabel(context),
          category: item.source,
          isPublished: item.isPublished,
          selected: _selectedIds.contains(item.id),
          onSelect: () => _toggleSelect(item.id),
          onMenu: () => _showContentMenu(item.id, 'media', item.isPublished),
        );
      },
    );
  }

  Widget _buildEventsTab() {
    if (_eventsError) {
      return _buildErrorView(_eventsErrorMsg ?? 'Erreur', _loadEvents);
    }

    if (_homeEvents.isEmpty) {
      return const Center(
        child: Text('Aucun événement',
            style: TextStyle(color: AdminColors.textSecondary)),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _homeEvents.length,
          itemBuilder: (_, i) {
            final event = _homeEvents[i];
            return _EventContentItem(
              id: event.id,
              title: event.titleFr,
              imageUrl: event.imageUrl,
              type: event.type.name,
              date: event.eventDate,
              isPublished: event.isPublished,
              selected: _selectedIds.contains(event.id),
              onSelect: () => _toggleSelect(event.id),
              onMenu: () =>
                  _showContentMenu(event.id, 'event', event.isPublished),
            );
          },
        ),
      ),
    );
  }

  void _showContentMenu(String id, String type, bool isPublished) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    final menuItems = [
      ListTile(
        leading: const Icon(Icons.edit_outlined, color: AdminColors.text),
        title: const Text('Modifier'),
        onTap: () {
          Navigator.pop(context);
          _editContent(id, type);
        },
      ),
      if (type == 'event' ||
          type == 'gallery' ||
          type == 'media' ||
          type == 'atelier')
        ListTile(
          leading: Icon(
            isPublished
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: isPublished ? AdminColors.danger : AdminColors.success,
          ),
          title: Text(isPublished ? 'Retirer de la publication' : 'Republier'),
          onTap: () {
            Navigator.pop(context);
            _togglePublish(id, type, isPublished);
          },
        ),
      ListTile(
        leading: const Icon(Icons.delete_outline, color: AdminColors.danger),
        title: const Text('Supprimer définitivement',
            style: TextStyle(color: AdminColors.danger)),
        onTap: () {
          Navigator.pop(context);
          _confirmDelete(id, type);
        },
      ),
    ];

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AdminColors.surface,
          title: const Text('Options'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: menuItems),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: AdminColors.surface,
        builder: (_) => SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: menuItems),
        ),
      );
    }
  }

  void _editContent(String id, String type) {
    Widget? page;
    switch (type) {
      case 'gallery':
        for (final a in _artworks) {
          if (a.id == id) {
            page = GalleryFormPage(existing: a);
            break;
          }
        }
        break;
      case 'atelier':
        for (final p in _atelierPhotos) {
          if (p.id == id) {
            page = AtelierFormPage(existing: p);
            break;
          }
        }
        break;
      case 'media':
        for (final m in _mediaItems) {
          if (m.id == id) {
            page = MediaFormPage(existing: m);
            break;
          }
        }
        break;
      case 'event':
        for (final e in _homeEvents) {
          if (e.id == id) {
            page = HomeEventFormPage(existing: e);
            break;
          }
        }
        break;
    }

    if (page == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Élément introuvable, veuillez rafraîchir.')),
      );
      return;
    }

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => page!))
        .then((_) => _loadData());
  }

  Future<void> _togglePublish(String id, String type, bool isPublished) async {
    try {
      final table = _getTableForType(type);
      if (table.isEmpty) {
        throw Exception('Type de contenu inconnu : $type');
      }

      final updated = await Supabase.instance.client
          .from(table)
          .update({'is_published': !isPublished})
          .eq('id', id)
          .select('id');

      if (updated.isEmpty) {
        throw Exception(
          'Modification refusée : droits administrateur insuffisants '
          'ou contenu introuvable.',
        );
      }

      await _loadData();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPublished
              ? 'Contenu retiré de la publication'
              : 'Contenu republié'),
        ),
      );
    } catch (e) {
      debugPrint('AdminContentManager: échec togglePublish — $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  void _confirmDelete(String id, String type) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: const Text('Supprimer définitivement ?'),
        content: const Text(
          'Cette action est irréversible. Le fichier sera supprimé du stockage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteContent(id, type);
            },
            child: const Text('Confirmer',
                style: TextStyle(color: AdminColors.danger)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContent(
    String id,
    String type, {
    bool reload = true,
  }) async {
    try {
      await switch (type) {
        'gallery' => GalleryService().deleteArtwork(id),
        'atelier' => AtelierService().deletePhoto(id),
        'media' => MediaService().deleteMedia(id),
        'event' => HomeEventService().deleteEvent(id),
        _ => throw Exception('Type de contenu inconnu: $type'),
      };

      if (reload) {
        await _loadData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contenu supprimé')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }

  String _getTypeForId(String id) {
    if (_artworks.any((a) => a.id == id)) return 'gallery';
    if (_atelierPhotos.any((p) => p.id == id)) return 'atelier';
    if (_mediaItems.any((m) => m.id == id)) return 'media';
    if (_homeEvents.any((e) => e.id == id)) return 'event';
    return '';
  }

  Future<void> _deleteMultiple() async {
    try {
      for (final id in _selectedIds.toList()) {
        final type = _getTypeForId(id);
        if (type.isNotEmpty) {
          await _deleteContent(id, type, reload: false);
        }
      }
      _selectedIds.clear();
      _selectAll = false;
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Éléments sélectionnés supprimés')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de suppression multiple: $e')));
    }
  }

  String _getTableForType(String type) => switch (type) {
        'gallery' => 'artworks',
        'atelier' => 'atelier_photos',
        'media' => 'media_items',
        'event' => 'home_events',
        _ => '',
      };
}

class _ContentItem extends StatelessWidget {
  final String id;
  final String title;
  final String imageUrl;
  final String type;
  final String category;
  final bool isPublished;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onMenu;

  const _ContentItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.type,
    required this.category,
    required this.isPublished,
    required this.selected,
    required this.onSelect,
    required this.onMenu,
  });

  Widget _buildImageWidget() {
    if (imageUrl.isEmpty) {
      return Container(
        color: AdminColors.surface,
        child: const Icon(Icons.image_not_supported,
            color: AdminColors.textMuted),
      );
    }
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(color: AdminColors.surface),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
      placeholder: (_, _) => Container(
        color: AdminColors.surface,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AdminColors.accent),
          ),
        ),
      ),
      errorWidget: (_, _, _) => Container(
        color: AdminColors.surface,
        child: const Icon(Icons.broken_image_outlined,
            color: Colors.redAccent, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onMenu,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImageWidget(),
                  if (!isPublished)
                    Container(
                      color: Colors.black.withValues(alpha: 0.55),
                      child: const Center(
                        child: Icon(Icons.visibility_off,
                            color: Colors.white70, size: 28),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: Checkbox(
                value: selected,
                onChanged: (_) => onSelect(),
                activeColor: AdminColors.accent,
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  title.length > 20 ? '${title.substring(0, 20)}...' : title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.more_vert, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventContentItem extends StatelessWidget {
  final String id;
  final String title;
  final String imageUrl;
  final String type;
  final DateTime? date;
  final bool isPublished;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onMenu;

  const _EventContentItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.type,
    required this.date,
    required this.isPublished,
    required this.selected,
    required this.onSelect,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onMenu,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AdminColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPublished
                  ? Colors.transparent
                  : AdminColors.danger.withValues(alpha: 0.3),
              width: isPublished ? 0 : 2,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Checkbox(
                  value: selected,
                  onChanged: (_) => onSelect(),
                  activeColor: AdminColors.accent,
                ),
              ),
              ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(8)),
                child: SizedBox(
                  width: 100,
                  height: 80,
                  child: imageUrl.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          imageRenderMethodForWeb:
                              ImageRenderMethodForWeb.HttpGet,
                          placeholder: (_, _) =>
                              Container(color: AdminColors.surfaceHi),
                          errorWidget: (_, _, _) =>
                              Container(color: AdminColors.surfaceHi),
                        )
                      : Container(color: AdminColors.surfaceHi),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AdminColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AdminColors.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              type.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: AdminColors.accent,
                              ),
                            ),
                          ),
                          if (date != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${date!.day}/${date!.month}/${date!.year}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AdminColors.textSecondary,
                              ),
                            ),
                          ],
                          if (!isPublished) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AdminColors.danger.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                'NON PUBLIÉ',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AdminColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert,
                    color: AdminColors.textSecondary),
                onPressed: onMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AdminColors.surface : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AdminColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AdminColors.text
                      : AdminColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AdminColors.accent.withValues(alpha: 0.2)
                      : AdminColors.surfaceHi,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? AdminColors.accent
                        : AdminColors.textSecondary,
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