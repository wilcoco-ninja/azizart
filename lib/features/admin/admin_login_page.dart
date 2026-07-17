import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/aziz_colors.dart';
import 'admin_credentials_service.dart';

/// Page de connexion pour accéder à l'administration.
///
/// Connexion par PSEUDO : on résout le pseudo saisi vers l'e-mail réel via
/// AdminCredentialsService, puis on appelle Supabase Auth normalement avec
/// cet e-mail. Tant qu'aucun pseudo n'a encore été configuré, ou si le
/// pseudo saisi n'est pas reconnu, la connexion directe par e-mail reste
/// possible (repli automatique) si le texte saisi contient un "@" — pour
/// ne JAMAIS vous bloquer hors de votre propre panneau d'administration.
/// Une fois connecté, allez dans "Mon compte" pour définir votre pseudo.
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _pseudoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _credentialsService = AdminCredentialsService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _pseudoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final input = _pseudoController.text.trim();

      // 1) On tente de résoudre le pseudo vers un e-mail connu.
      final resolvedEmail =
          await _credentialsService.resolveEmailForPseudo(input);

      String emailToUse;
      if (resolvedEmail != null && resolvedEmail.isNotEmpty) {
        emailToUse = resolvedEmail;
      } else if (input.contains('@')) {
        // 2) Repli : aucun pseudo configuré (ou non reconnu), mais le
        // texte saisi ressemble à un e-mail -> on tente la connexion
        // directe. Utile lors de la toute première connexion, avant
        // d'avoir défini un pseudo dans "Mon compte".
        emailToUse = input;
      } else {
        throw const AuthException('Identifiants incorrects.',
            code: 'user-not-found');
      }

      await Supabase.instance.client.auth.signInWithPassword(
        email: emailToUse,
        password: _passwordController.text,
      );
      // Pas besoin de naviguer manuellement : AdminGate écoute
      // onAuthStateChange et affichera automatiquement AdminHubPage.
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = switch (e.code) {
          'invalid_credentials' ||
          'user-not-found' ||
          'user_not_found' =>
            'Pseudo ou mot de passe incorrect.',
          'user_banned' => 'Ce compte a été désactivé.',
          'over_request_rate_limit' =>
            'Trop de tentatives. Réessayez plus tard.',
          'email_not_confirmed' =>
            'Adresse e-mail non confirmée — vérifiez votre boîte mail.',
          _ => 'Erreur de connexion. Veuillez réessayer.',
        };
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Une erreur inattendue est survenue.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AzizColors.backgroundDark,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 56,
                        color: AzizColors.saffron,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Administration',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          color: AzizColors.saffron,
                          fontSize: 24,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Connectez-vous pour gérer le contenu du site.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AzizColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Champ pseudo
                      TextFormField(
                        controller: _pseudoController,
                        decoration: const InputDecoration(
                          labelText: 'Pseudo',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer votre pseudo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Champ mot de passe
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _signIn(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre mot de passe';
                          }
                          return null;
                        },
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AzizColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AzizColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AzizColors.error,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AzizColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Bouton de connexion
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AzizColors.saffron,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AzizColors.textOnAccent,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Se connecter',
                                  style: TextStyle(
                                    color: AzizColors.textOnAccent,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: TextButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Retour au site'),
                          style: TextButton.styleFrom(
                            foregroundColor: AzizColors.textSecondary,
                          ),
                        ),
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
