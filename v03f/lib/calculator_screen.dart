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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          // Övre panel: remsa + stort värde, full bredd
          Expanded(
            child: DisplayWidget(
              valueText: engine.display,
              stripText: engine.strip,
            ),
          ),

          // Nederdel: knapparna
          Expanded(
            flex: 2,
            child: ButtonGrid(
              onTap: (v) => setState(() => engine.input(v)),
              onLongClear: () => setState(() => engine.clearAll()),
            ),
          ),
        ],
      ),
    );
  }
}