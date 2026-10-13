import 'package:flutter/material.dart';

import '../../theme/admin_colors.dart';
import 'about_texts_editor_page.dart';

/// Éditeur de la page « À propos » côté admin.
///
/// Point d'entrée unique utilisé par le hub et le gestionnaire de contenu.
/// [embedded] : `true` quand la page est affichée dans le shell du hub
/// (pas de barre d'application propre).
class AboutContentEditorPage extends StatelessWidget {
  final bool embedded;

  const AboutContentEditorPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    if (embedded) return const AboutTextsEditorPage();

    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AppBar(title: const Text('À propos')),
      body: const AboutTextsEditorPage(),
    );
  }
}