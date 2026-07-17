import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service d'upload d'images — remplace Firebase Storage par Supabase
/// Storage (bucket "site-images", créé par schema.sql).
///
/// Signature IDENTIQUE à l'ancienne version Firebase (pickImage / upload) :
/// aucun changement nécessaire dans admin_forms.dart, qui appelle déjà
/// `_up.pickImage()` et `_up.upload(bytes, folder: '...')`.
class ImageUploadService {
  final _bucket = Supabase.instance.client.storage.from('site-images');
  final _picker = ImagePicker();

  /// Ouvre le sélecteur d'image et retourne les octets choisis, ou `null`
  /// si l'utilisateur annule.
  Future<Uint8List?> pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    return await file.readAsBytes();
  }

  /// Envoie [bytes] dans le dossier [folder] du bucket "site-images" et
  /// retourne l'URL publique, ou `null` en cas d'échec.
  Future<String?> upload(Uint8List bytes, {required String folder}) async {
    try {
      final fileName = '${DateTime.now().microsecondsSinceEpoch}.jpg';
      final path = '$folder/$fileName';

      await _bucket.uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      return _bucket.getPublicUrl(path);
    } catch (e) {
      return null;
    }
  }
}
