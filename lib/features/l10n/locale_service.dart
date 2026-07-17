import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'translations.dart';

// ══════════════════════════════════════════════════════════════════════════════
// LocaleService — ChangeNotifier qui gère la locale active
// ══════════════════════════════════════════════════════════════════════════════
class LocaleService extends ChangeNotifier {
  Locale _locale = const Locale('fr');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!T.supported.containsKey(locale.languageCode)) return;
    _locale = locale;
    T.setLocale(locale.languageCode);
    notifyListeners();
  }

  /// Accès statique via BuildContext (lecture seule, ne déclenche pas de rebuild)
  static LocaleService of(BuildContext context) =>
      Provider.of<LocaleService>(context, listen: false);

  /// Accès en écoute (déclenche un rebuild quand la locale change)
  static LocaleService watch(BuildContext context) =>
      context.watch<LocaleService>();
}

// ══════════════════════════════════════════════════════════════════════════════
// LocaleServiceProvider — Provider wrapper à placer en haut de l'arbre
// ══════════════════════════════════════════════════════════════════════════════
class LocaleServiceProvider extends StatelessWidget {
  final Widget child;
  const LocaleServiceProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LocaleService>(
      create: (_) => LocaleService(),
      child: child,
    );
  }
}
