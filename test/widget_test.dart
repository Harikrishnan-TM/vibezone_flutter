import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vibezone_flutter/main.dart'; // Make sure this points to your actual main entry

void main() {
  testWidgets('App loads and counter increments test', (WidgetTester tester) async {
    // Build your app
    await tester.pumpWidget(const MyApp());

    // Verify the initial state (assuming a counter app structure)
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Simulate tapping the '+' button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify the state has updated
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
