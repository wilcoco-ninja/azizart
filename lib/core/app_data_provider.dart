import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/admin_about/services/about_content_service.dart';
import '../features/atelier/models/atelier_model.dart';
import '../features/atelier/services/atelier_service.dart';
import '../features/gallery/models/artwork.dart';
import '../features/gallery/services/gallery_service.dart';
import '../features/home/models/home_event_model.dart';
import '../features/home/models/home_model.dart';
import '../features/home/services/home_event_service.dart';
import '../features/media/models/media_model.dart';
import '../features/media/services/media_service.dart';

/// Données publiques du site, chargées UNE fois puis actualisées à intervalle
/// espacé et au retour sur l'onglet. Aucun abonnement temps réel côté public
/// (chaque visiteur ouvrirait une connexion WebSocket plafonnée par projet) :
/// le temps réel est réservé aux écrans admin.
///
/// Garanties :
/// - une source en échec ou trop lente conserve ses dernières données ;
/// - un rafraîchissement automatique ne remplace jamais des données
///   existantes par une liste vide (les services renvoient `[]` en cas
///   d'erreur) ; seul [refresh] (appelé à la sortie de l'admin) l'accepte ;
/// - un seul chargement à la fois, les demandes concurrentes sont fusionnées
///   et [refresh] attend la fin du chargement en cours ;
/// - un site réellement vide n'est PAS une erreur : une requête de contrôle
///   distingue « aucun contenu » de « serveur injoignable ».
class AppDataProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const Duration _refreshBase = Duration(minutes: 10);
  static const int _refreshJitterSeconds = 120;
  static const Duration _retryAfterError = Duration(seconds: 15);
  static const Duration _resumeStaleAfter = Duration(minutes: 2);
  static const Duration _sourceTimeout = Duration(seconds: 20);
  static const Duration _probeTimeout = Duration(seconds: 8);
  static const int _homeFeaturedLimit = 14;

  List<Artwork> _artworks = const [];
  List<AtelierPhoto> _atelierPhotos = const [];
  List<MediaItem> _mediaItems = const [];
  List<HomeEvent> _events = const [];
  Map<String, dynamic>? _aboutContent;
  HomeData _homeData = const HomeData();

  bool _ready = false;
  bool _disposed = false;
  String? _error;

  Future<void>? _running;
  bool _rerunRequested = false;
  bool _rerunTrustEmpty = false;
  DateTime? _lastSync;

  final Random _random = Random();
  Timer? _refreshTimer;

  List<Artwork> get artworks => _artworks;
  List<AtelierPhoto> get atelierPhotos => _atelierPhotos;
  List<MediaItem> get mediaItems => _mediaItems;
  List<HomeEvent> get events => _events;
  Map<String, dynamic>? get aboutContent => _aboutContent;
  HomeData get homeData => _homeData;
  bool get isReady => _ready;
  String? get error => _error;

  AppDataProvider() {
    WidgetsBinding.instance.addObserver(this);
    unawaited(_sync(trustEmpty: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _disposed) return;
    final last = _lastSync;
    if (last == null || DateTime.now().difference(last) > _resumeStaleAfter) {
      unawaited(_sync(trustEmpty: false));
    }
  }

  /// Lance un chargement, ou se rattache à celui en cours (qui sera relancé
  /// une fois si une nouvelle demande arrive entre-temps).
  Future<void> _sync({required bool trustEmpty}) {
    if (_disposed) return Future<void>.value();

    final running = _running;
    if (running != null) {
      _rerunRequested = true;
      _rerunTrustEmpty = _rerunTrustEmpty || trustEmpty;
      return running;
    }

    final run = _runSync(trustEmpty: trustEmpty);
    _running = run;
    return run;
  }

  Future<void> _runSync({required bool trustEmpty}) async {
    try {
      var trust = trustEmpty;
      do {
        _rerunRequested = false;
        await _load(trustEmpty: trust);
        trust = _rerunTrustEmpty;
        _rerunTrustEmpty = false;
      } while (_rerunRequested && !_disposed);
    } catch (e, st) {
      debugPrint('AppDataProvider: chargement interrompu — $e\n$st');
      _error ??= e.toString();
    } finally {
      // Libéré avant la notification : toute demande suivante démarre un
      // nouveau chargement au lieu d'être perdue.
      _running = null;
    }

    if (_disposed) return;
    _lastSync = DateTime.now();
    _ready = true;
    notifyListeners();
    _scheduleRefresh();
  }

  Future<void> _load({required bool trustEmpty}) async {
    final errors = <String>[];

    Future<T?> safe<T>(String label, Future<T> Function() task) async {
      try {
        return await task().timeout(_sourceTimeout);
      } catch (e) {
        debugPrint('AppDataProvider: échec chargement $label — $e');
        errors.add(e.toString());
        return null;
      }
    }

    final results = await Future.wait<Object?>([
      safe<List<Artwork>>('œuvres', () => GalleryService().fetchArtworks()),
      safe<List<AtelierPhoto>>('atelier', () => AtelierService().fetchPhotos()),
      safe<List<MediaItem>>('médias', () => MediaService().fetchAll()),
      safe<List<HomeEvent>>(
          'événements', () => HomeEventService().fetchPublished()),
      safe<Map<String, dynamic>?>(
          'à propos', () => AboutContentService().getContent()),
    ]);

    if (_disposed) return;

    // Liste reçue → liste retenue. `null` (échec) ou liste vide inattendue
    // (hors actualisation explicite) → on garde les données actuelles.
    List<T> keep<T>(List<T>? fresh, List<T> current) {
      if (fresh == null) return current;
      if (fresh.isEmpty && current.isNotEmpty && !trustEmpty) return current;
      return fresh;
    }

    final freshArtworks = results[0] as List<Artwork>?;
    final freshPhotos = results[1] as List<AtelierPhoto>?;
    final freshMedia = results[2] as List<MediaItem>?;
    final freshEvents = results[3] as List<HomeEvent>?;
    final freshAbout = results[4] as Map<String, dynamic>?;

    // Seul le contenu publié est affiché sur le site public.
    _artworks = keep<Artwork>(
      freshArtworks?.where((a) => a.isPublished).toList(),
      _artworks,
    );
    _atelierPhotos = keep<AtelierPhoto>(
      freshPhotos?.where((p) => p.isPublished).toList(),
      _atelierPhotos,
    );
    _mediaItems = keep<MediaItem>(
      freshMedia?.where((m) => m.isPublished).toList(),
      _mediaItems,
    );
    _events = keep<HomeEvent>(freshEvents, _events);
    if (freshAbout != null) _aboutContent = freshAbout;

    // Œuvres « en vedette » ; à défaut, les plus récentes : l'accueil n'est
    // jamais vide tant qu'une œuvre est publiée.
    final starred = _artworks.where((a) => a.featured).toList();
    _homeData = HomeData(
      featuredArtworks:
          (starred.isNotEmpty ? starred : _artworks)
              .take(_homeFeaturedLimit)
              .toList(),
    );

    // Les services renvoient `[]` sur erreur : on ne peut donc pas déduire une
    // panne d'une liste vide. Sans aucun contenu, une requête de contrôle
    // tranche ; un site vide mais joignable n'est PAS une erreur (les pages
    // affichent leurs états vides).
    final allFailed =
        freshArtworks == null && freshPhotos == null && freshMedia == null;
    final noContent =
        _artworks.isEmpty && _atelierPhotos.isEmpty && _mediaItems.isEmpty;

    if (allFailed) {
      _error = errors.isNotEmpty ? errors.first : 'Chargement impossible';
    } else if (noContent && !await _backendReachable()) {
      _error = 'Serveur injoignable. Vérifiez votre connexion.';
    } else {
      _error = null;
    }

    debugPrint('AppDataProvider: ${_artworks.length} œuvres, '
        '${_atelierPhotos.length} photos atelier, ${_mediaItems.length} médias, '
        '${_events.length} événements');
  }

  /// Requête minimale : réussit si le serveur répond, même sans aucune ligne.
  Future<bool> _backendReachable() async {
    try {
      await Supabase.instance.client
          .from('artworks')
          .select('id')
          .limit(1)
          .timeout(_probeTimeout);
      return true;
    } catch (e) {
      debugPrint('AppDataProvider: contrôle serveur échoué — $e');
      return false;
    }
  }

  /// Actualisation espacée avec délai aléatoire (évite les pics synchronisés) ;
  /// reprise rapide tant que le chargement est en erreur.
  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    final delay = _error != null
        ? _retryAfterError
        : _refreshBase +
            Duration(seconds: _random.nextInt(_refreshJitterSeconds));
    _refreshTimer = Timer(delay, () => unawaited(_sync(trustEmpty: false)));
  }

  /// Actualisation explicite (bouton « Réessayer », sortie de l'admin) :
  /// accepte aussi les listes vides (suppression volontaire de contenu) et
  /// attend la fin du chargement.
  Future<void> refresh() async {
    _error = null;
    await _sync(trustEmpty: true);
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }
}