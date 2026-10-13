import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../services/r2_storage_service.dart';

/// Évite les fichiers R2 orphelins dans les formulaires d'administration.
///
/// Chaque image envoyée pendant la session est mémorisée via [trackUpload].
///  • À l'enregistrement réussi : [commitUploads] supprime de R2 les envois
///    intermédiaires qui ne sont pas conservés (`keep`).
///  • Si le formulaire est quitté sans enregistrement : `dispose()` supprime
///    tous les envois de la session.
///
/// Les images déjà enregistrées en base ne sont jamais touchées ici : leur
/// remplacement est géré par les services (`updateX` purge l'ancien fichier).
mixin UploadSessionCleanup<T extends StatefulWidget> on State<T> {
  final Set<String> _sessionUploads = <String>{};
  bool _uploadsCommitted = false;

  void trackUpload(String url) {
    final value = url.trim();
    if (value.isNotEmpty) _sessionUploads.add(value);
  }

  Future<void> commitUploads({required Iterable<String?> keep}) async {
    _uploadsCommitted = true;
    final keepKeys = <String>{
      for (final reference in keep)
        ?R2StorageService.keyFromReference(reference ?? ''),
    };
    final stale = _sessionUploads.where((url) {
      final key = R2StorageService.keyFromReference(url);
      return key != null && !keepKeys.contains(key);
    }).toList();
    _sessionUploads.clear();
    if (stale.isNotEmpty) await _purge(stale);
  }

  Future<void> _purge(List<String> urls) async {
    try {
      await R2StorageService().deleteReferences(urls);
    } catch (e) {
      debugPrint('UploadSessionCleanup: fichiers R2 non supprimés — $e');
    }
  }

  @override
  void dispose() {
    if (!_uploadsCommitted && _sessionUploads.isNotEmpty) {
      unawaited(_purge(_sessionUploads.toList()));
    }
    super.dispose();
  }
}