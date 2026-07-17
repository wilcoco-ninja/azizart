import 'package:supabase_flutter/supabase_flutter.dart';

// ══════════════════════════════════════════════════════════════════════════════
// AdminCredentialsService
//
// Ajoute une connexion admin par PSEUDO par-dessus Supabase Auth, qui ne
// connaît nativement que l'e-mail. Le mot de passe reste géré à 100% par
// Supabase Auth (jamais stocké ailleurs) ; seule la correspondance
// pseudo -> e-mail est gardée dans la table admin_settings (une seule
// ligne, id fixe 'main' — voir schema.sql).
//
// IMPORTANT (sécurité) : cette ligne doit être lisible publiquement, sans
// connexion, pour que la page de connexion puisse résoudre le pseudo AVANT
// l'authentification. Cela expose l'e-mail associé au pseudo (jamais le
// mot de passe). Compromis raisonnable pour un site à un seul compte admin.
// ══════════════════════════════════════════════════════════════════════════════
class AdminCredentialsService {
  final _db = Supabase.instance.client;
  static const _table = 'admin_settings';
  static const _rowId = 'main';

  /// Résout un pseudo vers l'e-mail Supabase Auth correspondant.
  /// Retourne `null` si la ligne n'existe pas encore, ou si le pseudo saisi
  /// ne correspond pas (comparaison insensible à la casse).
  Future<String?> resolveEmailForPseudo(String pseudo) async {
    final row = await _db.from(_table).select().eq('id', _rowId).maybeSingle();
    if (row == null) return null;
    final storedPseudo = (row['pseudo'] as String? ?? '').trim().toLowerCase();
    final enteredPseudo = pseudo.trim().toLowerCase();
    if (storedPseudo.isEmpty || storedPseudo != enteredPseudo) return null;
    return row['email'] as String?;
  }

  /// Lit le pseudo actuellement configuré, pour l'afficher dans "Mon
  /// compte". Retourne `null` si aucun pseudo n'a encore été défini.
  Future<String?> getCurrentPseudo() async {
    final row = await _db.from(_table).select().eq('id', _rowId).maybeSingle();
    return row?['pseudo'] as String?;
  }

  /// Crée ou met à jour la ligne admin_settings/main. Utilisé pour la
  /// configuration initiale du pseudo, ou pour le changer ensuite.
  /// [email] doit toujours être l'e-mail du compte Supabase Auth
  /// actuellement connecté, sinon la connexion par pseudo cessera de
  /// fonctionner pour ce compte.
  Future<void> setPseudo(
      {required String pseudo, required String email}) async {
    await _db.from(_table).upsert({
      'id': _rowId,
      'pseudo': pseudo.trim(),
      'email': email.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Change le mot de passe du compte admin actuellement connecté.
  /// On vérifie d'abord [currentPassword] via une nouvelle connexion
  /// (comportement identique quel que soit le réglage "Secure password
  /// change" du projet Supabase), puis on appelle updateUser().
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _db.auth.currentUser?.email;
    if (email == null) {
      throw StateError('Aucun administrateur connecté.');
    }

    // Vérifie le mot de passe actuel.
    await _db.auth.signInWithPassword(email: email, password: currentPassword);

    // Applique le nouveau mot de passe.
    await _db.auth.updateUser(UserAttributes(password: newPassword));
  }
}
