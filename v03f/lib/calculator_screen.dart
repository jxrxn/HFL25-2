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
        actions: [
          IconButton(
            tooltip: isDark ? 'Byt till ljust tema' : 'Byt till mörkt tema',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const cols = 4;
          const rows = 5;
          const gap = 3.0;

          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          // Mindre marginal på mobil, lite större på större skärmar
          final outerMargin = width < 500 ? 16.0 : 32.0;
          final horizontalPadding = width < 500 ? 8.0 : 16.0;

          final usableWidth = width - outerMargin * 2;
          final usableHeight = height - outerMargin * 2;

          // Samma logik som i ButtonGrid för att räkna fram cellstorlek
          final maxGridWidthByWidth = usableWidth - horizontalPadding * 2;
          final cellSizeByWidth =
              (maxGridWidthByWidth - gap * (cols - 1)) / cols;

          final buttonAreaHeight = usableHeight * 2 / 3;
          final cellSizeByHeight =
              (buttonAreaHeight - gap * (rows - 1)) / rows;

          final cell = cellSizeByWidth < cellSizeByHeight
              ? cellSizeByWidth
              : cellSizeByHeight;

          // Själva gridets bredd (4 knappar + 3 gap)
          final gridWidth = cell * cols + gap * (cols - 1);

          // Yttre bredd: grid + padding på båda sidor
          final outerWidth = gridWidth + horizontalPadding * 2;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: outerMargin,
              vertical: 16,
            ),
            child: Column(
              children: [
                // ===== DISPLAY – samma bredd som knapparna =====
                Expanded(
                  flex: 1,
                  child: Center(
                    child: SizedBox(
                      width: outerWidth,
                      child: DisplayWidget(
                        valueText: engine.display,
                        stripText: engine.strip,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ===== GRID – samma bredd, lite luft mot nederkant =====
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SizedBox(
                        width: outerWidth,
                        child: ButtonGrid(
                          onTap: (v) => setState(() => engine.input(v)),
                          onLongClear: () => setState(() => engine.clearAll()),
                          gap: gap,
                          horizontalPadding: horizontalPadding,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}