import 'package:flutter/material.dart';

import 'about_content_editor_page.dart';

/// Point d'entrée de la section « À propos » côté admin.
class AdminAboutPage extends StatelessWidget {
  final bool embedded;

  const AdminAboutPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return AboutContentEditorPage(embedded: embedded);
  }
}