import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/aziz_colors.dart';
import 'admin_hub_page.dart';
import 'admin_login_page.dart';

/// Point d'entrée de la route '/admin'.
///
/// Règles de sécurité :
///  1. Une session restaurée depuis le stockage du navigateur au
///     chargement de la page n'est JAMAIS acceptée : elle est purgée et
///     l'utilisateur doit saisir pseudo (ou e-mail) + mot de passe.
///  2. Une connexion faite pendant la page courante reste valable jusqu'à
///     la déconnexion ou le rechargement de la page.
///  3. L'utilisateur doit exister dans `public.admins` (colonne `id` ou
///     `user_id`), sinon la session est fermée et un message « Accès
///     refusé » est affiché.
///  4. Une erreur réseau ou de configuration pendant la vérification n'est
///     PAS un refus : un écran « Réessayer » est affiché, avec le détail
///     technique, sans fermer la session.
///
/// ⚠️ Cette porte est un confort d'interface : la vraie protection des
/// données reste la RLS Supabase et le contrôle admin de `r2-presign`.
class AdminGate extends StatefulWidget {
  const AdminGate({super.key});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

enum _AdminCheck { admin, denied, failed }

class _AdminGateState extends State<AdminGate> {
  /// Vrai uniquement après une connexion saisie dans la page courante.
  /// Remis à zéro par un rechargement de la page.
  static bool _signedInThisLaunch = false;

  /// Colonnes de `public.admins` pouvant contenir l'identifiant du compte.
  static const List<String> _adminIdColumns = ['id', 'user_id'];

  final GoTrueClient _auth = Supabase.instance.client.auth;
  StreamSubscription<AuthState>? _sub;

  bool _ready = false;
  bool _accessDenied = false;
  bool _signingOut = false;
  Future<_AdminCheck>? _adminCheck;
  String? _checkedUserId;

  /// Détail technique de la dernière vérification échouée (affiché à l'écran).
  String? _failureDetail;

  @override
  void initState() {
    super.initState();
    _sub = _auth.onAuthStateChange.listen(_onAuthChange);
    _purgeStaleSession();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onAuthChange(AuthState state) {
    if (!mounted) return;
    // Après la purge, plus aucune session restaurée n'existe en stockage :
    // une session apparue ensuite vient d'une vraie saisie d'identifiants.
    // La connexion par pseudo passe par `setSession`, qui peut émettre
    // `tokenRefreshed` au lieu de `signedIn` : les deux sont acceptés.
    final isSignInEvent = state.event == AuthChangeEvent.signedIn ||
        state.event == AuthChangeEvent.tokenRefreshed;
    if (_ready && isSignInEvent && state.session != null) {
      _signedInThisLaunch = true;
    }
    if (state.event == AuthChangeEvent.signedOut) {
      _signedInThisLaunch = false;
      _adminCheck = null;
      _checkedUserId = null;
    }
    setState(() {});
  }

  Future<void> _purgeStaleSession() async {
    if (!_signedInThisLaunch && _auth.currentSession != null) {
      try {
        await _auth.signOut();
      } catch (e) {
        debugPrint('[AdminGate] purge de session impossible : $e');
      }
    }
    if (mounted) setState(() => _ready = true);
  }

  /// Vérifie que [userId] figure dans `public.admins`.
  ///
  /// Essaie chaque colonne de [_adminIdColumns] (selon le schéma, l'identifiant
  /// s'appelle `id` ou `user_id`) :
  ///  • ligne trouvée                      → admin
  ///  • requête réussie mais aucune ligne  → refusé
  ///  • 42501 (RLS refuse l'accès)         → refusé
  ///  • autre erreur sur toutes les colonnes (réseau, colonne absente…)
  ///                                       → échec, détail dans [_failureDetail]
  Future<_AdminCheck> _checkAdmin(String userId) async {
    var answered = false;
    var forbidden = false;
    String? detail;

    for (final column in _adminIdColumns) {
      try {
        final row = await Supabase.instance.client
            .from('admins')
            .select(column)
            .eq(column, userId)
            .maybeSingle();
        answered = true;
        if (row != null) return _AdminCheck.admin;
      } on PostgrestException catch (e) {
        debugPrint(
            '[AdminGate] vérification admin sur « $column » (${e.code}) : $e');
        if (e.code == '42501') forbidden = true;
        detail = '${e.message} (code : ${e.code ?? 'inconnu'}, colonne : $column)';
      } catch (e) {
        debugPrint('[AdminGate] vérification admin impossible : $e');
        _failureDetail = '$e';
        return _AdminCheck.failed;
      }
    }

    if (answered || forbidden) return _AdminCheck.denied;
    _failureDetail = detail;
    return _AdminCheck.failed;
  }

  void _retryCheck() {
    setState(() {
      _failureDetail = null;
      _checkedUserId = null;
      _adminCheck = null;
    });
  }

  /// Ferme la session d'un compte qui n'est pas administrateur.
  void _denyAccess() {
    if (_signingOut) return;
    _signingOut = true;
    _accessDenied = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _auth.signOut();
      } catch (e) {
        debugPrint('[AdminGate] fermeture de session impossible : $e');
      }
      _signedInThisLaunch = false;
      _adminCheck = null;
      _checkedUserId = null;
      _signingOut = false;
      if (mounted) setState(() {});
    });
  }

  Widget _loader() => const Scaffold(
        backgroundColor: AzizColors.backgroundDark,
        body: Center(
          child: CircularProgressIndicator(color: AzizColors.saffron),
        ),
      );

  Widget _errorView() => Scaffold(
        backgroundColor: AzizColors.backgroundDark,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 40, color: AzizColors.saffron),
                  const SizedBox(height: 16),
                  const Text(
                    'Vérification impossible.\nContrôlez votre connexion puis réessayez.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AzizColors.textSecondary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  if (_failureDetail != null) ...[
                    const SizedBox(height: 12),
                    SelectableText(
                      _failureDetail!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AzizColors.textMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _retryCheck,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AzizColors.saffron,
                      foregroundColor: AzizColors.textOnAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _denyAccessSilently,
                    child: const Text(
                      'Se déconnecter',
                      style: TextStyle(color: AzizColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  /// Déconnexion volontaire depuis l'écran d'erreur (sans message « refusé »).
  Future<void> _denyAccessSilently() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('[AdminGate] déconnexion impossible : $e');
    }
    _signedInThisLaunch = false;
    _failureDetail = null;
    _adminCheck = null;
    _checkedUserId = null;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return _loader();

    final session = _auth.currentSession;
    if (session == null || !_signedInThisLaunch) {
      return AdminLoginPage(
        notice: _accessDenied
            ? 'Accès refusé : ce compte n\'est pas enregistré comme '
                'administrateur (table « admins »).'
            : null,
      );
    }

    final userId = session.user.id;
    if (_checkedUserId != userId || _adminCheck == null) {
      _checkedUserId = userId;
      _failureDetail = null;
      _adminCheck = _checkAdmin(userId);
    }

    return FutureBuilder<_AdminCheck>(
      future: _adminCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _loader();
        }
        switch (snapshot.data ?? _AdminCheck.failed) {
          case _AdminCheck.admin:
            return const AdminHubPage();
          case _AdminCheck.failed:
            return _errorView();
          case _AdminCheck.denied:
            _denyAccess();
            return _loader();
        }
      },
    );
  }
}