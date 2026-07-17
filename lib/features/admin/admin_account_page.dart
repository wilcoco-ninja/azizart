import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/aziz_colors.dart';
import 'admin_credentials_service.dart';

/// Page "Mon compte" — permet à l'administrateur connecté de changer son
/// pseudo et/ou son mot de passe, sans jamais passer par le Dashboard
/// Supabase.
class AdminAccountPage extends StatefulWidget {
  const AdminAccountPage({super.key});

  @override
  State<AdminAccountPage> createState() => _AdminAccountPageState();
}

class _AdminAccountPageState extends State<AdminAccountPage> {
  final _service = AdminCredentialsService();

  final _pseudoFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _pseudoController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loadingPseudo = true;
  bool _savingPseudo = false;
  bool _savingPassword = false;

  String? _pseudoMessage;
  bool _pseudoSuccess = false;
  String? _passwordMessage;
  bool _passwordSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPseudo();
  }

  Future<void> _loadCurrentPseudo() async {
    final pseudo = await _service.getCurrentPseudo();
    if (!mounted) return;
    setState(() {
      if (pseudo != null) _pseudoController.text = pseudo;
      _loadingPseudo = false;
    });
  }

  @override
  void dispose() {
    _pseudoController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _savePseudo() async {
    if (!_pseudoFormKey.currentState!.validate()) return;
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null) return;

    setState(() {
      _savingPseudo = true;
      _pseudoMessage = null;
    });
    try {
      await _service.setPseudo(
          pseudo: _pseudoController.text.trim(), email: email);
      setState(() {
        _pseudoSuccess = true;
        _pseudoMessage =
            'Pseudo mis à jour. Utilisez-le dès votre prochaine connexion.';
      });
    } catch (e) {
      setState(() {
        _pseudoSuccess = false;
        _pseudoMessage = 'Erreur : $e';
      });
    } finally {
      if (mounted) setState(() => _savingPseudo = false);
    }
  }

  Future<void> _savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _savingPassword = true;
      _passwordMessage = null;
    });
    try {
      await _service.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      setState(() {
        _passwordSuccess = true;
        _passwordMessage = 'Mot de passe mis à jour avec succès.';
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
    } on AuthException catch (e) {
      setState(() {
        _passwordSuccess = false;
        _passwordMessage = switch (e.code) {
          'invalid_credentials' => 'Mot de passe actuel incorrect.',
          'weak_password' =>
            'Le nouveau mot de passe est trop faible (6 caractères minimum).',
          'same_password' =>
            'Le nouveau mot de passe doit être différent de l\'actuel.',
          'reauthentication_needed' =>
            'Reconnectez-vous puis réessayez immédiatement.',
          _ => 'Erreur : ${e.message}',
        };
      });
    } catch (e) {
      setState(() {
        _passwordSuccess = false;
        _passwordMessage = 'Erreur inattendue : $e';
      });
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  InputDecoration _decoration(String label, {IconData? icon}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
      );

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          color: AzizColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _feedback(String? message, bool success) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        message,
        style: TextStyle(
          color: success ? AzizColors.success : AzizColors.error,
          fontSize: 13,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AzizColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AzizColors.backgroundMedium,
        elevation: 0,
        title: const Text(
          'Mon compte',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            color: AzizColors.saffron,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Connecté avec : $email',
                    style: const TextStyle(
                      color: AzizColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Changer le pseudo ─────────────────────────────────
                  _sectionTitle('Pseudo de connexion'),
                  const SizedBox(height: 4),
                  const Text(
                    "C'est ce pseudo (et non l'e-mail) que vous utiliserez "
                    "pour vous connecter à /admin.",
                    style: TextStyle(
                      color: AzizColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_loadingPseudo)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator(),
                    )
                  else
                    Form(
                      key: _pseudoFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _pseudoController,
                            decoration: _decoration('Pseudo',
                                icon: Icons.person_outline_rounded),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Le pseudo ne peut pas être vide'
                                : null,
                          ),
                          _feedback(_pseudoMessage, _pseudoSuccess),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _savingPseudo ? null : _savePseudo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AzizColors.saffron,
                              foregroundColor: AzizColors.textOnAccent,
                            ),
                            child: _savingPseudo
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Enregistrer le pseudo'),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 40),
                  const Divider(color: AzizColors.cardBorder),
                  const SizedBox(height: 24),

                  // ── Changer le mot de passe ────────────────────────────
                  _sectionTitle('Mot de passe'),
                  const SizedBox(height: 12),
                  Form(
                    key: _passwordFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _currentPasswordController,
                          decoration: _decoration('Mot de passe actuel',
                              icon: Icons.lock_outline),
                          obscureText: true,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _newPasswordController,
                          decoration: _decoration('Nouveau mot de passe',
                              icon: Icons.lock_outline),
                          obscureText: true,
                          validator: (v) => (v == null || v.length < 6)
                              ? '6 caractères minimum'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: _decoration(
                              'Confirmer le nouveau mot de passe',
                              icon: Icons.lock_outline),
                          obscureText: true,
                          validator: (v) => (v != _newPasswordController.text)
                              ? 'Les mots de passe ne correspondent pas'
                              : null,
                        ),
                        _feedback(_passwordMessage, _passwordSuccess),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _savingPassword ? null : _savePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AzizColors.saffron,
                            foregroundColor: AzizColors.textOnAccent,
                          ),
                          child: _savingPassword
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Enregistrer le mot de passe'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
