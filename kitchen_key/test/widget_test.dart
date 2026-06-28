// Smoke test: verifies the app boots to the branded splash screen.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kitchen_key/main.dart';

void main() {
  testWidgets('App boots and shows the brand name on splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: KitchenKeyApp()));
    await tester.pump();

    // Brand name is present on the splash screen (even before fade-in completes).
    expect(find.text('Kitchen Key'), findsOneWidget);

    // Advance past the splash auto-redirect timer so no timers stay pending.
    await tester.pump(const Duration(seconds: 3));
  });
}
