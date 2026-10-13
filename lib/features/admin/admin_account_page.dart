import 'package:flutter/material.dart';
import 'package:azizart/theme/admin_colors.dart';
import 'admin_forms.dart';
import 'admin_credentials_service.dart';

class AdminAccountPage extends StatefulWidget {
  const AdminAccountPage({super.key});

  @override
  State<AdminAccountPage> createState() => _AdminAccountPageState();
}

class _AdminAccountPageState extends State<AdminAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _currentPwdController = TextEditingController();
  final _newPwdController = TextEditingController();
  final _credentialsService = AdminCredentialsService();
  bool _isSaving = false;

  /// Pseudo enregistré à l'ouverture : on ne réécrit le pseudo que s'il change.
  String _initialPseudo = '';

  /// Message d'avertissement si la lecture du pseudo échoue (droits, réseau).
  String? _loadError;

  /// Dernier résultat de « Mettre à jour le compte », affiché sans disparaître.
  String? _banner;
  bool _bannerIsError = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPseudo();
  }

  Future<void> _loadCurrentPseudo() async {
    try {
      final pseudo = await _credentialsService.loadPseudo();
      if (!mounted) return;
      if (pseudo != null && pseudo.isNotEmpty) {
        _initialPseudo = pseudo.trim();
        _nameController.text = pseudo;
      }
    } on AdminCredentialsException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    } catch (e) {
      if (mounted) setState(() => _loadError = 'Lecture du pseudo impossible : $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPwdController.dispose();
    _newPwdController.dispose();
    super.dispose();
  }

  /// Affiche le résultat dans un bandeau permanent (et une bulle si succès).
  void _notify(String message, {required bool isError}) {
    if (!mounted) return;
    setState(() {
      _banner = message;
      _bannerIsError = isError;
    });
    if (!isError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AdminColors.success),
      );
    }
  }

  Future<void> _handleUpdateAccount() async {
    setState(() => _banner = null);
    if (!_formKey.currentState!.validate()) return;

    final newPseudo = _nameController.text.trim();
    final currentPwd = _currentPwdController.text;
    final newPwd = _newPwdController.text;

    // Seul le NOUVEAU mot de passe déclenche un changement de mot de passe :
    // un champ « actuel » rempli automatiquement par le navigateur ne doit
    // pas empêcher la mise à jour du pseudo.
    final wantsPasswordChange = newPwd.isNotEmpty;
    final pseudoChanged =
        newPseudo.isNotEmpty && newPseudo != _initialPseudo;

    if (wantsPasswordChange && currentPwd.isEmpty) {
      _notify(
        'Renseignez le mot de passe actuel pour en choisir un nouveau.',
        isError: true,
      );
      return;
    }

    if (!wantsPasswordChange && !pseudoChanged) {
      _notify('Aucune modification à enregistrer.', isError: false);
      return;
    }

    setState(() => _isSaving = true);
    var passwordChanged = false;
    try {
      // Mot de passe d'abord : il échoue sans effet de bord si le mot de
      // passe actuel est faux, ce qui évite une mise à jour partielle.
      if (wantsPasswordChange) {
        await _credentialsService.changePassword(
          currentPassword: currentPwd,
          newPassword: newPwd,
        );
        passwordChanged = true;
      }
      if (pseudoChanged) {
        await _credentialsService.setPseudo(pseudo: newPseudo);
        _initialPseudo = newPseudo;
        if (mounted) setState(() => _loadError = null);
      }
      _currentPwdController.clear();
      _newPwdController.clear();

      _notify(
        passwordChanged && pseudoChanged
            ? 'Mot de passe et pseudo mis à jour.'
            : passwordChanged
                ? 'Mot de passe mis à jour.'
                : 'Pseudo mis à jour : utilisez-le à la prochaine connexion.',
        isError: false,
      );
    } on AdminCredentialsException catch (e) {
      if (passwordChanged) {
        _currentPwdController.clear();
        _newPwdController.clear();
      }
      _notify(
        passwordChanged
            ? 'Mot de passe modifié, mais le pseudo n\'a pas été enregistré : ${e.message}'
            : e.message,
        isError: true,
      );
    } catch (e) {
      if (passwordChanged) {
        _currentPwdController.clear();
        _newPwdController.clear();
      }
      _notify('Erreur inattendue : $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AppBar(
        title: const Text(
          'Paramètres du Compte',
          style: TextStyle(color: AdminColors.text),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AdminColors.text),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AdminColors.surface,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: AdminColors.text,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_loadError != null) ...[
                    AdminInfoBanner(message: _loadError!, isWarning: true),
                    const SizedBox(height: 16),
                  ],

                  adminTextField(
                    _nameController,
                    'Nom d\'administrateur',
                    helper: 'Pseudo utilisé pour se connecter.',
                    validator: (value) {
                      final t = (value ?? '').trim();
                      if (t.isEmpty) return null;
                      return AdminCredentialsService.validatePseudo(t);
                    },
                  ),
                  const SizedBox(height: 24),

                  const Divider(color: AdminColors.border),
                  const SizedBox(height: 24),

                  const Text(
                    'Sécurité',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pas de « autofillHints » ici : le navigateur ne doit pas
                  // préremplir le mot de passe actuel à l'ouverture.
                  adminTextField(
                    _currentPwdController,
                    'Mot de passe actuel',
                    isPassword: true,
                    helper: 'Nécessaire uniquement pour changer le mot de passe.',
                  ),
                  const SizedBox(height: 16),

                  adminTextField(
                    _newPwdController,
                    'Nouveau mot de passe',
                    isPassword: true,
                    helper: '8 caractères minimum.',
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (value) {
                      final v = value ?? '';
                      if (v.isEmpty) return null;
                      return v.length < 8 ? 'Au moins 8 caractères' : null;
                    },
                  ),
                  const SizedBox(height: 24),

                  if (_banner != null) ...[
                    AdminInfoBanner(
                      message: _banner!,
                      isWarning: _bannerIsError,
                    ),
                    const SizedBox(height: 16),
                  ],

                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleUpdateAccount,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AdminColors.accent,
                      foregroundColor: AdminColors.bg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AdminColors.bg,
                            ),
                          )
                        : const Text(
                            'Mettre à jour le compte',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await _credentialsService.signOut();

                        if (!context.mounted) return;

                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/',
                          (route) => false,
                        );
                      } catch (e) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur de déconnexion: $e'),
                            backgroundColor: AdminColors.danger,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.logout, color: AdminColors.danger),
                    label: const Text(
                      'Se déconnecter',
                      style: TextStyle(
                        color: AdminColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AdminColors.danger),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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