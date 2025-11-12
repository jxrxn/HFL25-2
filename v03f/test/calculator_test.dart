// test/calculator_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v03f/main.dart';
import 'package:v03f/calc_button.dart';

// --- Hjälpare ---

Future<void> _tapKey(WidgetTester t, String k) async {
  final f = find.byKey(Key(k));
  expect(f, findsOneWidget, reason: 'Saknar knapp $k');
  await t.tap(f);
  await t.pumpAndSettle();
}

final _displayFinder = find.byKey(const Key('display'));

String _readDisplay(WidgetTester t) {
  expect(_displayFinder, findsOneWidget, reason: 'Display saknas');
  final textWidget = t.widget<Text>(_displayFinder);
  return textWidget.data ?? ''; // funkar när displayen är Text(...)
}

void main() {
  // Säkerställ att hela 4×4-griden får plats i testytan
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('UI laddas och 16 knappar finns', (tester) async {
    await tester.binding.setSurfaceSize(const Size(440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const CalculatorApp());
    await tester.pumpAndSettle();

    // Räkna CalcButton (inte ElevatedButton) för stabilitet
    expect(find.byType(CalcButton), findsNWidgets(16));

    // Displayen startar på "0"
    expect(_readDisplay(tester), '0');
  });

  testWidgets('Adderar 2 + 3 korrekt', (tester) async {
    await tester.binding.setSurfaceSize(const Size(440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const CalculatorApp());
    await tester.pumpAndSettle();

    await _tapKey(tester, 'btn-2');
    await _tapKey(tester, 'btn-+');
    await _tapKey(tester, 'btn-3');
    await _tapKey(tester, 'btn-=');

    final d = _readDisplay(tester);
    expect(d == '5' || d == '5.0', isTrue,
        reason: 'Förväntade "5" eller "5.0", fick "$d"');
  });

  testWidgets('C nollställer displayen', (tester) async {
    await tester.pumpWidget(const CalculatorApp());
    await tester.pumpAndSettle();

    await _tapKey(tester, 'btn-7');
    expect(_readDisplay(tester), '7');

    await _tapKey(tester, 'btn-C');
    expect(_readDisplay(tester), '0');
  });

  testWidgets('Division med noll ger Error', (tester) async {
    await tester.pumpWidget(const CalculatorApp());
    await tester.pumpAndSettle();

    await _tapKey(tester, 'btn-8');
    await _tapKey(tester, 'btn-/');
    await _tapKey(tester, 'btn-0');
    await _tapKey(tester, 'btn-=');

    expect(_readDisplay(tester), 'Error');
  });
}