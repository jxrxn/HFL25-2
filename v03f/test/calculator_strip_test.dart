// test/calculator_strip_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:v03f/logic/calculator_engine.dart';

void main() {
  group('CalculatorEngine strip (remsa)', () {
    test('startar tom', () {
      final eng = CalculatorEngine();
      expect(eng.strip, '');
    });

    test('bygger enkel remsa: 2 + 3', () {
      final eng = CalculatorEngine();
      eng.input('2');
      eng.input('+');
      eng.input('3');

      expect(eng.strip, '2 + 3');
    });

    test('procent på remsan: 50 + 10 % → "50 + 10 %"', () {
      final eng = CalculatorEngine();
      eng.input('5');
      eng.input('0');
      eng.input('+');
      eng.input('1');
      eng.input('0');
      eng.input('%');

      expect(eng.strip, '50 + 10 %');
    });

    test('procent vid division: 100 ÷ 10 % → remsa "100 ÷ 10 % = 1\u202F000"', () {
      final eng = CalculatorEngine();
      eng.input('1');
      eng.input('0');
      eng.input('0');
      eng.input('÷');
      eng.input('1');
      eng.input('0');
      eng.input('%');
      eng.input('=');

      expect(eng.strip, '100 ÷ 10 % = 1\u202F000');
    });
  });
}