import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/localization/language_provider.dart';
import 'core/data/json_data_service.dart';
import 'features/gallery/models/artwork.dart';
import 'features/gallery/services/gallery_service.dart';
import 'features/atelier/models/atelier_model.dart';
import 'features/atelier/services/atelier_service.dart';
import 'features/media/models/media_model.dart';
import 'features/media/services/media_service.dart';
import 'features/home/models/home_model.dart';
import 'features/home/services/home_service.dart';
import 'theme/app_theme.dart';
import 'theme/aziz_colors.dart';
import 'widgets/navbar.dart';
import 'features/about/about_page.dart';
import 'features/admin/admin_gate.dart';
import 'features/atelier/atelier_page.dart';
import 'features/contact/contact_page.dart';
import 'features/gallery/gallery_page.dart';
import 'features/home/home_page.dart';
import 'features/media/media_page.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Indices de navigation (identiques à l'original)
// ══════════════════════════════════════════════════════════════════════════════
class PageIndices {
  static const int home = 0;
  static const int gallery = 1;
  static const int atelier = 2;
  static const int media = 3;
  static const int about = 4;
  static const int contact = 5;
}

// ══════════════════════════════════════════════════════════════════════════════
// AppDataProvider — FIX : Firestore streams en temps réel + fallback JSON
//
// CORRECTION PRINCIPALE :
//   Avant : chargement unique depuis artworks.json / atelier_photos.json /
//           media_items.json. Les ajouts admin (Firestore) n'apparaissaient
//           jamais dans l'app.
//   Après : (1) Charge JSON localement pour un affichage immédiat (< 200 ms),
//           (2) Souscrit aux streams Firestore — dès qu'un admin publie une
//               œuvre/photo/média, l'UI se met à jour en temps réel.
//           (3) Plus de spinner plein-écran bloquant — l'UI s'affiche
//               immédiatement avec les données JSON, puis se raffraîchit live.
// ══════════════════════════════════════════════════════════════════════════════
class AppDataProvider extends ChangeNotifier {
  List<Artwork> _artworks = [];
  List<AtelierPhoto> _atelierPhotos = [];
  List<MediaItem> _mediaItems = [];
  bool _ready = false;
  String? _error;

  // FIX (site "pas réellement dynamique") : une fois qu'un flux Firestore
  // a livré au moins une donnée réelle, on doit lui faire confiance en
  // permanence — y compris si l'admin supprime ensuite tout le contenu
  // d'une collection. Avant ce fix, la condition `if (list.isNotEmpty)`
  // ignorait purement et simplement toute mise à jour Firestore vide,
  // donc une suppression totale ne se répercutait jamais sur le site
  // (il continuait d'afficher les anciennes données, ou le JSON local).
  bool _artworksLive = false;
  bool _atelierLive = false;
  bool _mediaLive = false;

  // Subscriptions Supabase Realtime
  StreamSubscription<List<Artwork>>? _artworkSub;
  StreamSubscription<List<AtelierPhoto>>? _atelierSub;
  StreamSubscription<List<MediaItem>>? _mediaSub;

  // FIX (robustesse réseau) : si le temps réel Supabase (WebSocket)
  // n'arrive pas à se connecter — réseau d'entreprise/VPN/antivirus qui
  // bloque les WebSocket, projet qui vient de se réveiller, etc. — on ne
  // reste plus bloqué indéfiniment sur les données JSON locales. On
  // bascule sur une actualisation périodique classique (HTTPS, pas de
  // WebSocket) toutes les 45 secondes.
  Timer? _artworksPollTimer;
  Timer? _atelierPollTimer;
  Timer? _mediaPollTimer;

  List<Artwork> get artworks => _artworks;
  List<AtelierPhoto> get atelierPhotos => _atelierPhotos;
  List<MediaItem> get mediaItems => _mediaItems;

  /// [ready] est true dès que le JSON local est chargé.
  /// L'UI peut s'afficher sans attendre Firestore.
  bool get isReady => _ready;
  String? get error => _error;

  AppDataProvider() {
    _boot();
  }

  // ── Démarrage en deux étapes ─────────────────────────────────────────────
  Future<void> _boot() async {
    // Étape 1 : JSON local → affichage immédiat
    await _loadJson();
    _ready = true;
    notifyListeners();

    // Étape 2 : Streams Firestore → mises à jour temps réel
    _subscribeFirestore();
  }

  // ── Chargement JSON (rapide, fonctionne hors-ligne) ─────────────────────
  Future<void> _loadJson() async {
    try {
      final svc = JsonDataService();
      final results = await Future.wait([
        svc.loadArtworks(),
        svc.loadAtelierPhotos(),
        svc.loadMediaItems(),
      ]);
      _artworks = results[0] as List<Artwork>;
      _atelierPhotos = results[1] as List<AtelierPhoto>;
      _mediaItems = results[2] as List<MediaItem>;
      debugPrint('AppDataProvider JSON: ${_artworks.length} œuvres, '
          '${_atelierPhotos.length} photos atelier, ${_mediaItems.length} médias');
    } catch (e) {
      _error = e.toString();
      debugPrint('AppDataProvider erreur JSON: $e');
    }
  }

  // ── Souscription streams Supabase (+ repli polling si échec) ─────────────
  void _subscribeFirestore() {
    // Galerie
    try {
      _artworkSub = GalleryService().watchArtworks().listen(
        (list) {
          if (list.isNotEmpty || _artworksLive) {
            _artworksLive = true;
            _artworks = list;
            notifyListeners();
            debugPrint(
                'AppDataProvider Supabase: ${list.length} œuvres reçues');
          }
        },
        onError: (e) {
          debugPrint('Artworks stream error: $e');
          _startArtworksFallbackPolling();
        },
      );
    } catch (e) {
      debugPrint('AppDataProvider: impossible de souscrire artworks: $e');
      _startArtworksFallbackPolling();
    }

    // Atelier
    try {
      _atelierSub = AtelierService().watchPhotos().listen(
        (list) {
          if (list.isNotEmpty || _atelierLive) {
            _atelierLive = true;
            _atelierPhotos = list;
            notifyListeners();
            debugPrint(
                'AppDataProvider Supabase: ${list.length} photos atelier reçues');
          }
        },
        onError: (e) {
          debugPrint('Atelier stream error: $e');
          _startAtelierFallbackPolling();
        },
      );
    } catch (e) {
      debugPrint('AppDataProvider: impossible de souscrire atelier: $e');
      _startAtelierFallbackPolling();
    }

    // Médias
    try {
      _mediaSub = MediaService().watchAll().listen(
        (list) {
          if (list.isNotEmpty || _mediaLive) {
            _mediaLive = true;
            _mediaItems = list;
            notifyListeners();
            debugPrint('AppDataProvider Supabase: ${list.length} médias reçus');
          }
        },
        onError: (e) {
          debugPrint('Media stream error: $e');
          _startMediaFallbackPolling();
        },
      );
    } catch (e) {
      debugPrint('AppDataProvider: impossible de souscrire médias: $e');
      _startMediaFallbackPolling();
    }
  }

  // ── Repli en actualisation périodique (temps réel indisponible) ─────────
  void _startArtworksFallbackPolling() {
    if (_artworksPollTimer != null) return; // déjà en mode dégradé
    debugPrint('AppDataProvider: mode périodique activé pour la galerie');
    _pollArtworksOnce();
    _artworksPollTimer =
        Timer.periodic(const Duration(seconds: 45), (_) => _pollArtworksOnce());
  }

  Future<void> _pollArtworksOnce() async {
    try {
      final list = await GalleryService().fetchArtworks();
      if (list.isNotEmpty) {
        _artworks = list;
        _artworksLive = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AppDataProvider: échec actualisation périodique œuvres: $e');
    }
  }

  void _startAtelierFallbackPolling() {
    if (_atelierPollTimer != null) return;
    debugPrint('AppDataProvider: mode périodique activé pour l\'atelier');
    _pollAtelierOnce();
    _atelierPollTimer =
        Timer.periodic(const Duration(seconds: 45), (_) => _pollAtelierOnce());
  }

  Future<void> _pollAtelierOnce() async {
    try {
      final list = await AtelierService().fetchPhotos();
      if (list.isNotEmpty) {
        _atelierPhotos = list;
        _atelierLive = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AppDataProvider: échec actualisation périodique atelier: $e');
    }
  }

  void _startMediaFallbackPolling() {
    if (_mediaPollTimer != null) return;
    debugPrint('AppDataProvider: mode périodique activé pour les médias');
    _pollMediaOnce();
    _mediaPollTimer =
        Timer.periodic(const Duration(seconds: 45), (_) => _pollMediaOnce());
  }

  Future<void> _pollMediaOnce() async {
    try {
      final list = await MediaService().fetchAll();
      if (list.isNotEmpty) {
        _mediaItems = list;
        _mediaLive = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AppDataProvider: échec actualisation périodique médias: $e');
    }
  }

  /// Rechargement forcé du JSON (pull-to-refresh éventuel).
  Future<void> refresh() async {
    await _loadJson();
    notifyListeners();
  }

  @override
  void dispose() {
    _artworkSub?.cancel();
    _atelierSub?.cancel();
    _mediaSub?.cancel();
    _artworksPollTimer?.cancel();
    _atelierPollTimer?.cancel();
    _mediaPollTimer?.cancel();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AzizArtApp — Widget racine
// ══════════════════════════════════════════════════════════════════════════════
class AzizArtApp extends StatelessWidget {
  const AzizArtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppDataProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const _AzizArtAppContent(),
    );
  }
}

class _AzizArtAppContent extends StatelessWidget {
  const _AzizArtAppContent();

  static List<Locale> get _supportedLocales =>
      LanguageProvider.supportedLanguages.map((code) => Locale(code)).toList();

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LanguageProvider>().locale;

    return MaterialApp(
      title: 'AZIZART — Olga Indigo',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: _supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale != null) {
          for (final supported in supportedLocales) {
            if (supported.languageCode == deviceLocale.languageCode) {
              return supported;
            }
          }
        }
        return const Locale('fr');
      },
      theme: AppTheme.theme,
      home: const _AzizArtShell(),
      routes: {'/admin': (context) => const AdminGate()},
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _AzizArtShell — Shell de navigation
//
// FIX PERFORMANCE :
//   Avant : spinner plein-écran jusqu'à la fin de TOUS les chargements JSON.
//   Après : l'UI s'affiche immédiatement ; les sections gèrent leurs propres
//           états vides/chargement. Aucun blocage global.
// ══════════════════════════════════════════════════════════════════════════════
class _AzizArtShell extends StatefulWidget {
  const _AzizArtShell();

  @override
  State<_AzizArtShell> createState() => _AzizArtShellState();
}

class _AzizArtShellState extends State<_AzizArtShell> {
  int _currentIndex = PageIndices.home;
  late final Future<HomeData> _homeDataFuture;

  @override
  void initState() {
    super.initState();
    // HomeService récupère les œuvres vedettes depuis Firestore (ou JSON fallback)
    _homeDataFuture = HomeService().fetchHomeData();
  }

  void _navigate(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  Widget _buildHomePage(AppDataProvider dataProvider) {
    return FutureBuilder<HomeData>(
      future: _homeDataFuture,
      builder: (context, snapshot) {
        // Affichage immédiat — pas de spinner bloquant
        return HomePage(
          onNavigate: _navigate,
          homeData: snapshot.data ?? const HomeData(),
          atelierPhotos: dataProvider.atelierPhotos,
          mediaItems: dataProvider.mediaItems,
        );
      },
    );
  }

  Widget _buildPage(AppDataProvider dataProvider) {
    switch (_currentIndex) {
      case PageIndices.home:
        return _buildHomePage(dataProvider);
      case PageIndices.gallery:
        return GalleryPage(artworkList: dataProvider.artworks);
      case PageIndices.atelier:
        return AtelierPage(
          onContact: () => _navigate(PageIndices.contact),
          photos: dataProvider.atelierPhotos,
        );
      case PageIndices.media:
        return MediaPage(mediaItems: dataProvider.mediaItems);
      case PageIndices.about:
        return const AboutPage();
      case PageIndices.contact:
        return const ContactPage();
      default:
        return _buildHomePage(dataProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<AppDataProvider>();

    // FIX : plus de spinner plein-écran — affichage immédiat du shell.
    // Si une erreur critique s'est produite (JSON + Firestore tous les deux
    // indisponibles), on affiche un écran d'erreur minimal.
    if (dataProvider.error != null && !dataProvider.isReady) {
      return Scaffold(
        backgroundColor: AzizColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AzizColors.terraCotta, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Erreur de chargement',
                style: TextStyle(color: AzizColors.textPrimary, fontSize: 18),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => dataProvider.refresh(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AzizColors.background,
      body: Column(
        children: [
          AzizNavBar(currentIndex: _currentIndex, onTap: _navigate),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: _buildPage(dataProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
