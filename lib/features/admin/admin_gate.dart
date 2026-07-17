import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/aziz_colors.dart';
import 'admin_login_page.dart';
import 'admin_hub_page.dart';

/// Point d'entrée de la route '/admin'.
/// Affiche AdminLoginPage si l'utilisateur n'est pas connecté,
/// sinon affiche directement AdminHubPage.
///
/// FIX : Supabase Auth au lieu de Firebase Auth. `onAuthStateChange`
/// émet un premier événement dès l'ouverture (session restaurée depuis
/// le stockage local, ou `null` si aucune) — donc le même schéma
/// StreamBuilder qu'avant fonctionne à l'identique.
class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Scaffold(
            backgroundColor: AzizColors.backgroundDark,
            body: Center(
              child: CircularProgressIndicator(color: AzizColors.saffron),
            ),
          );
        }

        final session = snapshot.data?.session;
        if (session == null) {
          return const AdminLoginPage();
        }

        return const AdminHubPage();
      },
    );
  }
}
