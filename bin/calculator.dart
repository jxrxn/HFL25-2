import 'dart:io';

void main() {
  // Läs in första talet
  stdout.write('Ange första talet: ');
  var input1 = stdin.readLineSync();
  var a = int.parse(input1 ?? '0'); // konverterar text till int

  // Läs in andra talet
  stdout.write('Ange andra talet: ');
  var input2 = stdin.readLineSync();
  var b = int.parse(input2 ?? '0');

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