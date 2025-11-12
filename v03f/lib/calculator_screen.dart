// lib/calculator_screen.dart
import 'package:flutter/material.dart';
import 'ui/display_widget.dart';
import 'ui/button_grid.dart';
import 'logic/calculator_engine.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key, this.onToggleTheme});
  final VoidCallback? onToggleTheme;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late final CalculatorEngine engine;

  @override
  void initState() {
    super.initState();
    engine = CalculatorEngine();
  }

  void _onButtonPressed(String value) {
    setState(() => engine.input(value));
  }

  @override
  Widget build(BuildContext context) {
    const labels = [
      '7','8','9','/',
      '4','5','6','*',
      '1','2','3','-',
      'C','0','=','+',
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Miniräknare'),
        actions: [
          IconButton(
            tooltip: isDark ? 'Byt till ljust tema' : 'Byt till mörkt tema',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Column(
        children: [
          // Display
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Align(
                alignment: Alignment.bottomRight,
                child: DisplayWidget(
                  key: const Key('display'),
                  text: engine.display,                 // <-- ändrat från value:
                ),
              ),
            ),
          ),
          // Grid med knappar
          Expanded(
            flex: 2,
            child: ButtonGrid(
              labels: labels,
              onTap: _onButtonPressed,                  // <-- inga extra named params
            ),
          ),
        ],
      ),
    );
  }
}