import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';

void main() {
  testWidgets('Unauthenticated user is redirected to LoginScreen', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: SakuKuApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the login screen header and form are displayed
    expect(find.text('SakuKu'), findsOneWidget);
    expect(find.text('Masuk ke Akun'), findsOneWidget);
    expect(find.text('Username atau Email'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Ingat username di perangkat ini'), findsOneWidget);
  });
}
