import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Cache disque des images (Android, iOS, bureau).
///
/// Sur le Web il n'y a pas de système de fichiers : `JsonCacheInfoRepository`
/// y échoue, ce qui fait afficher le widget d'erreur à la place de l'image.
/// Le navigateur gère déjà son cache HTTP : [forPlatform] renvoie donc `null`
/// sur le Web et `CachedNetworkImage` retombe sur son gestionnaire par défaut.
///
/// À passer à `CachedNetworkImage(cacheManager: AzizartCacheManager.forPlatform)`.
class AzizartCacheManager {
  static const String key = 'azizart_image_cache';

  static CacheManager? get forPlatform => kIsWeb ? null : instance;

  // Initialisé à la première lecture seulement : jamais construit sur le Web.
  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 500,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}