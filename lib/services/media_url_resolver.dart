import '../config.dart';
import 'r2_storage_service.dart';

/// Point d'entrée unique : transforme toute référence d'image (URL R2,
/// ancienne URL Supabase Storage, chemin relatif) en URL publique R2.
///
/// Renvoie une chaîne vide si la référence est vide ou désigne un asset local.
class MediaUrlResolver {
  const MediaUrlResolver._();

  static const String _supabaseMarker = '/storage/v1/object/public/';
  static const String _bucketName = 'azizart-media';
  static const String _knownHost = 'media.azizart.com';
  static const String _resizeSegment = '/cdn-cgi/image/';

  /// Largeurs servies : peu de paliers = meilleur taux de cache CDN.
  static const List<int> _widthBuckets = [
    320, 480, 640, 828, 1080, 1440, 1920, 2400,
  ];

  /// Hôtes R2 gérés par ce projet (même logique que R2StorageService).
  static bool _isR2Host(String host) {
    final h = host.toLowerCase();
    final configured = Uri.tryParse(AppConfig.mediaBase)?.host.toLowerCase();
    return h == configured ||
        h == _knownHost ||
        h.endsWith('.r2.dev') ||
        h.endsWith('.r2.cloudflarestorage.com');
  }

  static String? _decodedPath(Uri uri) {
    try {
      return Uri.decodeComponent(uri.path);
    } catch (_) {
      return null;
    }
  }

  static String? _key(String path, String? folder) {
    var p = path.replaceFirst(RegExp(r'^/+'), '');
    if (p.startsWith('$_bucketName/')) p = p.substring(_bucketName.length + 1);
    return R2StorageService.keyFromReference(p, defaultFolder: folder);
  }

  /// Ré-encode chaque segment de la clé (espaces, accents) pour l'URL finale.
  static String _encodeKey(String key) =>
      key.split('/').map(Uri.encodeComponent).join('/');

  static String resolve(String? reference, {String? folder}) {
    final value = (reference ?? '').trim();
    if (value.isEmpty || value.startsWith('assets/')) return '';

    final base = AppConfig.mediaBase;
    final isUrl = value.startsWith('http://') || value.startsWith('https://');

    if (isUrl) {
      final uri = Uri.tryParse(value);
      if (uri == null || base.isEmpty) return value;
      final path = _decodedPath(uri);
      if (path == null) return value;
      final host = uri.host.toLowerCase();

      // URL R2 (y compris un ancien domaine) : ramenée au domaine actuel.
      if (_isR2Host(host)) {
        final key = _key(path, null);
        if (key == null) return value;
        return '$base/${_encodeKey(key)}${uri.hasQuery ? '?${uri.query}' : ''}';
      }

      // Ancienne URL Supabase Storage : le fichier est cherché dans R2.
      if (host.endsWith('.supabase.co')) {
        final index = path.indexOf(_supabaseMarker);
        if (index < 0) return value;
        final afterMarker = path.substring(index + _supabaseMarker.length);
        final slash = afterMarker.indexOf('/');
        if (slash < 0) return value;
        final key = _key(afterMarker.substring(slash + 1), folder);
        return key == null ? value : '$base/${_encodeKey(key)}';
      }

      return value;
    }

    if (base.isEmpty) return '';
    var relative = value.replaceFirst(RegExp(r'^/+'), '');
    if (relative.startsWith('images/')) relative = relative.substring(7);
    final key = _key(relative, folder);
    return '$base/${_encodeKey(key ?? relative)}';
  }

  /// Plus petit palier de largeur couvrant [pixels] (plafonné à 2400).
  static int bucketWidth(double pixels) {
    for (final w in _widthBuckets) {
      if (pixels <= w) return w;
    }
    return _widthBuckets.last;
  }

  /// Variante redimensionnée par Cloudflare (JPEG/WebP/AVIF selon le
  /// navigateur). Renvoie [resolvedUrl] inchangée si le redimensionnement est
  /// désactivé, si la largeur est inconnue ou si l'URL n'est pas sur le
  /// domaine médias.
  static String sized(String resolvedUrl, {double? pixelWidth}) {
    final base = AppConfig.mediaBase;
    if (!AppConfig.imageResizing ||
        pixelWidth == null ||
        pixelWidth <= 0 ||
        base.isEmpty ||
        !resolvedUrl.startsWith('$base/') ||
        resolvedUrl.contains(_resizeSegment)) {
      return resolvedUrl;
    }
    final width = bucketWidth(pixelWidth);
    final objectPath = resolvedUrl.substring(base.length + 1);
    return '$base$_resizeSegment'
        'width=$width,quality=${AppConfig.imageQuality},format=auto,fit=scale-down'
        '/$objectPath';
  }
}