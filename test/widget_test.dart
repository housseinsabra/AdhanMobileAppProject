import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adhan/main.dart'; // Ensure 'adhan' matches your pubspec.yaml name

void main() {
  testWidgets('App loads with Islamic design and shows loading state', (WidgetTester tester) async {
    // 1. Build our app and trigger a frame.
    await tester.pumpWidget(const AdhanApp());

    // 2. Verify the AppBar Title matches the NEW design
    // The title was changed from 'Adhan Prayer Times' to just 'Prayer Times'
    expect(find.text('Prayer Times'), findsOneWidget);

    // 3. Verify the Islamic Header (Ayah) is present
    // This confirms your new beautiful header is rendering correctly
    expect(find.text('Surah An-Nisa 4:103'), findsOneWidget);

    // 4. Verify the Loading Indicator is visible
    // Since the app starts fetching data immediately, this should be on screen.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // NOTE: We do not use 'await tester.pumpAndSettle();' here.
    // Since we haven't set up a "Mock" for the HTTP client, a real network call
    // cannot complete in this basic test environment.
    // This test successfully proves the UI launches and the design elements are present.
  });
}