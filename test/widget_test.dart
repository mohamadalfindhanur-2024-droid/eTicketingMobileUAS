import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasimobileuts/main.dart';

void main() {
  testWidgets('Splash Screen displays App Title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HelpdeskApp());

    // Verify that the splash screen text exists
    expect(find.text('E-Ticketing'), findsOneWidget);
    expect(find.text('Helpdesk Mobile App'), findsOneWidget);

    // Wait for the splash screen timer to finish to prevent pending timer failures
    await tester.pump(const Duration(milliseconds: 3000));
  });
}
