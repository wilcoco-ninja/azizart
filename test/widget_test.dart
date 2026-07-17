import 'package:flutter_test/flutter_test.dart';
import 'package:azizart/app.dart';
import 'package:provider/provider.dart';
import 'package:azizart/features/l10n/locale_service.dart';

void main() {
  testWidgets('AzizArtApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LocaleService(),
        child: const AzizArtApp(),
      ),
    );
    // Vérifier que l'app démarre sans exception
    expect(find.byType(AzizArtApp), findsOneWidget);
  });
}
