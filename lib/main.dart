import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config.dart';
import 'theme/aziz_colors.dart';

Future<void> main() async {
  // URLs propres (sans « # ») : indispensable pour que le lien de
  // réinitialisation reçu par e-mail (/admin/reset-password) soit lu.
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration du cache d'images pour optimiser la mémoire
  PaintingBinding.instance.imageCache.maximumSizeBytes = 120 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 800;

  // Initialisation du backend de données et d'authentification
  // (les fichiers médias sont servis par Cloudflare R2).
  try {
    await Supabase.initialize(
      url: AppConfig.url,
      publishableKey: AppConfig.anonKey,
    );
  } catch (e, st) {
    debugPrint('[Startup] ✖ initialisation backend : $e\n$st');
    runApp(const _StartupErrorApp());
    return;
  }

  runApp(const AzizArtApp());
}

/// Écran affiché si l'initialisation échoue, à la place d'une page blanche.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AzizColors.backgroundDark,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Impossible de démarrer l\'application.\n'
              'Vérifiez votre connexion et rechargez la page.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AzizColors.textPrimary, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}