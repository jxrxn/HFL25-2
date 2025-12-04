// lib/calculator_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  // ─────────────────────────────────────────────────────────
  // Remsa-historik
  // ─────────────────────────────────────────────────────────
  final List<String> _historyLines = [];
  String _currentStripLine = '';
  bool _justEvaluated = false; // true direkt efter '='

  /// Gemensam inmatningsfunktion för knappar + tangentbord.
  void _handleInput(String value) {
    // ======================================================
    // AC → Rensa motor & aktuell rad, men spara historiken
    // (krysset använder _clearAllAndHistory istället)
    // ======================================================
    if (value == 'AC') {
      engine.clearAll();
      _currentStripLine = '';
      _justEvaluated = false;
      setState(() {});
      return;
    }

    // Allt annat går först igenom motorn som vanligt
    engine.input(value);

    if (value == 'C') {
      // Clear entry – motorn sköter talet, vi synkar remsan
      _currentStripLine = engine.strip;
      _justEvaluated = false;
    } else if (value == '=') {
      // '=' avslutar/uppdaterar aktuella raden,
      // men vi flyttar inte till historiken förrän nästa knapptryckning
      _currentStripLine = engine.strip;
      _justEvaluated = true;
    } else {
      // Alla andra tangenter (siffra, komma, operator, %, …)

      if (_justEvaluated) {
        // Vi har just tryckt '=' och trycker nu *vad som helst* (förutom AC/C/=)
        // → föregående rad låses och hamnar i historiken,
        //    ny rad börjar från resultatet.
        if (_currentStripLine.isNotEmpty) {
          _historyLines.add(_currentStripLine);
        }
      }

      // Uppdatera aktuell rad från motorn (ny uträkning eller fortsatt)
      _currentStripLine = engine.strip;
      _justEvaluated = false;
    }

    setState(() {});
  }

  /// Rensa både motor, aktuell rad **och** historik – används av X-knappen.
  void _clearAllAndHistory() {
    setState(() {
      engine.clearAll();
      _historyLines.clear();
      _currentStripLine = '';
      _justEvaluated = false;
    });
  }

  /// Strängen som skickas till display-widgeten (flera rader med \n).
  String get _stripForDisplay {
    if (_historyLines.isEmpty && _currentStripLine.isEmpty) {
      return '';
    }
    return [
      ..._historyLines,
      if (_currentStripLine.isNotEmpty) _currentStripLine,
    ].join('\n');
  }

  @override
  void initState() {
    super.initState();
    engine = CalculatorEngine();
  }

  bool get _wantsKeyboardShortcuts {
    // Kortkommandon på web + desktop
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return true;
      default:
        return false; // Android / iOS / fuchsia
    }
  }

  // ─────────────────────────────────────────────────────────
  // Tangentbordshantering (webb + desktop)
  // ─────────────────────────────────────────────────────────
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final LogicalKeyboardKey key = event.logicalKey;
    String? ch = event.character;

    ch ??= key.keyLabel;
    if (ch.isEmpty) ch = null;

    String? input;

    // Siffror
    if (ch != null && RegExp(r'^[0-9]$').hasMatch(ch)) {
      input = ch;
    }
    // Decimaltecken
    else if (ch == ',' || ch == '.') {
      input = ',';
    }
    // Operatorer
    else if (ch == '+') {
      input = '+';
    } else if (ch == '-') {
      input = '-';
    } else if (ch == '*' || ch == '×') {
      input = '×';
    } else if (ch == '/' || ch == '÷') {
      input = '÷';
    } else if (ch == '%') {
      input = '%';
    }
    // Lika med / Enter
    else if (ch == '=' ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      input = '=';
    }
    // Backspace / Delete / Esc
    else if (key == LogicalKeyboardKey.backspace) {
      final pressed = HardwareKeyboard.instance.logicalKeysPressed;
      final ctrlPressed = pressed.contains(LogicalKeyboardKey.controlLeft) ||
          pressed.contains(LogicalKeyboardKey.controlRight);
      final metaPressed = pressed.contains(LogicalKeyboardKey.metaLeft) ||
          pressed.contains(LogicalKeyboardKey.metaRight); // Cmd på macOS

      // Ctrl+Backspace / Cmd+Backspace → AC, annars C
      input = (ctrlPressed || metaPressed) ? 'AC' : 'C';
    } else if (key == LogicalKeyboardKey.delete) {
      // Delete → AC
      input = 'AC';
    } else if (key == LogicalKeyboardKey.escape) {
      input = 'AC';
    }

    if (input == null) {
      return KeyEventResult.ignored;
    }

    _handleInput(input);
    return KeyEventResult.handled;
  }

  // ─────────────────────────────────────────────────────────
  // PORTRAIT-LAYOUT (display överst, knappar under)
  // ─────────────────────────────────────────────────────────
  Widget _buildPortraitLayout(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const cols = 4;
        const gap = 3.0;

        final width = constraints.maxWidth;

        final outerMargin = width < 500 ? 16.0 : 32.0;
        final horizontalPadding = width < 500 ? 8.0 : 16.0;

        double innerWidth = width - outerMargin * 2 - horizontalPadding * 2;
        if (innerWidth < 0) innerWidth = 0;

        final minGapWidth = gap * (cols - 1);

        double cellSize;
        double gridWidth;

        if (innerWidth <= minGapWidth) {
          cellSize = 0;
          gridWidth = innerWidth;
        } else {
          cellSize = (innerWidth - minGapWidth) / cols;
          gridWidth = cellSize * cols + minGapWidth;
        }

        double outerWidth = gridWidth + horizontalPadding * 2;
        if (outerWidth < 0) outerWidth = 0;
        if (outerWidth > width) outerWidth = width;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: outerMargin,
            vertical: 32,
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
                      stripText: _stripForDisplay,
                      isLandscape: false,
                      onClearHistory: _clearAllAndHistory,
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
                        onTap: _handleInput,
                        onLongClear: _clearAllAndHistory,
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
    );
  }

  // ─────────────────────────────────────────────────────────
  // LANDSCAPE-LAYOUT (display vänster, knappar höger, tema-kolumn längst till höger)
  // ─────────────────────────────────────────────────────────
  Widget _buildLandscapeLayout(BuildContext context, bool isDark) {
    const gap = 3.0;

    final size = MediaQuery.of(context).size;
    final width = size.width;

    // Samma logik som tidigare, med tydlig vertikal marginal
    final outerMargin = width < 700 ? 16.0 : 32.0;
    final horizontalPadding = width < 700 ? 8.0 : 16.0;
    const double verticalPadding = 32.0;

    // Knapparnas bredd
    final rawKeypadWidth = width * 0.40;
    final keypadWidth = rawKeypadWidth.clamp(260.0, 420.0);

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: outerMargin,
        vertical: verticalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // DISPLAY TILL VÄNSTER
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 700,
                ),
                child: DisplayWidget(
                  valueText: engine.display,
                  stripText: _stripForDisplay,
                  isLandscape: true,
                  onClearHistory: _clearAllAndHistory,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // KNAPPSATS I MITTEN
          SizedBox(
            width: keypadWidth,
            child: Center(
              child: ButtonGrid(
                onTap: _handleInput,
                onLongClear: _clearAllAndHistory,
                gap: gap,
                horizontalPadding: horizontalPadding,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // TEMA-KOLUMN LÄNGST TILL HÖGER
          SizedBox(
            width: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: isDark
                      ? 'Byt till ljust tema'
                      : 'Byt till mörkt tema',
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  color: scheme.onSurface,
                  onPressed: widget.onToggleTheme,
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final useKeyboard = _wantsKeyboardShortcuts;

    final media = MediaQuery.of(context);
    final size = media.size;
    final width = size.width;
    final height = size.height;

    final platform = defaultTargetPlatform;

    // Web + desktop beter sig "desktop-likt"
    final isDesktopLike = kIsWeb ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux;

    final isLandscape = width > height;

    // Enda fallet vi använder landscape-layouten är
    // mobil/platta i landscape.
    final useLandscapeLayout = (!isDesktopLike && isLandscape);

    // AppBar:
    //  - Desktop/Web: alltid AppBar.
    //  - Mobil/platta porträtt: AppBar.
    //  - Mobil/platta landscape: ingen AppBar (knapp i högerkolumn istället).
    final showAppBar = !useLandscapeLayout || isDesktopLike;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              actions: [
                IconButton(
                  tooltip:
                      isDark ? 'Byt till ljust tema' : 'Byt till mörkt tema',
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  onPressed: widget.onToggleTheme,
                ),
              ],
            )
          : null,
      body: Focus(
        autofocus: useKeyboard,
        onKeyEvent: useKeyboard ? _handleKeyEvent : null,
        child: useLandscapeLayout
            ? _buildLandscapeLayout(context, isDark)
            : _buildPortraitLayout(context),
      ),
    );
  }
}