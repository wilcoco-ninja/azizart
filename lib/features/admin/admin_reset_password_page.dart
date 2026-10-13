import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/admin_colors.dart';
import '../../theme/admin_design.dart';

class AdminResetPasswordPage extends StatefulWidget {
  const AdminResetPasswordPage({super.key});

  @override
  State<AdminResetPasswordPage> createState() => _AdminResetPasswordPageState();
}

class _AdminResetPasswordPageState extends State<AdminResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  /// Vrai dès qu'une session de récupération existe (lien valide).
  bool _hasSession = false;

  /// Court délai de grâce : le code du lien est échangé contre une session
  /// juste après le démarrage, avant de conclure que le lien est invalide.
  bool _checking = true;

  StreamSubscription<AuthState>? _authSub;
  Timer? _graceTimer;

  static const String _expiredLinkMessage =
      'Le lien de réinitialisation est expiré ou invalide. '
      'Demandez-en un nouveau depuis la page de connexion.';

  @override
  void initState() {
    super.initState();
    final auth = Supabase.instance.client.auth;
    _hasSession = auth.currentSession != null;
    _checking = !_hasSession;

    _authSub = auth.onAuthStateChange.listen((state) {
      if (!mounted) return;
      setState(() {
        _hasSession = state.session != null;
        if (_hasSession) _checking = false;
      });
    });

    if (_checking) {
      _graceTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => _checking = false);
      });
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _graceTimer?.cancel();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  /// Message lisible (en français) pour une erreur d'authentification.
  String _messageFor(AuthException e) {
    switch (e.code) {
      case 'same_password':
        return 'Le nouveau mot de passe doit être différent de l\'ancien.';
      case 'weak_password':
        return 'Mot de passe trop faible. Utilisez au moins 8 caractères variés.';
      case 'over_request_rate_limit':
        return 'Trop de tentatives. Réessayez dans quelques minutes.';
      case 'session_not_found':
      case 'session_expired':
      case 'refresh_token_not_found':
        return _expiredLinkMessage;
      default:
        return e.message.toLowerCase().contains('session')
            ? _expiredLinkMessage
            : 'Impossible de modifier le mot de passe. Réessayez.';
    }
  }

  void _backToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/admin', (r) => false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Supabase.instance.client.auth;
    // Sans session de récupération (lien expiré ou page ouverte en direct),
    // la mise à jour ne peut pas aboutir.
    if (auth.currentSession == null) {
      setState(() => _error = _expiredLinkMessage);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await auth.updateUser(UserAttributes(password: _passCtrl.text));
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _messageFor(e);
        _loading = false;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Une erreur est survenue. Réessayez.';
        _loading = false;
      });
      return;
    }

    // Le mot de passe est changé : une déconnexion qui échoue n'est pas
    // une erreur de l'opération.
    try {
      await auth.signOut();
    } catch (e) {
      debugPrint('AdminResetPasswordPage: déconnexion impossible — $e');
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mot de passe modifié. Connectez-vous.')),
    );
    _backToLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AdminDesign.sp16),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AdminDesign.formMaxWidth),
            child: Container(
              padding: const EdgeInsets.all(AdminDesign.sp24),
              decoration: AdminDesign.card(),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Nouveau mot de passe',
                        style: TextStyle(
                          color: AdminColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!_hasSession) ...[
                        const SizedBox(height: AdminDesign.sp12),
                        Text(
                          _checking
                              ? 'Vérification du lien…'
                              : _expiredLinkMessage,
                          style: TextStyle(
                            color: _checking
                                ? AdminColors.textMuted
                                : AdminColors.danger,
                          ),
                        ),
                      ],
                      const SizedBox(height: AdminDesign.sp20),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.newPassword],
                        style: const TextStyle(color: AdminColors.text),
                        decoration: AdminDesign.input(
                          label: 'Nouveau mot de passe',
                          suffixIcon: IconButton(
                            tooltip: _obscure ? 'Afficher' : 'Masquer',
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: AdminColors.textMuted,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v == null || v.length < 8)
                            ? '8 caractères minimum'
                            : null,
                      ),
                      const SizedBox(height: AdminDesign.sp12),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.newPassword],
                        style: const TextStyle(color: AdminColors.text),
                        decoration: AdminDesign.input(
                            label: 'Confirmer le mot de passe'),
                        validator: (v) => v != _passCtrl.text
                            ? 'Les mots de passe diffèrent'
                            : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AdminDesign.sp12),
                        Text(_error!,
                            style:
                                const TextStyle(color: AdminColors.danger)),
                      ],
                      const SizedBox(height: AdminDesign.sp20),
                      ElevatedButton(
                        style: AdminDesign.primaryButton(),
                        onPressed:
                            (_loading || !_hasSession) ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Enregistrer'),
                      ),
                      const SizedBox(height: AdminDesign.sp8),
                      TextButton(
                        onPressed: _loading ? null : _backToLogin,
                        child: const Text('Retour à la connexion'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}