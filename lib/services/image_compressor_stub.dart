import 'dart:typed_data';

/// Version « vide » utilisée hors navigateur (Android, iOS, Windows, etc.).
///
/// Elle doit avoir exactement la même signature que `compressWithBrowser`
/// dans `image_compressor_web.dart`. Elle renvoie toujours `null`, ce qui
/// fait basculer `ImageCompressorService` sur le pipeline Dart (package
/// `image`, exécuté dans un isolate).
Future<Uint8List?> compressWithBrowser(
  Uint8List bytes, {
  required int maxLongSide,
  required double quality,
}) async {
  return null;
}