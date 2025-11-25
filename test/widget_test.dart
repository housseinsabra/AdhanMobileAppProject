import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:adhan/main.dart'; // Import your main file

void main() {
  testWidgets('PrayerTimesScreen loads and shows loading indicator initially', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // FIX: Using the correct main widget name: AdhanApp
    await tester.pumpWidget(const AdhanApp());

    // Verify that the title appears.
    expect(find.text('Adhan Prayer Times'), findsOneWidget);

    // Since the app starts fetching data, the CircularProgressIndicator 
    // should be visible immediately after launching the widget.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Trigger a frame to allow the FutureBuilder to complete (though the actual 
    // network call won't finish in a unit test without mocking).
    await tester.pumpAndSettle();

    // After settling, the loading indicator should ideally disappear and
    // the header card should appear (testing successful data path).
    // In a real scenario, you would mock the HTTP request here.

    // We expect the city text to appear after the data is received.
    // For this simple test, we just ensure the initial launch is correct.
  });
}