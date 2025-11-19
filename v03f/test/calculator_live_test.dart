import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v03f/main.dart';
import 'package:v03f/calc_button.dart';

Future<void> _tap(WidgetTester tester, String label) async {
  final f = find.widgetWithText(CalcButton, label);
  expect(f, findsOneWidget, reason: 'Hittar inte knappen "$label"');
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _longPress(WidgetTester tester, String label) async {
  final f = find.widgetWithText(CalcButton, label);
  expect(
    f,
    findsOneWidget,
    reason: 'Hittar inte knappen "$label" (för long press)',
  );
  await tester.longPress(f);
  await tester.pumpAndSettle();
}

Finder _display() => find.byKey(const Key('display'));

Future<void> _pumpCalculator(WidgetTester tester) async {
  // Sätt en "telefonlik" storlek som funkar med vårt layoutbygge
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(const CalculatorApp());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Live-beräkning med operatorprioritet (33 + 2 × 6 = 45)',
    (tester) async {
      await _pumpCalculator(tester);

      await _tap(tester, '3');
      await _tap(tester, '3');
      await _tap(tester, '+');
      await _tap(tester, '2');
      await _tap(tester, '×');
      await _tap(tester, '6');

      expect(
        find.descendant(of: _display(), matching: find.text('45')),
        findsOneWidget,
      );

      expect(find.textContaining('33 + 2 × 6'), findsOneWidget);
    },
  );

  testWidgets('Procentlogik: 12 ÷ 10 % ⇒ 120', (tester) async {
    await _pumpCalculator(tester);

    await _tap(tester, '1');
    await _tap(tester, '2');
    await _tap(tester, '÷');
    await _tap(tester, '1');
    await _tap(tester, '0');
    await _tap(tester, '%');

    expect(
      find.descendant(of: _display(), matching: find.text('120')),
      findsOneWidget,
    );
  });

  testWidgets('Backspace och AC (långtryck på C)', (tester) async {
    await _pumpCalculator(tester);

    await _tap(tester, '7');
    await _tap(tester, '8');
    expect(
      find.descendant(of: _display(), matching: find.text('78')),
      findsOneWidget,
    );

    // C = backspace
    await _tap(tester, 'C');
    expect(
      find.descendant(of: _display(), matching: find.text('7')),
      findsOneWidget,
    );

    // Långtryck på C = AC
    await _longPress(tester, 'C');
    expect(
      find.descendant(of: _display(), matching: find.text('0')),
      findsOneWidget,
    );
  });

  testWidgets('Decimal med kommatecken: 1 , 5 × 2 ⇒ 3', (tester) async {
    await _pumpCalculator(tester);

    await _tap(tester, '1');
    await _tap(tester, ',');
    await _tap(tester, '5');
    await _tap(tester, '×');
    await _tap(tester, '2');

    expect(
      find.descendant(of: _display(), matching: find.text('3')),
      findsOneWidget,
    );
  });

  testWidgets('Delning med noll ger Error (live)', (tester) async {
    await _pumpCalculator(tester);

    await _tap(tester, '8');
    await _tap(tester, '÷');
    await _tap(tester, '0');
    await _tap(tester, '=');

    expect(
      find.descendant(of: _display(), matching: find.text('Error')),
      findsOneWidget,
    );
  });
}