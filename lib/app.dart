import 'dart:async';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_data_provider.dart';
import 'core/localization/language_provider.dart';
import 'features/about/about_page.dart';
import 'features/admin/admin_gate.dart' deferred as admin;
import 'features/admin/admin_reset_password_page.dart' deferred as admin_reset;
import 'features/atelier/atelier_page.dart';
import 'features/contact/contact_page.dart';
import 'features/gallery/gallery_page.dart';
import 'features/home/home_page.dart';
import 'features/media/media_page.dart';
import 'theme/app_theme.dart';
import 'theme/aziz_colors.dart';
import 'widgets/navbar.dart';

final Future<void> _adminLibrary = admin.loadLibrary();
final Future<void> _adminResetLibrary = admin_reset.loadLibrary();

class PageIndices {
  static const int home = 0;
  static const int gallery = 1;
  static const int atelier = 2;
  static const int media = 3;
  static const int about = 4;
  static const int contact = 5;
}

/// Autorise le défilement par glissement à la souris et au pavé tactile (Web / PC).
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

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

  /// Affiche une page d'une bibliothèque différée une fois celle-ci chargée.
  static Widget _deferredPage(Future<void> library, Widget Function() build) {
    return FutureBuilder<void>(
      future: library,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            backgroundColor: AzizColors.backgroundDark,
            body: Center(
              child: Text(
                'Chargement impossible. Rechargez la page.',
                style: TextStyle(color: AzizColors.textPrimary),
              ),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AzizColors.backgroundDark,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return build();
      },
    );
  }

  /// Retrouve la route à partir du chemin seul en ignorant les query params et trailing slashes.
  static Route<dynamic>? _routeFor(String? name) {
    if (name == null) return null;
    final uri = Uri.parse(name);
    var path = uri.path;
    
    // Normalisation du chemin (suppression du slash final superflu)
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    switch (path) {
      case '/':
      case '':
        return MaterialPageRoute<void>(
          settings: RouteSettings(name: name),
          builder: (_) => const _AzizArtShell(),
        );
      case '/admin':
        return MaterialPageRoute<void>(
          settings: RouteSettings(name: name),
          builder: (_) =>
              _deferredPage(_adminLibrary, () => admin.AdminGate()),
        );
      case '/admin/reset-password':
        return MaterialPageRoute<void>(
          settings: RouteSettings(name: name),
          builder: (_) => _deferredPage(
            _adminResetLibrary,
            () => admin_reset.AdminResetPasswordPage(),
          ),
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LanguageProvider>().locale;

    return MaterialApp(
      title: 'AZIZART COLORS — Olga Indigo',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _AppScrollBehavior(),
      locale: locale,
      supportedLocales: _supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.theme,
      // Actualise les données publiques quand l'administrateur quitte /admin
      navigatorObservers: [
        _RefreshOnAdminExit(context.read<AppDataProvider>()),
      ],
      onGenerateRoute: (settings) {
        final route = _routeFor(settings.name);
        if (route != null) return route;
        // Fallback de sécurité : renvoie vers l'accueil si la route n'existe pas
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const _AzizArtShell(),
        );
      },
      onGenerateInitialRoutes: (initialRoute) {
        final home = MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/'),
          builder: (_) => const _AzizArtShell(),
        );
        final route = _routeFor(initialRoute);
        if (route == null || route.settings.name == '/') {
          return <Route<dynamic>>[home];
        }
        if (route.settings.name == '/admin/reset-password') {
          return <Route<dynamic>>[route];
        }
        return <Route<dynamic>>[home, route];
      },
    );
  }
}

/// Actualise [AppDataProvider] à la sortie de l'espace administration.
class _RefreshOnAdminExit extends NavigatorObserver {
  _RefreshOnAdminExit(this._data);

  final AppDataProvider _data;

  void _refreshIfAdmin(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null && name.startsWith('/admin')) {
      unawaited(_data.refresh());
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _refreshIfAdmin(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _refreshIfAdmin(oldRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _refreshIfAdmin(route);
}

class _AzizArtShell extends StatefulWidget {
  const _AzizArtShell();

  @override
  State<_AzizArtShell> createState() => _AzizArtShellState();
}

class _AzizArtShellState extends State<_AzizArtShell> {
  int _currentIndex = PageIndices.home;

  final Set<int> _visited = {PageIndices.home};
  final Map<int, ScrollPosition> _pageScrollPositions = {};

  bool _capturePageScroll(
      int pageIndex, ScrollMetrics metrics, BuildContext? ctx) {
    if (metrics.axis != Axis.vertical || ctx == null) return false;
    final position = Scrollable.maybeOf(ctx)?.position;
    if (position == null || !position.hasContentDimensions) return false;
    final known = _pageScrollPositions[pageIndex];
    if (known == null ||
        !known.hasContentDimensions ||
        position.maxScrollExtent >= known.maxScrollExtent) {
      _pageScrollPositions[pageIndex] = position;
    }
    return false;
  }

  Widget _pageHost(int index, AppDataProvider data) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _capturePageScroll(index, n.metrics, n.context),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _capturePageScroll(index, n.metrics, n.context),
        child: _buildPage(index, data),
      ),
    );
  }

  void _scrollToTop(int index, {bool animate = true}) {
    final pos = _pageScrollPositions[index];
    if (pos == null || !pos.hasPixels || !pos.hasContentDimensions) return;
    if (pos.pixels == 0) return;
    if (animate) {
      pos.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      pos.jumpTo(0);
    }
  }

  void _navigate(int index) {
    if (index == _currentIndex) {
      _scrollToTop(index);
      return;
    }

    setState(() {
      _currentIndex = index;
      _visited.add(index);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToTop(index, animate: false);
    });
  }

  Widget _buildPage(int index, AppDataProvider data) {
    switch (index) {
      case PageIndices.home:
        return HomePage(
          onNavigate: _navigate,
          homeData: data.homeData,
          atelierPhotos: data.atelierPhotos,
          mediaItems: data.mediaItems,
        );
      case PageIndices.gallery:
        return GalleryPage(artworkList: data.artworks);
      case PageIndices.atelier:
        return AtelierPage(onContact: () => _navigate(PageIndices.contact));
      case PageIndices.media:
        return MediaPage(mediaItems: data.mediaItems);
      case PageIndices.about:
        return const AboutPage();
      case PageIndices.contact:
        return const ContactPage();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<AppDataProvider>();

    final isLoading = !dataProvider.isReady && dataProvider.error == null;

    if (dataProvider.error != null && dataProvider.artworks.isEmpty) {
      return Scaffold(
        backgroundColor: AzizColors.lightBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AzizColors.terraCotta, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Erreur de chargement',
                style: TextStyle(
                  color: AzizColors.textPrimary,
                  fontSize: 18,
                  fontFamily: 'Playfair Display',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => dataProvider.refresh(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AzizColors.lightBackground,
      body: Column(
        children: [
          AzizNavBar(currentIndex: _currentIndex, onTap: _navigate),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AzizColors.trueIndigo,
                    ),
                  )
                : IndexedStack(
                    index: _currentIndex,
                    children: [
                      for (var i = 0; i <= PageIndices.contact; i++)
                        _visited.contains(i)
                            ? _pageHost(i, dataProvider)
                            : const SizedBox.shrink(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}