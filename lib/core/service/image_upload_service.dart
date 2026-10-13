import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Service d'upload d'images — optimisé pour Supabase Storage
/// (bucket "site-images", créé par schema.sql).
class ImageUploadService {
  static const String bucketName = 'site-images';
  
  final _client = Supabase.instance.client;
  
  // 1. Bonne pratique : Réutiliser la même instance de ImagePicker
  final ImagePicker _picker = ImagePicker();

  /// Vérifie si l'utilisateur est connecté et est un admin
  Future<bool> _checkAdminPermissions() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      debugPrint('ImageUploadService: Utilisateur non connecté');
      return false;
    }
    
    try {
      // Vérifier si l'utilisateur est dans la table admins
      final response = await _client
          .from('admins')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      
      if (response == null) {
        debugPrint('ImageUploadService: Utilisateur ${user.id} n\'est pas dans la table admins');
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('ImageUploadService: Erreur vérification admin: $e');
      return false;
    }
  }

  /// Ouvre le sélecteur d'image et retourne les octets choisis, ou `null`
  /// si l'utilisateur annule.
  /// Utilise ImagePicker qui est compatible Web, Mobile et Desktop.
  Future<Uint8List?> pickImage() async {
    try {
      // 2. CRUCIAL : Ajout de la compression. 
      // Évite d'uploader des images de 10 Mo qui ralentissent l'app.
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compresse légèrement l'image (invisible à l'œil nu)
        maxWidth: 1920,   // Redimensionne les images trop grandes
        maxHeight: 1920,
      );
      
      if (image == null) return null;
      
      // readAsBytes() est compatible avec toutes les plateformes (y compris le Web)
      return await image.readAsBytes();
    } catch (e) {
      debugPrint('ImageUploadService: Erreur pickImage: $e');
      return null;
    }
  }

  /// Envoie [bytes] dans le dossier [folder] du bucket "site-images" et
  /// retourne l'URL publique.
  Future<String?> upload(Uint8List bytes, {required String folder}) async {
    final isAdmin = await _checkAdminPermissions();
    if (!isAdmin) {
      debugPrint('ImageUploadService: Permissions refusées - utilisateur non admin ou non connecté');
      throw Exception('Permissions insuffisantes. Vérifiez que vous êtes connecté avec un compte admin inscrit dans la table "admins".');
    }

    try {
      final fileName = '${DateTime.now().microsecondsSinceEpoch}.jpg';
      
      // 3. Sécurisation : Enlever le slash final de `folder` s'il y en a un par erreur
      final cleanFolder = folder.endsWith('/') ? folder.substring(0, folder.length - 1) : folder;
      final path = '$cleanFolder/$fileName';

      debugPrint('ImageUploadService: Upload vers $bucketName/$path (${bytes.length} bytes)');

      final bucket = _client.storage.from(bucketName);
      await bucket.uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      final url = bucket.getPublicUrl(path);
      debugPrint('ImageUploadService: Upload réussi - URL: $url');
      return url;
      
    } on StorageException catch (e) {
      // 4. Amélioration de la détection des erreurs Supabase
      String message = 'Erreur upload';
      final errorMsg = e.message.toLowerCase();
      
      if (errorMsg.contains('permission') || e.statusCode == '403') {
        message = 'Permissions insuffisantes pour uploader. Vérifiez les politiques de sécurité (RLS) de votre bucket.';
      } else if (errorMsg.contains('bucket') || e.statusCode == '404') {
        message = 'Bucket de storage introuvable. Exécutez d\'abord supabase/seed.sql.';
      } else if (errorMsg.contains('jwt')) {
        message = 'Session expirée. Reconnectez-vous.';
      } else {
        message = 'Erreur upload: ${e.message}';
      }
      
      debugPrint('ImageUploadService: StorageException - $message');
      throw Exception(message);
    } catch (e) {
      debugPrint('ImageUploadService: Erreur upload inattendue: $e');
      throw Exception('Erreur upload inattendue: $e');
    }
  }
}