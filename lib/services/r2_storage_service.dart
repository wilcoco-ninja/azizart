import 'dart:async';
import 'dart:math' show Random;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

/// Erreur d'envoi vers R2. `toString()` renvoie directement un message
/// lisible en français : les écrans existants qui affichent `$e` restent
/// donc compréhensibles.
class R2UploadException implements Exception {
  final String message;
  final bool retryable;
  const R2UploadException(this.message, {this.retryable = false});

  @override
  String toString() => message;
}

class R2StorageService {
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Plafonds de taille : alignés sur les écrans (media_form_page accepte
  /// jusqu'à 100 Mo de vidéo ; les images doivent rester légères).
  static const int _maxImageBytes = 10 * 1024 * 1024; // 10 Mo
  static const int _maxMediaBytes = 100 * 1024 * 1024; // 100 Mo

  /// Au-delà, on ne relance pas automatiquement un envoi qui a échoué.
  static const int _retryLimitBytes = 20 * 1024 * 1024;

  static const Duration _presignTimeout = Duration(seconds: 30);

  /// Dossiers autorisés — DOIT rester identique à ALLOWED_FOLDERS de la
  /// fonction Edge `r2-presign` (c'est elle qui fait foi).
  static const Set<String> _uploadAllowedFolders = <String>{
    'atelier',
    'gallery',
    'logo',
    'about_avatars',
    'about_banners',
    'home_events',
    'media',
  };

  /// Domaines média connus en plus du domaine de [AppConfig.r2PublicUrl] :
  /// une URL enregistrée avant un changement de domaine reste supprimable.
  static const Set<String> _knownMediaHosts = <String>{'media.azizart.com'};

  /// Même format que `KEY_PATTERN` de la fonction Edge `r2-presign`.
  static final RegExp _keyPattern =
      RegExp(r'^[a-z0-9_]+(/[A-Za-z0-9._\-]+)+$');

  static bool _isManagedHost(String host) {
    final h = host.toLowerCase();
    if (h.isEmpty) return false;
    final configured = Uri.tryParse(AppConfig.r2PublicUrl)?.host.toLowerCase();
    return h == configured ||
        h.endsWith('.r2.dev') ||
        h.endsWith('.r2.cloudflarestorage.com') ||
        _knownMediaHosts.contains(h);
  }

  /// Clé R2 correspondant à [reference] (URL publique du bucket ou chemin
  /// relatif), ou `null` si ce n'est pas un fichier géré par ce bucket
  /// (lien YouTube, asset, vide…). La requête (`?v=…`) est ignorée.
  ///
  /// Un nom nu (`photo.jpg`) reçoit [defaultFolder] s'il est fourni.
  static String? keyFromReference(String reference, {String? defaultFolder}) {
    final value = reference.trim();
    if (value.isEmpty || value.startsWith('assets/')) return null;

    final isUrl = value.startsWith('http://') || value.startsWith('https://');
    var path = value;

    if (isUrl) {
      final uri = Uri.tryParse(value);
      if (uri == null || !_isManagedHost(uri.host)) return null;
      try {
        path = Uri.decodeComponent(uri.path);
      } catch (_) {
        return null;
      }
    } else {
      path = value.split('#').first.split('?').first;
    }

    path = path.replaceFirst(RegExp(r'^/+'), '');
    if (path.isEmpty) return null;

    var key = path;
    if (!_uploadAllowedFolders.contains(path.split('/').first)) {
      final folder = defaultFolder;
      if (isUrl ||
          folder == null ||
          !_uploadAllowedFolders.contains(folder)) {
        return null;
      }
      key = '$folder/$path';
    }

    if (!_keyPattern.hasMatch(key)) return null;
    if (key.split('/').any((segment) => segment == '.' || segment == '..')) {
      return null;
    }
    return key;
  }

  // ── Upload ────────────────────────────────────────────────────────────
  /// Envoie [bytes] vers R2 et retourne l'URL publique.
  /// Deux tentatives maximum (nouvelle URL signée à chaque tentative).
  Future<String> upload({
    required String key,
    required Uint8List bytes,
    String? contentType,
    String? fileName,
  }) async {
    if (bytes.isEmpty) {
      throw const R2UploadException('Le fichier est vide.');
    }
    final ct = _normalizeMime(
      contentType ?? lookupMimeType(fileName ?? key) ?? '',
    );
    if (ct.isEmpty) {
      throw const R2UploadException('Type de fichier non reconnu.');
    }

    final maxBytes = ct.startsWith('image/') ? _maxImageBytes : _maxMediaBytes;
    if (bytes.length > maxBytes) {
      final sizeMo = (bytes.length / 1024 / 1024).toStringAsFixed(1);
      throw R2UploadException(
        'Fichier trop volumineux ($sizeMo Mo, maximum ${maxBytes ~/ 1024 ~/ 1024} Mo).',
      );
    }

    // Délai proportionnel à la taille : 45 s + 15 s par Mo (plafond 15 min)
    final mo = bytes.length / 1024 / 1024;
    final putTimeout = Duration(seconds: (45 + mo * 15).clamp(45, 900).round());
    final canRetry = bytes.length <= _retryLimitBytes;
    debugPrint('[R2] ▶ upload key=$key type=$ct taille=${mo.toStringAsFixed(2)} Mo');

    R2UploadException? last;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final data = await _presign({
          'action': 'upload',
          'key': key,
          'contentType': ct,
        });

        final uploadUrl = data['uploadUrl'] as String?;
        final publicUrl = data['publicUrl'] as String?;
        if (uploadUrl == null || publicUrl == null) {
          throw const R2UploadException(
            'Réponse invalide du service de stockage.',
          );
        }

        debugPrint('[R2] ✔ URL signée obtenue, envoi en cours…');
        final res = await http
            .put(
              Uri.parse(uploadUrl),
              headers: {'Content-Type': ct},
              body: bytes,
            )
            .timeout(putTimeout);

        debugPrint('[R2] PUT → HTTP ${res.statusCode}');
        if (res.statusCode >= 200 && res.statusCode < 300) return publicUrl;

        if (res.statusCode == 401 || res.statusCode == 403) {
          debugPrint('[R2] ✖ refus R2 : ${res.body}');
          throw R2UploadException(
            'Le stockage R2 a refusé l\'envoi — ${_r2Diagnostic(res.body)}.',
          );
        }
        throw R2UploadException(
          'Envoi refusé par le stockage (code ${res.statusCode}).',
          retryable: res.statusCode >= 500,
        );
      } on R2UploadException catch (e) {
        last = e;
        if (!e.retryable || !canRetry) rethrow;
      } on TimeoutException {
        last = const R2UploadException(
          'Connexion trop lente : l\'envoi a expiré. '
          'Essayez avec un fichier plus léger.',
          retryable: true,
        );
        if (!canRetry) throw last;
      } on http.ClientException {
        last = const R2UploadException(
          'Envoi impossible : connexion perdue ou bloquée par le navigateur (CORS).',
          retryable: true,
        );
        if (!canRetry) throw last;
      }
    }
    throw last ??
        const R2UploadException('Échec de l\'envoi. Réessayez dans un instant.');
  }

  // ── Suppression ───────────────────────────────────────────────────────
  Future<void> delete(String key) async {
    final data = await _presign({'action': 'delete', 'key': key});
    final deleteUrl = data['deleteUrl'] as String?;
    if (deleteUrl == null) {
      throw const R2UploadException(
        'URL de suppression invalide retournée par le service.',
      );
    }

    try {
      final res = await http
          .delete(Uri.parse(deleteUrl))
          .timeout(const Duration(seconds: 60));
      // 404 = déjà supprimé : on considère que c'est un succès.
      if (res.statusCode != 200 &&
          res.statusCode != 204 &&
          res.statusCode != 404) {
        throw R2UploadException(
          'Suppression refusée par le stockage (code ${res.statusCode}).',
        );
      }
    } on TimeoutException {
      throw const R2UploadException('Suppression expirée. Réessayez.');
    } on http.ClientException {
      throw const R2UploadException(
        'Suppression impossible : connexion perdue ou bloquée '
        '(vérifiez que la règle CORS du bucket R2 autorise la méthode DELETE).',
      );
    }
  }

  /// Supprime de R2 les fichiers désignés par [references] (URL publiques ou
  /// chemins relatifs). Les références externes sont ignorées ; un fichier
  /// déjà absent (404) compte comme supprimé.
  ///
  /// Lève [R2UploadException] au premier échec : l'appelant peut ainsi
  /// conserver la ligne en base et laisser l'administrateur réessayer, au
  /// lieu de laisser un fichier orphelin.
  Future<void> deleteReferences(
    Iterable<String?> references, {
    String? defaultFolder,
  }) async {
    final keys = <String>{};
    for (final reference in references) {
      final key = keyFromReference(reference ?? '', defaultFolder: defaultFolder);
      if (key != null) keys.add(key);
    }
    for (final key in keys) {
      await delete(key);
      debugPrint('[R2] ✔ supprimé $key');
    }
  }

  // ── Clé unique et nettoyée ────────────────────────────────────────────
  String buildKey({required String folder, required String fileName}) {
    if (!_uploadAllowedFolders.contains(folder)) {
      throw ArgumentError.value(
        folder,
        'folder',
        'Dossier R2 invalide. Dossiers autorisés : $_uploadAllowedFolders.',
      );
    }

    final cleanFileName = fileName.split('/').last.split('\\').last;
    final safe = cleanFileName
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .toLowerCase();

    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final stamp = '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';

    // Suffixe aléatoire : deux envois du même fichier dans la même seconde
    // ne s'écrasent plus.
    final random = Random().nextInt(0x7fffffff).toRadixString(36);

    return '$folder/${stamp}_${random}_$safe';
  }

  String _normalizeMime(String mime) {
    final m = mime.trim().toLowerCase();
    return m == 'image/jpg' ? 'image/jpeg' : m;
  }

  // ── Interne : appel de la fonction Edge ───────────────────────────────
  Future<void> _ensureSession() async {
    final auth = _supabase.auth;
    final session = auth.currentSession;
    if (session == null) {
      throw const R2UploadException(
        'Session expirée. Reconnectez-vous pour envoyer des images.',
      );
    }
    final expiresAt = session.expiresAt; // secondes depuis l'epoch
    if (expiresAt != null) {
      final remaining =
          expiresAt - DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (remaining < 60) {
        try {
          await auth.refreshSession();
        } catch (_) {
          throw const R2UploadException(
            'Session expirée. Reconnectez-vous pour envoyer des images.',
          );
        }
      }
    }
  }

  Future<Map<String, dynamic>> _presign(Map<String, dynamic> body) async {
    await _ensureSession();

    var attempt = 0;
    var refreshed = false;
    while (true) {
      try {
        final res = await _supabase.functions
            .invoke('r2-presign', body: body)
            .timeout(_presignTimeout);

        final data = res.data;
        debugPrint('[R2] presign → HTTP ${res.status}');
        if (data is Map) return Map<String, dynamic>.from(data);
        throw const R2UploadException(
          'Réponse invalide du service de stockage.',
        );
      } on FunctionException catch (e) {
        debugPrint('[R2] ✖ presign HTTP ${e.status} : ${e.details}');
        // 401 : le jeton de session est peut-être ancien (ex. après une
        // rotation des clés Supabase). On le renouvelle UNE fois et on réessaie.
        if (e.status == 401 && !refreshed) {
          refreshed = true;
          try {
            await _supabase.auth.refreshSession();
            continue;
          } catch (_) {
            // on retombe sur le message clair ci-dessous
          }
        }
        final err = _mapFunctionError(e);
        if (err.retryable && attempt == 0) {
          attempt++;
          await Future<void>.delayed(const Duration(seconds: 1));
          continue;
        }
        throw err;
      } on TimeoutException {
        if (attempt == 0) {
          attempt++;
          continue;
        }
        throw const R2UploadException(
          'Le service de stockage met trop de temps à répondre. '
          'Réessayez dans un instant.',
          retryable: true,
        );
      }
    }
  }

  /// Traduit la réponse d'erreur XML de R2 en cause lisible.
  String _r2Diagnostic(String body) {
    final code = RegExp(r'<Code>([^<]+)</Code>').firstMatch(body)?.group(1);
    final msg = RegExp(r'<Message>([^<]+)</Message>').firstMatch(body)?.group(1);
    final cause = switch (code) {
      'InvalidAccessKeyId' =>
        'R2_ACCESS_KEY_ID inconnu ou révoqué (jeton R2 à remplacer dans les secrets)',
      'SignatureDoesNotMatch' =>
        'R2_SECRET_ACCESS_KEY incorrect dans les secrets de la fonction',
      'AccessDenied' =>
        'jeton R2 sans permission « Object Read & Write » sur ce bucket, ou URL expirée',
      _ => 'jeton R2 ou signature refusés',
    };
    final tech = [code, msg].whereType<String>().join(' : ');
    return tech.isEmpty ? cause : '$cause [$tech]';
  }

  R2UploadException _mapFunctionError(FunctionException e) {
    final details = e.details;
    final detail = details is Map
        ? details['error']?.toString()
        : details?.toString();

    switch (e.status) {
      case 401:
        return const R2UploadException(
          'Session expirée. Reconnectez-vous.',
        );
      case 403:
        return const R2UploadException(
          'Ce compte n\'est pas autorisé à envoyer des images.',
        );
      case 400:
        return R2UploadException(
          'Requête refusée : ${detail ?? 'dossier ou type de fichier invalide'}.',
        );
      default:
        return R2UploadException(
          'Service de stockage indisponible (code ${e.status}).',
          retryable: e.status >= 500,
        );
    }
  }
}