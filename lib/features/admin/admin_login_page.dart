import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config.dart';
import '../../theme/aziz_colors.dart';
import '../../widgets/optimized_image.dart';
import 'admin_credentials_service.dart';

/// Connexion par PSEUDO : le pseudo est échangé contre une session par la
/// fonction Edge `admin-login` (AdminCredentialsService.signIn) ; l'e-mail
/// réel n'est jamais renvoyé au client.
/// Si le texte saisi contient un "@", la connexion directe par e-mail reste
/// possible (repli automatique) pour ne JAMAIS vous bloquer hors de votre
/// propre panneau d'administration.
class AdminLoginPage extends StatefulWidget {
  /// Message affiché dès l'ouverture (ex. « Accès refusé »).
  final String? notice;

  const AdminLoginPage({super.key, this.notice});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pseudoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _credentialsService = AdminCredentialsService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  /// Logo de l'espace admin, hébergé sur Cloudflare R2 (`logo/logo0.png`).
  final String _logoUrl = AppConfig.logoAdminUrl;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _errorMessage = widget.notice;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pseudoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Affiche le dialogue de réinitialisation du mot de passe.
  Future<void> _showForgotPasswordDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ForgotPasswordDialog(service: _credentialsService),
    );
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _credentialsService.signIn(
        identifier: _pseudoController.text,
        password: _passwordController.text,
      );
      // Connexion réussie : AdminGate prend le relais.
      TextInput.finishAutofillContext();
    } on AuthException catch (e) {
      if (!mounted) return;
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
          'service_unavailable' =>
            'Service de connexion indisponible. Réessayez dans un instant.',
          _ => 'Erreur de connexion. Veuillez réessayer.',
        };
      });
    } catch (_) {
      if (!mounted) return;
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
      child: AutofillGroup(
        child: Scaffold(
          backgroundColor: AzizColors.backgroundDark,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AzizColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo AZIZART affiché au sommet
                            Center(
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.35),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: OptimizedImage(
                                    url: _logoUrl,
                                    folder: 'logo',
                                    fit: BoxFit.contain,
                                    placeholder: const Center(
                                      child: SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  AzizColors.saffron),
                                        ),
                                      ),
                                    ),
                                    errorWidget: Container(
                                      color: AzizColors.backgroundMedium,
                                      child: const Center(
                                        child: Text(
                                          'AZ',
                                          style: TextStyle(
                                            fontFamily: 'Playfair Display',
                                            color: AzizColors.saffron,
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Titre
                            const Text(
                              'Espace Admin',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Playfair Display',
                                color: AzizColors.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Sous-titre
                            const Text(
                              'Connectez-vous pour gérer le contenu du site AZIZART',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AzizColors.textSecondary,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Champ pseudo
                            TextFormField(
                              controller: _pseudoController,
                              style: const TextStyle(
                                color: AzizColors.textPrimary,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Pseudo',
                                labelStyle: const TextStyle(
                                    color: AzizColors.textSecondary),
                                prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
                                    color: AzizColors.saffron),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AzizColors.divider),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AzizColors.divider),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AzizColors.saffron, width: 2),
                                ),
                                filled: true,
                                fillColor: AzizColors.background,
                              ),
                              keyboardType: TextInputType.text,
                              autocorrect: false,
                              enableSuggestions: false,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Veuillez entrer votre pseudo';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Champ mot de passe
                            TextFormField(
                              controller: _passwordController,
                              style: const TextStyle(
                                color: AzizColors.textPrimary,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                labelStyle: const TextStyle(
                                    color: AzizColors.textSecondary),
                                prefixIcon: const Icon(Icons.lock_outline,
                                    color: AzizColors.saffron),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AzizColors.textSecondary,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword =
                                        !_obscurePassword,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AzizColors.divider),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AzizColors.divider),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AzizColors.saffron, width: 2),
                                ),
                                filled: true,
                                fillColor: AzizColors.background,
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

                            // Message d'erreur
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AzizColors.error
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AzizColors.error
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: AzizColors.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: AzizColors.error,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 32),

                            // Bouton de connexion
                            Container(
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: AzizColors.terracottaGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AzizColors.terraCotta
                                        .withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  AzizColors.textPrimary),
                                        ),
                                      )
                                    : const Text(
                                        'Se connecter',
                                        style: TextStyle(
                                          color: AzizColors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),

                            // Lien mot de passe oublié
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () =>
                                  _showForgotPasswordDialog(context),
                              child: const Text(
                                'Mot de passe oublié ?',
                                style: TextStyle(
                                  color: AzizColors.saffron,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Bouton retour
                            TextButton.icon(
                              onPressed: () => Navigator.of(context)
                                  .pushNamedAndRemoveUntil('/', (r) => false),
                              icon: const Icon(Icons.arrow_back, size: 18),
                              label: const Text(
                                'Retour au site',
                                style: TextStyle(fontSize: 14),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AzizColors.textSecondary,
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
          ),
        ),
      ),
    );
  }
}

/// Dialogue « Mot de passe oublié » : possède son propre contrôleur (libéré
/// avec le dialogue) et n'est pas fermable pendant l'envoi.
class _ForgotPasswordDialog extends StatefulWidget {
  final AdminCredentialsService service;

  const _ForgotPasswordDialog({required this.service});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSending = false;
  bool _success = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Adresse de retour du lien : celle d'où la demande est faite. Le jeton
  /// (PKCE) est stocké dans CE navigateur, donc le lien doit y revenir.
  /// Repli sur [AppConfig.baseUrl] hors navigateur.
  String _resetRedirectUrl() {
    final base = Uri.base;
    final origin = (base.scheme == 'http' || base.scheme == 'https')
        ? base.origin
        : AppConfig.baseUrl;
    return '$origin/admin/reset-password';
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
      _message = null;
    });

    try {
      await widget.service.sendPasswordReset(
        _emailController.text,
        _resetRedirectUrl(),
      );
      if (!mounted) return;
      setState(() {
        _success = true;
        _message =
            'Si un compte existe avec cet e-mail, vous recevrez un lien de réinitialisation.';
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _success = false;
        _message = e.code == 'over_email_send_rate_limit' ||
                e.code == 'over_request_rate_limit' ||
                e.statusCode == '429'
            ? 'Trop de demandes. Patientez une minute puis réessayez.'
            : 'Envoi impossible. Vérifiez l\'adresse et réessayez.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _success = false;
        _message = 'Connexion impossible. Vérifiez votre réseau.';
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AzizColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Réinitialiser le mot de passe',
        style: TextStyle(
          fontFamily: 'Playfair Display',
          color: AzizColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Entrez votre adresse e-mail pour recevoir un lien de réinitialisation.',
              style: TextStyle(color: AzizColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              enabled: !_isSending,
              decoration: InputDecoration(
                labelText: 'E-mail',
                prefixIcon: const Icon(Icons.email_outlined,
                    color: AzizColors.saffron),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer votre e-mail';
                }
                if (!value.contains('@')) return 'E-mail invalide';
                return null;
              },
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_success ? AzizColors.success : AzizColors.error)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _success ? AzizColors.success : AzizColors.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.pop(context),
          child: Text(_success ? 'Fermer' : 'Annuler'),
        ),
        ElevatedButton(
          onPressed: _isSending ? null : _send,
          style: ElevatedButton.styleFrom(
            backgroundColor: AzizColors.saffron,
            foregroundColor: AzizColors.textOnAccent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Envoyer'),
        ),
      ],
    );
  }
}