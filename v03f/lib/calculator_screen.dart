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
          const gap = 3.0;

          final width = constraints.maxWidth;

          // Yttre marginaler/innerspalt – samma logik som tidigare
          final outerMargin = width < 500 ? 16.0 : 32.0;
          final horizontalPadding = width < 500 ? 8.0 : 16.0;

          // Tillgänglig bredd för själva knapprutnätet (utan outerMargin och padding)
          double innerWidth =
              width - outerMargin * 2 - horizontalPadding * 2;

          // Skydda mot konstiga constraint-lägen (innerWidth kan inte vara negativ)
          if (innerWidth < 0) innerWidth = 0;

          // Minsta bredd som bara gapsen tar
          final minGapWidth = gap * (cols - 1);

          double cellSize;
          double gridWidth;

          if (innerWidth <= minGapWidth) {
            // Extremfall (borde aldrig hända på riktiga telefoner):
            // gör cellerna 0 breda så vi åtminstone inte kraschar.
            cellSize = 0;
            gridWidth = innerWidth;
          } else {
            cellSize = (innerWidth - minGapWidth) / cols;
            gridWidth = cellSize * cols + minGapWidth;
          }

          // Yttre bredd för display + grid (inkl. horisontell padding),
          // klampad så att den aldrig blir negativ eller större än tillgänglig bredd.
          double outerWidth = gridWidth + horizontalPadding * 2;
          if (outerWidth < 0) outerWidth = 0;
          if (outerWidth > width) outerWidth = width;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: outerMargin,
              vertical: 16,
            ),
            child: Column(
              children: [
                // DISPLAY
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

                // GRID
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