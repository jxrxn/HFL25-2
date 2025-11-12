// lib/calculator_screen.dart
import 'package:flutter/material.dart';
import 'logic/calculator_engine.dart';
import 'ui/display_widget.dart';
import 'ui/button_grid.dart';

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

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
        child: Column(
          children: [
            // Display överst (en enda)
            Expanded(
              child: DisplayWidget(
                key: const Key('display-wrapper'),
                text: engine.display,
              ),
            ),

            // Knapprutnätet (en enda)
            Expanded(
              flex: 2,
              child: ButtonGrid(
                // Kort tryck på en knapp
                onTap: (value) {
                  setState(() => engine.input(value));
                },
                // Långtryck på C = full återställning (AC)
                onLongClear: () {
                  setState(() => engine.clearAll());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}