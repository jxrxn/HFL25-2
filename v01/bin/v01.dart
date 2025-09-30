import 'dart:io';

void main() {
  // Läs in första talet
  var a = _readNumber('Ange första talet: ');

  // Läs in andra talet
  var b = _readNumber('Ange andra talet: ');

  // Fråga efter operation
  stdout.write('Vilken operation vill du göra? (+, -, *, /): ');
  var op = stdin.readLineSync();

  // If/else-logik för olika operationer
  if (op == '+') {
    print('Resultatet är: ${a + b}');
  } else if (op == '-') {
    print('Resultatet är: ${a - b}');
  } else if (op == '*') {
    print('Resultatet är: ${a * b}');
  } else if (op == '/') {
    if (b == 0) {
      print('Fel: Division med 0 är inte tillåten.');
    } else {
      print('Resultatet är: ${a / b}');
    }
  } else {
    print('Ogiltig operation.');
  }
}

// Hjälpfunktion för att läsa in och validera siffror
int _readNumber(String prompt) {
  while (true) {
    stdout.write(prompt);
    var input = stdin.readLineSync();
    var number = int.tryParse(input ?? '');
    if (number != null) {
      return number;
    } else {
      print('Ogiltig inmatning. Försök igen.');
    }
  }
}