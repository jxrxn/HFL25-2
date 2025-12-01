import 'package:flutter_test/flutter_test.dart';
import 'package:v03f/logic/calculator_engine.dart';

/// Normalisera smala mellanrum (U+202F osv) till vanliga spaces,
/// så att testen inte är känsliga för exakt typ av mellanslag.
String normalizeSpaces(String s) {
  return s
      .replaceAll('\u202F', ' ')
      .replaceAll('\u00A0', ' ');
}

void main() {
  test('CalculatorEngine strip (remsa) bygger enkel remsa: 2 + 3', () {
    final engine = CalculatorEngine();
    engine.input('2');
    engine.input('+');
    engine.input('3');

    // Vi bryr oss om innehållet, inte exakt typ av mellanslag.
    expect(normalizeSpaces(engine.strip), '2 + 3');
  });
}