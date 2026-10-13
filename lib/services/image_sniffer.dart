import 'dart:typed_data';

/// Détection du type réel d'une image par ses « magic numbers ».
///
/// Fiable sur Web et sur mobile (le nom de fichier et le `mimeType` fourni
/// par les sélecteurs ne le sont pas). Remplace les trois copies qui
/// existaient dans `admin_forms`, `media_form_page` et `admin_avatar_picker`.
class ImageSniffer {
  const ImageSniffer._();

  static const String unknown = 'application/octet-stream';
  static const String heic = 'image/heic';

  static bool _matches(Uint8List b, int offset, List<int> signature) {
    if (b.length < offset + signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (b[offset + i] != signature[i]) return false;
    }
    return true;
  }

  /// Marques « ftyp » des fichiers HEIC / HEIF (photos d'iPhone).
  static const Set<String> _heifBrands = {
    'heic', 'heix', 'heif', 'hevc', 'hevx', 'heim', 'heis', 'mif1', 'msf1',
  };

  /// Retourne `image/jpeg`, `image/png`, `image/webp`, `image/gif`,
  /// `image/heic` ou [unknown].
  static String detectMime(Uint8List b) {
    if (_matches(b, 0, const [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
    if (_matches(b, 0, const [0x89, 0x50, 0x4E, 0x47])) return 'image/png';
    if (_matches(b, 0, const [0x52, 0x49, 0x46, 0x46]) &&
        _matches(b, 8, const [0x57, 0x45, 0x42, 0x50])) {
      return 'image/webp';
    }
    if (_matches(b, 0, const [0x47, 0x49, 0x46, 0x38])) return 'image/gif';
    if (_matches(b, 4, const [0x66, 0x74, 0x79, 0x70]) && b.length >= 12) {
      final brand = String.fromCharCodes(b.sublist(8, 12));
      if (_heifBrands.contains(brand)) return heic;
    }
    return unknown;
  }

  /// Extension (avec point) correspondant à [mime] ; `.jpg` par défaut.
  static String extensionFromMime(String mime) {
    switch (mime) {
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'image/gif':
        return '.gif';
      case heic:
        return '.heic';
      default:
        return '.jpg';
    }
  }
}