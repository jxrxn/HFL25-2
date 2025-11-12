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
      body: Column(
        children: [
          // Stora displayen (live)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: DisplayWidget(text: engine.display)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Text(
                    engine.strip,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65)
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                          letterSpacing: 0.5,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),

          // Grid
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