import 'package:flutter/material.dart';
import 'calc_button.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String display = '0';
  double? firstOperand;
  String? operator;
  bool shouldReset = false;

  void onButtonPressed(String value) {
    setState(() {
      if ('0123456789'.contains(value)) {
        if (shouldReset || display == '0') {
          display = value;
          shouldReset = false;
        } else {
          display += value;
        }
        return;
      }
      if ('+-*/'.contains(value)) {
        firstOperand = double.tryParse(display);
        operator = value;
        shouldReset = true;
        return;
      }
      if (value == '=') {
        final second = double.tryParse(display);
        if (firstOperand != null && operator != null && second != null) {
          switch (operator) {
            case '+':
              display = (firstOperand! + second).toString();
              break;
            case '-':
              display = (firstOperand! - second).toString();
              break;
            case '*':
              display = (firstOperand! * second).toString();
              break;
            case '/':
              display = (second == 0) ? 'Error' : (firstOperand! / second).toString();
              break;
          }
          firstOperand = null;
          operator = null;
          shouldReset = true;
        }
        return;
      }
      if (value == 'C') {
        display = '0';
        firstOperand = null;
        operator = null;
        shouldReset = false;
        return;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final labels = [
      '7', '8', '9', '/',
      '4', '5', '6', '*',
      '1', '2', '3', '-',
      'C', '0', '=', '+',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Miniräknare')),
      body: Column(
        children: [
          // Display
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(24),
              child: Text(
                display,
                key: const Key('display'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Grid med knappar
          Expanded(
            flex: 2,
            child: GridView.count(
              crossAxisCount: 4,
              padding: const EdgeInsets.all(8),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (final label in labels)
                  CalcButton(
                    buttonKey: Key('btn-$label'),     // <-- ändrat (tidigare: key:)
                    label: label,
                    onTap: () => onButtonPressed(label),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}