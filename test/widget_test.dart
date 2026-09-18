import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/app/app.dart';

void main() {
  testWidgets('FinTrack inicia mostrando el login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FinTrackApp()));

    await tester.pumpAndSettle();

    expect(find.text('FinTrack'), findsOneWidget);

    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
