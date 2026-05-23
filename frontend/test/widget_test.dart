// This is a basic Flutter widget test for FarmSaathi.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter_test/flutter_test.dart';
import 'package:farmsaathi/main.dart';

void main() {
  testWidgets('FarmSaathiApp instantiation smoke test', (WidgetTester tester) async {
    // Verify that the FarmSaathiApp widget can be instantiated
    const app = FarmSaathiApp();
    expect(app, isNotNull);
  });
}
