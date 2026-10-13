/*
 * Developed by Wilcoco
 * Application: AzizArt
 * Description: Service de gestion des identifiants et de l'authentification Supabase Admin.
 */

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Erreur métier dont `toString()` est directement lisible par l'utilisateur.
class AdminCredentialsException implements Exception {
  final String message;
  const AdminCredentialsException(this.message);

  @override
  String toString() => message;
}

class AdminCredentialsService {
  final _db = Supabase.instance.client;
  static const _table = 'admin_settings';

  /// Valide un pseudo ; retourne un message d'erreur ou null si valide.
  static String? validatePseudo(String? value) {
    final t = (value ?? '').trim();
    if (t.isEmpty) return 'Ce champ est obligatoire';
    if (t.length < 3) return 'Au moins 3 caractères';
    if (t.contains('@')) return 'Le pseudo ne doit pas contenir de « @ »';
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────
  // MESSAGES D'ERREUR LISIBLES (le code technique est conservé entre
  // parenthèses : il permet d'identifier la cause exacte côté Supabase)
  // ─────────────────────────────────────────────────────────────────────

  /// Message français pour une erreur d'authentification Supabase.
  static String describeAuthError(AuthException e) {
    final code = (e.code ?? '').trim();
    final message = switch (code) {
      'invalid_credentials' => 'Mot de passe actuel incorrect.',
      'weak_password' =>
        'Mot de passe refusé par les règles de sécurité (trop faible ou '
            'trop courant). Utilisez au moins 8 caractères avec majuscule, '
            'minuscule et chiffre.',
      'same_password' =>
        'Le nouveau mot de passe doit être différent de l\'ancien.',
      'over_request_rate_limit' ||
      'over_email_send_rate_limit' =>
        'Trop de tentatives. Patientez quelques minutes puis réessayez.',
      'reauthentication_needed' ||
      'reauthentication_not_valid' =>
        'Une confirmation est exigée : déconnectez-vous, reconnectez-vous '
            'puis réessayez.',
      'session_not_found' ||
      'session_expired' ||
      'refresh_token_not_found' ||
      'refresh_token_already_used' =>
        'Session expirée. Déconnectez-vous puis reconnectez-vous.',
      'user_not_found' => 'Compte introuvable. Reconnectez-vous.',
      'user_banned' => 'Ce compte a été désactivé.',
      'email_not_confirmed' => 'Adresse e-mail non confirmée.',
      _ => e.message.isEmpty ? 'Erreur d\'authentification.' : e.message,
    };
    return code.isEmpty ? message : '$message (code : $code)';
  }

  /// Message français pour une erreur de base de données.
  static String describePostgrestError(PostgrestException e) {
    switch (e.code) {
      case '23505':
        return 'Ce pseudo est déjà utilisé.';
      case '42501':
        return 'Droits insuffisants sur la table admin_settings : exécutez '
            'le script 02_admin.sql dans Supabase (SQL Editor), puis '
            'réessayez. (code : 42501)';
      case 'PGRST301':
      case 'PGRST303':
        return 'Session expirée. Déconnectez-vous puis reconnectez-vous. '
            '(code : ${e.code})';
      default:
        final code = (e.code ?? '').isEmpty ? '' : ' (code : ${e.code})';
        return '${e.message}$code';
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // CONNEXION
  // ─────────────────────────────────────────────────────────────────────

  /// Connexion par pseudo (via Edge Function) ou par e-mail direct.
  /// L'e-mail réel n'est jamais renvoyé au client.
  ///
  /// Codes d'erreur ([AuthException.code]) possibles :
  ///  • `invalid_credentials`  : identifiants refusés
  ///  • `over_request_rate_limit` : trop de tentatives
  ///  • `function_missing`     : la fonction `admin-login` n'est pas déployée
  ///  • `service_unavailable`  : la fonction plante ou est injoignable
  ///  • `not_admin`            : compte valide mais absent de la table `admins`
  Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    final input = identifier.trim();
    if (input.isEmpty || password.isEmpty) {
      throw const AuthException('Identifiants incorrects.',
          code: 'invalid_credentials');
    }

    if (input.contains('@')) {
      await _db.auth
          .signInWithPassword(email: input.toLowerCase(), password: password);
    } else {
      await _signInWithPseudo(input, password);
    }

    await _ensureAdmin();
  }

  Future<void> _signInWithPseudo(String pseudo, String password) async {
    try {
      final res = await _db.functions.invoke(
        'admin-login',
        body: {'pseudo': pseudo.toLowerCase(), 'password': password},
      );
      final data = res.data;
      final refresh = data is Map ? data['refresh_token'] as String? : null;
      if (refresh == null || refresh.isEmpty) {
        throw const AuthException('Identifiants incorrects.',
            code: 'invalid_credentials');
      }
      await _db.auth.setSession(refresh);
    } on AuthException {
      rethrow;
    } on FunctionException catch (e) {
      debugPrint('AdminCredentialsService.signIn[admin-login] : '
          'HTTP ${e.status} — ${e.details}');
      throw _mapFunctionError(e);
    } catch (e) {
      // Réseau coupé, CORS, domaine non autorisé…
      debugPrint('AdminCredentialsService.signIn[admin-login] : $e');
      throw const AuthException(
        'Service de connexion injoignable.',
        code: 'service_unavailable',
        statusCode: 'network',
      );
    }
  }

  /// Traduit la réponse HTTP de la fonction `admin-login`.
  /// 400 / 401 / 403 : identifiants refusés ; 429 : trop de tentatives ;
  /// 404 « fonction introuvable » : non déployée ; autre 404 : pseudo inconnu ;
  /// tout autre statut (5xx…) : la fonction est en panne.
  AuthException _mapFunctionError(FunctionException e) {
    final status = e.status;
    final details = '${e.details}'.toLowerCase();

    if (status == 400 || status == 401 || status == 403) {
      return const AuthException('Identifiants incorrects.',
          code: 'invalid_credentials');
    }
    if (status == 429) {
      return const AuthException('Trop de tentatives.',
          code: 'over_request_rate_limit');
    }
    if (status == 404) {
      final notDeployed =
          details.contains('function') && details.contains('not found');
      if (notDeployed) {
        return const AuthException(
          'La fonction de connexion par pseudo n\'est pas déployée.',
          code: 'function_missing',
          statusCode: '404',
        );
      }
      // La fonction répond « pseudo introuvable ».
      return const AuthException('Identifiants incorrects.',
          code: 'invalid_credentials');
    }
    return AuthException(
      'Service de connexion indisponible.',
      code: 'service_unavailable',
      statusCode: '$status',
    );
  }

  /// Vérifie que le compte connecté figure dans la table `admins`.
  ///
  /// Un compte peut exister dans Authentication sans être administrateur :
  /// la connexion réussit mais l'accès à l'espace admin est refusé. On le
  /// signale ici clairement. Si la table ne peut pas être lue (colonne
  /// différente, droits…), on ne bloque pas : [AdminGate] tranche.
  Future<void> _ensureAdmin() async {
    final user = _db.auth.currentUser;
    if (user == null) return;

    var checked = false;
    for (final column in const ['id', 'user_id']) {
      try {
        final row = await _db
            .from('admins')
            .select(column)
            .eq(column, user.id)
            .maybeSingle();
        checked = true;
        if (row != null) return; // administrateur confirmé
      } on PostgrestException catch (e) {
        debugPrint('AdminCredentialsService._ensureAdmin[$column] : $e');
      }
    }

    if (checked) {
      await _db.auth.signOut();
      throw const AuthException(
        'Ce compte n\'est pas enregistré comme administrateur.',
        code: 'not_admin',
      );
    }
  }

  Future<void> sendPasswordReset(String email, String redirectTo) =>
      _db.auth.resetPasswordForEmail(email.trim(), redirectTo: redirectTo);

  /// Envoie le code de confirmation (« nonce ») pour changer le mot de passe.
  Future<void> sendReauthenticationCode() => _db.auth.reauthenticate();

  /// Change le mot de passe en validant le code reçu.
  Future<void> updatePasswordWithCode({
    required String newPassword,
    required String code,
  }) async {
    await _db.auth.updateUser(
      UserAttributes(password: newPassword, nonce: code.trim()),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // PSEUDO
  // ─────────────────────────────────────────────────────────────────────

  /// Lit le pseudo de l'administrateur connecté (null s'il n'est pas encore
  /// enregistré). Contrairement à [getCurrentPseudo], un refus de droits ou
  /// une panne est signalé par une [AdminCredentialsException] lisible.
  Future<String?> loadPseudo() async {
    final user = _db.auth.currentUser;
    if (user == null) {
      throw const AdminCredentialsException('Aucun administrateur connecté.');
    }
    try {
      final row = await _db
          .from(_table)
          .select('pseudo')
          .eq('id', user.id)
          .maybeSingle();
      return row?['pseudo'] as String?;
    } on PostgrestException catch (e) {
      debugPrint('AdminCredentialsService.loadPseudo : $e');
      throw AdminCredentialsException(
        'Lecture du pseudo impossible : ${describePostgrestError(e)}',
      );
    }
  }

  /// Version « silencieuse » conservée pour compatibilité : renvoie null en
  /// cas d'échec (l'erreur est journalisée dans la console du navigateur).
  Future<String?> getCurrentPseudo() async {
    try {
      return await loadPseudo();
    } on AdminCredentialsException catch (e) {
      debugPrint('AdminCredentialsService.getCurrentPseudo : ${e.message}');
      return null;
    }
  }

  /// Enregistre ou met à jour le pseudo de l'administrateur sur Supabase DB.
  /// L'écriture est vérifiée : si la base ne renvoie aucune ligne (écriture
  /// silencieusement refusée), une erreur explicite est levée.
  Future<void> setPseudo({required String pseudo}) async {
    final user = _db.auth.currentUser;
    if (user == null) {
      throw const AdminCredentialsException('Aucun administrateur connecté.');
    }

    final error = validatePseudo(pseudo);
    if (error != null) throw AdminCredentialsException(error);

    try {
      final saved = await _db.from(_table).upsert({
        'id': user.id,
        'pseudo': pseudo.trim().toLowerCase(),
        'email': (user.email ?? '').trim().toLowerCase(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).select('pseudo');

      if (saved.isEmpty) {
        throw const AdminCredentialsException(
          'Le pseudo n\'a pas été enregistré : la base a refusé l\'écriture '
          '(vérifiez que ce compte figure dans la table admins).',
        );
      }
    } on PostgrestException catch (e) {
      debugPrint('AdminCredentialsService.setPseudo : $e');
      throw AdminCredentialsException(describePostgrestError(e));
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // MOT DE PASSE
  // ─────────────────────────────────────────────────────────────────────

  /// Modifie le mot de passe de l'administrateur en validant le mot de passe
  /// actuel. Chaque étape produit un message précis (avec code technique).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _db.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      throw const AdminCredentialsException('Aucun administrateur connecté.');
    }
    if (currentPassword == newPassword) {
      throw const AdminCredentialsException(
        'Le nouveau mot de passe doit être différent de l\'actuel.',
      );
    }

    // 1) Vérification du mot de passe actuel (ouvre aussi une session
    //    « récente », exigée si « Secure password change » est actif).
    try {
      await _db.auth
          .signInWithPassword(email: email, password: currentPassword);
    } on AuthException catch (e) {
      debugPrint('AdminCredentialsService.changePassword[vérification] : $e');
      throw AdminCredentialsException(describeAuthError(e));
    }

    // 2) Enregistrement du nouveau mot de passe.
    try {
      await _db.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      debugPrint('AdminCredentialsService.changePassword[mise à jour] : $e');
      throw AdminCredentialsException(describeAuthError(e));
    }
  }

  /// Déconnecte la session d'administration active.
  Future<void> signOut() async {
    await _db.auth.signOut();
  }
}