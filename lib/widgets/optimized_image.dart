import 'dart:async';
import 'dart:math' show Random;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../services/azizart_cache_manager.dart';
import '../services/media_url_resolver.dart';
import '../theme/aziz_colors.dart';

/// Image réseau unique de l'application.
///
/// Web : `Image.network` décode l'image dans le canvas Flutter. Une balise
/// `<img>` HTML n'est utilisée qu'en dernier recours (échec CORS/décodage).
/// Mobile / bureau : `CachedNetworkImage` avec cache disque.
///
/// La largeur demandée au serveur dépend de la taille affichée et de la
/// densité de pixels : un petit écran ne télécharge ni ne décode jamais
/// une image de 2400 px.
///
/// Robustesse : si TOUTES les URL candidates échouent (limite de débit de
/// l'adresse r2.dev, coupure réseau brève), l'image est redemandée
/// automatiquement jusqu'à [_maxRetries] fois, avec un délai croissant et
/// aléatoire, avant d'afficher l'icône d'erreur.
class OptimizedImage extends StatefulWidget {
  final String? url;
  final String? path;

  /// Dossier R2 appliqué aux chemins sans dossier (ex. `gallery`,
  /// `about_avatars`, `about_banners`, `atelier`, `home_events`, `media`).
  final String? folder;
  final BoxFit fit;
  final Widget? errorWidget;
  final Widget? placeholder;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Alignment alignment;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final String? cacheKey;
  final Map<String, String>? httpHeaders;

  const OptimizedImage({
    super.key,
    this.url,
    String? path,
    this.folder,
    @Deprecated('Ignoré') String? bucket,
    @Deprecated('Utiliser `path:` à la place.') String? assetPath,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.placeholder,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.alignment = Alignment.center,
    this.memCacheWidth,
    this.memCacheHeight,
    this.cacheKey,
    this.httpHeaders,
  }) : path = path ?? assetPath;

  String get _reference {
    final direct = (url ?? '').trim();
    return direct.isNotEmpty ? direct : (path ?? '').trim();
  }

  /// URL d'origine (si http) : filet de sécurité quand l'URL résolue échoue.
  String get _originalUrl => _reference.startsWith('http') ? _reference : '';

  static bool _isNetwork(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage> {
  /// Nombre de nouvelles tentatives après l'échec de toutes les URL.
  static const int _maxRetries = 2;
  static final Random _random = Random();

  int _attempt = 0;

  @override
  void didUpdateWidget(covariant OptimizedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._reference != widget._reference) _attempt = 0;
  }

  void _retry(int fromAttempt) {
    if (!mounted || _attempt != fromAttempt) return;
    setState(() => _attempt = fromAttempt + 1);
  }

  Widget get _loading =>
      widget.placeholder ??
      _shimmerBox(
        width: widget.width,
        height: widget.height,
        color: widget.backgroundColor,
      );

  Widget get _fallback =>
      widget.errorWidget ??
      _placeholderBox(
        width: widget.width,
        height: widget.height,
        color: widget.backgroundColor,
        child: const Icon(
          Icons.broken_image_outlined,
          color: AzizColors.textSecondary,
          size: 24,
        ),
      );

  /// Toutes les URL ont échoué : nouvelle tentative différée, puis icône.
  Widget _retryOrFallback(String id) {
    final attempt = _attempt;
    if (attempt >= _maxRetries) return _fallback;

    final delay = Duration(
      milliseconds: 600 * (attempt + 1) + _random.nextInt(600),
    );
    return _RetryAfterDelay(
      key: ValueKey('retry-$id-$attempt'),
      delay: delay,
      onRetry: () => _retry(attempt),
      child: _loading,
    );
  }

  /// Web : décodage canvas, `<img>` HTML uniquement en repli.
  Widget _webImage(List<String> candidates) {
    final current = candidates.first;
    return Image.network(
      current,
      key: ValueKey('$current#$_attempt'),
      headers: widget.httpHeaders,
      fit: widget.fit,
      alignment: widget.alignment,
      width: widget.width,
      height: widget.height,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return _loading;
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[Image] ✖ chargement impossible : $current — $error');
        if (candidates.length > 1) {
          return _webImage(candidates.sublist(1));
        }
        return _retryOrFallback(current);
      },
    );
  }

  /// Mobile / bureau : cache disque, puis URL de repli.
  Widget _nativeImage(List<String> candidates) {
    final current = candidates.first;
    return CachedNetworkImage(
      key: ValueKey('$current#$_attempt'),
      imageUrl: current,
      cacheKey: candidates.length == 1 ? widget.cacheKey : null,
      httpHeaders: widget.httpHeaders,
      cacheManager: AzizartCacheManager.instance,
      fit: widget.fit,
      alignment: widget.alignment,
      width: widget.width,
      height: widget.height,
      memCacheWidth: widget.memCacheWidth,
      memCacheHeight: widget.memCacheHeight,
      fadeInDuration: const Duration(milliseconds: 250),
      fadeOutDuration: const Duration(milliseconds: 100),
      placeholder: (context, _) => _loading,
      errorWidget: (context, failedUrl, error) {
        debugPrint('[Image] ✖ chargement impossible : $failedUrl — $error');
        if (candidates.length > 1) {
          return _nativeImage(candidates.sublist(1));
        }
        return _retryOrFallback(current);
      },
    );
  }

  Widget _buildNetwork(String plain, double? logicalWidth, double dpr) {
    final pixelWidth = logicalWidth == null || !logicalWidth.isFinite
        ? null
        : logicalWidth * dpr.clamp(1.0, 2.0);

    final sized = MediaUrlResolver.sized(plain, pixelWidth: pixelWidth);
    final original = widget._originalUrl;

    final candidates = <String>[
      sized,
      if (plain != sized) plain,
      if (original.isNotEmpty && original != plain && original != sized)
        original,
    ];

    return kIsWeb ? _webImage(candidates) : _nativeImage(candidates);
  }

  @override
  Widget build(BuildContext context) {
    final plain =
        MediaUrlResolver.resolve(widget._reference, folder: widget.folder);

    if (!OptimizedImage._isNetwork(plain)) {
      return _clip(
        _placeholderBox(
          width: widget.width,
          height: widget.height,
          color: widget.backgroundColor,
          child: widget.errorWidget,
        ),
      );
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);

    final Widget image;
    final w = widget.width;
    if (w != null && w.isFinite) {
      image = _buildNetwork(plain, w, dpr);
    } else {
      image = LayoutBuilder(
        builder: (context, constraints) => _buildNetwork(
          plain,
          constraints.hasBoundedWidth ? constraints.maxWidth : null,
          dpr,
        ),
      );
    }

    return _clip(image);
  }

  Widget _clip(Widget child) {
    final radius = widget.borderRadius;
    if (radius == null) return child;
    return ClipRRect(borderRadius: radius, child: child);
  }
}

/// Affiche [child] et déclenche [onRetry] une seule fois après [delay].
class _RetryAfterDelay extends StatefulWidget {
  final Duration delay;
  final VoidCallback onRetry;
  final Widget child;

  const _RetryAfterDelay({
    super.key,
    required this.delay,
    required this.onRetry,
    required this.child,
  });

  @override
  State<_RetryAfterDelay> createState() => _RetryAfterDelayState();
}

class _RetryAfterDelayState extends State<_RetryAfterDelay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, widget.onRetry);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Widget _placeholderBox({
  double? width,
  double? height,
  Color? color,
  Widget? child,
}) {
  return Container(
    width: width,
    height: height,
    color: color ?? AzizColors.lightSurface,
    alignment: Alignment.center,
    child: child,
  );
}

Widget _shimmerBox({
  double? width,
  double? height,
  Color? color,
}) {
  final base = color ?? AzizColors.lightSurface;
  return Shimmer.fromColors(
    baseColor: base,
    highlightColor: Colors.white.withValues(alpha: 0.6),
    child: Container(width: width, height: height, color: base),
  );
}