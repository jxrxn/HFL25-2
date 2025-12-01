// test/calculator_live_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:v03f/calculator_screen.dart';
import 'package:v03f/calc_button.dart';

/// Startar kalkylatorn i ett enkelt MaterialApp-skal.
Future<void> pumpCalc(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: CalculatorScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Trycker på en knapp med given text, t.ex. '3', '+', '×', '='.
/// Vi letar specifikt efter CalcButton med den texten,
/// så vi inte råkar klicka på display-texten.
Future<void> tapButton(WidgetTester tester, String label) async {
  final finder = find.widgetWithText(CalcButton, label);

  expect(
    finder,
    findsOneWidget,
    reason: 'Hittar ingen CalcButton med text "$label"',
  );

  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Live-beräkning med operatorprioritet (33 + 2 × 6 = 45)',
    (tester) async {
      await pumpCalc(tester);

      // Sekvens: 33 + 2 × 6 =
      await tapButton(tester, '3');
      await tapButton(tester, '3');
      await tapButton(tester, '+');
      await tapButton(tester, '2');
      await tapButton(tester, '×');
      await tapButton(tester, '6');
      await tapButton(tester, '=');

      // Läs stora tallet – ska vara "45".
      expect(find.text('45'), findsOneWidget);
    },
  );
}