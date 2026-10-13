import 'package:flutter/foundation.dart' show kIsWeb;

/// Configuration publique de l'application.
///
/// Flutter NE LIT PAS le fichier .env : les valeurs viennent de
/// `--dart-define` / `--dart-define-from-file`. Les valeurs par défaut
/// ci-dessous sont celles de production (clé « publishable » : conçue pour
/// être publique, la sécurité repose sur la RLS et sur la fonction r2-presign).
///
/// ⚠️ Ne mets JAMAIS ici : une clé secrète / service_role,
/// ni R2_ACCESS_KEY_ID / R2_SECRET_ACCESS_KEY.
class AppConfig {
  const AppConfig._();

  /// URL de l'API de données et d'authentification.
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://nqzrynteyovxzvahonpx.supabase.co',
  );

  /// Clé publishable (publique par conception).
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_JiIWJ1SGBT7DoBM9ZiIolg_nd3qoLI3',
  );

  /// URL publique des médias Cloudflare R2.
  ///
  /// Tant qu'aucun domaine personnalisé n'est connecté au bucket, on garde
  /// l'URL r2.dev. Une fois `media.<votre-domaine>` actif, remplacez la valeur
  /// par défaut (ou build avec --dart-define=R2_PUBLIC_URL=https://media...).
  static const String r2PublicUrl = String.fromEnvironment(
    'R2_PUBLIC_URL',
    defaultValue: 'https://pub-683ade17eed84c96a53d0631e8f03742.r2.dev',
  );

  /// Redimensionnement demandé (désactivable avec --dart-define=IMAGE_RESIZING=false).
  static const bool _resizingRequested = bool.fromEnvironment(
    'IMAGE_RESIZING',
    defaultValue: true,
  );

  /// Redimensionnement Cloudflare (`/cdn-cgi/image/...`) : effectif seulement
  /// sur un domaine personnalisé de la zone (jamais sur r2.dev, qui ne le
  /// propose pas) et si Images → Transformations est activé.
  static bool get imageResizing {
    if (!_resizingRequested) return false;
    final host = Uri.tryParse(mediaBase)?.host.toLowerCase() ?? '';
    return host.isNotEmpty &&
        !host.endsWith('.r2.dev') &&
        !host.endsWith('.r2.cloudflarestorage.com');
  }

  /// Qualité JPEG/WebP des variantes redimensionnées (0-100).
  static const int imageQuality = int.fromEnvironment(
    'IMAGE_QUALITY',
    defaultValue: 82,
  );

  /// [r2PublicUrl] sans espaces ni « / » final : à utiliser pour construire
  /// toute URL de média.
  static String get mediaBase =>
      r2PublicUrl.trim().replaceAll(RegExp(r'/+$'), '');

  /// URLs des logos générées dynamiquement à partir de [mediaBase]
  static String get logoPublicUrl => '$mediaBase/logo/logo.png';
  static String get logoAdminUrl => '$mediaBase/logo/logo0.png';

  static const String _baseUrlOverride = String.fromEnvironment('BASE_URL');

  /// Adresse publique du site : lue dans le navigateur (vercel.app, puis le
  /// futur domaine) sans rien modifier. Surchargeable avec --dart-define=BASE_URL=...
  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride.trim().replaceAll(RegExp(r'/+$'), '');
    }
    return kIsWeb ? Uri.base.origin : '';
  }
}