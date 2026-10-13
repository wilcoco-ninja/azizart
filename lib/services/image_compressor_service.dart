import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:image/image.dart' as img;

import 'image_compressor_stub.dart'
    if (dart.library.js_interop) 'image_compressor_web.dart' as browser;

enum ImageTargetType { avatar, banner, artwork }

/// Résultat de compression : octets + extension réelle (sans point).
class CompressedImage {
  final Uint8List bytes;
  final String extension;
  final bool wasCompressed;

  const CompressedImage({
    required this.bytes,
    required this.extension,
    required this.wasCompressed,
  });
}

/// Fichier impossible à lire comme image. `toString()` renvoie un message
/// lisible : les écrans qui affichent `$e` restent compréhensibles.
class UnsupportedImageException implements Exception {
  final String message;
  const UnsupportedImageException([
    this.message =
        'Format d\'image non pris en charge. Utilisez une photo JPEG, PNG ou WebP.',
  ]);

  @override
  String toString() => message;
}

typedef _CompressJob = ({Uint8List bytes, int maxLongSide, int quality});

/// Pipeline Dart (mobile/bureau, ou repli sur le Web) : exécuté dans un
/// isolate sur mobile/bureau.
Uint8List? _compressJob(_CompressJob job) {
  try {
    final decoded = img.decodeImage(job.bytes);
    if (decoded == null) return null;

    // Applique l'orientation EXIF (photos de téléphone).
    var image = img.bakeOrientation(decoded);

    // Plafond sur le côté le plus long, sans jamais agrandir.
    final longest = math.max(image.width, image.height);
    if (longest > job.maxLongSide) {
      final scale = job.maxLongSide / longest;
      image = img.copyResize(
        image,
        width: math.max(1, (image.width * scale).round()),
        height: math.max(1, (image.height * scale).round()),
        interpolation: img.Interpolation.average,
      );
    }

    // Le JPEG n'a pas de transparence : fond blanc au lieu de noir.
    if (image.numChannels == 4) {
      final background = img.Image(width: image.width, height: image.height);
      img.fill(background, color: img.ColorRgb8(255, 255, 255));
      image = img.compositeImage(background, image);
    }

    return Uint8List.fromList(img.encodeJpg(image, quality: job.quality));
  } catch (_) {
    return null;
  }
}

class ImageCompressorService {
  const ImageCompressorService._();

  static ({int maxLongSide, int quality}) _settings(ImageTargetType type) {
    switch (type) {
      case ImageTargetType.avatar:
        return (maxLongSide: 800, quality: 85);
      case ImageTargetType.banner:
        return (maxLongSide: 1920, quality: 85);
      case ImageTargetType.artwork:
        return (maxLongSide: 2400, quality: 88);
    }
  }

  /// Extension déduite du CONTENU (octets magiques), jamais du nom de fichier.
  /// `null` si ce n'est pas un JPEG, PNG ou WebP.
  static String? _sniffExtension(Uint8List b) {
    if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
      return 'jpg';
    }
    if (b.length >= 8 &&
        b[0] == 0x89 &&
        b[1] == 0x50 &&
        b[2] == 0x4E &&
        b[3] == 0x47) {
      return 'png';
    }
    if (b.length >= 12 &&
        b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 &&
        b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) {
      return 'webp';
    }
    return null;
  }

  /// Redimensionne et convertit en JPEG sRGB.
  ///
  /// Web : le navigateur décode et encode (rapide, orientation et profil
  /// couleur gérés nativement). Repli : pipeline Dart.
  /// Un fichier illisible lève [UnsupportedImageException] ; un JPEG/PNG/WebP
  /// valide que le décodeur Dart ne sait pas traiter est conservé tel quel.
  static Future<CompressedImage> compress({
    required Uint8List rawBytes,
    required ImageTargetType type,
    String? fileName,
  }) async {
    if (rawBytes.isEmpty) {
      throw const UnsupportedImageException('Le fichier est vide.');
    }
    final settings = _settings(type);

    if (kIsWeb) {
      final out = await browser.compressWithBrowser(
        rawBytes,
        maxLongSide: settings.maxLongSide,
        quality: settings.quality / 100,
      );
      if (out != null && out.isNotEmpty) {
        return CompressedImage(bytes: out, extension: 'jpg', wasCompressed: true);
      }
    }

    final result = await compute<_CompressJob, Uint8List?>(
      _compressJob,
      (
        bytes: rawBytes,
        maxLongSide: settings.maxLongSide,
        quality: settings.quality,
      ),
    );
    if (result != null) {
      return CompressedImage(bytes: result, extension: 'jpg', wasCompressed: true);
    }

    final sniffed = _sniffExtension(rawBytes);
    if (sniffed != null) {
      return CompressedImage(
        bytes: rawBytes,
        extension: sniffed,
        wasCompressed: false,
      );
    }
    throw const UnsupportedImageException();
  }

  /// Compatibilité avec les appels existants.
  static Future<Uint8List> compressForWebAndMobile({
    required Uint8List rawBytes,
    required ImageTargetType type,
  }) async {
    final result = await compress(rawBytes: rawBytes, type: type);
    return result.bytes;
  }
}