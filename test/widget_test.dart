// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:laundryku/main.dart';

void main() {
  testWidgets('LaundryKuApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame (with firebaseReady false to test fallback screen).
    await tester.pumpWidget(const LaundryKuApp(firebaseReady: false));

    // Verify fallback error screen shows when Firebase is not connected in test
    expect(find.text('Koneksi Firebase Gagal'), findsOneWidget);
  });
}
