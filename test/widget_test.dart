import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:azizart/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // AppDataProvider (créé en interne par AzizArtApp) instancie
    // GalleryService / AtelierService / MediaService dès sa construction,
    // et ces services lisent Supabase.instance.client. Sans initialisation
    // préalable, ça lève une exception avant même le premier pump.
    // 127.0.0.1 (loopback, rien n'écoute dessus) fait échouer les appels
    // réseau quasi instantanément et de façon déterministe, au lieu de
    // dépendre du DNS/timeout d'un vrai domaine. EmptyLocalStorage évite
    // toute dépendance à un stockage natif indisponible en test.
    await Supabase.initialize(
      url: 'http://127.0.0.1:54321',
      publishableKey: 'test-publishable-key',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
      ),
    );
  });

  testWidgets('AzizArtApp smoke test', (WidgetTester tester) async {
    // runAsync() bascule cette portion sur la vraie boucle d'événements :
    // indispensable ici, car AppDataProvider déclenche de vrais appels
    // réseau (Supabase) dès sa construction, et tester.pump() seul ne fait
    // avancer que l'horloge simulée (Timer), jamais une I/O réelle. Sans
    // ça, ces appels restent "en vol" et peuvent appeler notifyListeners()
    // après la destruction du provider plus bas.
    await tester.runAsync(() async {
      await tester.pumpWidget(const AzizArtApp());
      await tester.pump();

      // Laisse le temps à l'échec réseau (attendu, géré par les try/catch
      // internes de AppDataProvider) de réellement se produire.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await tester.pump();
    });

    // AzizArtApp fournit déjà son propre MultiProvider (AppDataProvider +
    // LanguageProvider) en interne — inutile de l'envelopper dans un
    // provider externe.
    expect(find.byType(AzizArtApp), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Démonte l'arbre maintenant que les appels réseau ont eu le temps de
    // se résoudre : AppDataProvider.dispose() annule ses Timer.periodic
    // sans risquer un notifyListeners() après dispose().
    await tester.pumpWidget(const SizedBox.shrink());
  });
}