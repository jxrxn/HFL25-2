// lib/ui/display_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_size_text/auto_size_text.dart';

class DisplayWidget extends StatefulWidget {
  final String valueText;
  final String stripText;
  final bool isLandscape;
  final VoidCallback? onClearHistory; // krysset i hörnet

  const DisplayWidget({
    super.key,
    required this.valueText,
    required this.stripText,
    this.isLandscape = false,
    this.onClearHistory,
  });

  @override
  State<DisplayWidget> createState() => _DisplayWidgetState();
}

class _DisplayWidgetState extends State<DisplayWidget> {
  final ScrollController _scrollController = ScrollController();

  bool _highlightStrip = false;
  bool _highlightValue = false;

  /// Tunna mellanrum för tusental (för tal i form "12345.67").
  /// Arbetar alltid med punkt som decimal internt.
  String _groupThousands(String s) {
    final numberPattern = RegExp(r'^-?\d+(\.\d+)?$');
    if (!numberPattern.hasMatch(s)) return s;

    final negative = s.startsWith('-');
    var body = negative ? s.substring(1) : s;

    final parts = body.split('.');
    final intPart = parts[0];
    final fracPart = parts.length > 1 ? '.${parts[1]}' : '';

    final buf = StringBuffer();
    var count = 0;

    for (var i = intPart.length - 1; i >= 0; i--) {
      buf.write(intPart[i]);
      count++;
      if (count == 3 && i != 0) {
        buf.write('\u202F'); // tunt mellanrum
        count = 0;
      }
    }

    final reversed = buf.toString().runes.toList().reversed;
    final groupedInt = String.fromCharCodes(reversed);

    return '${negative ? '-' : ''}$groupedInt$fracPart';
  }

  void _animateToBottom() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;

    if (position.maxScrollExtent <= 0) return;

    _scrollController.animateTo(
      position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(covariant DisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stripText != widget.stripText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateToBottom();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final stripColor = isDark
        ? scheme.onSurface.withValues(alpha: 0.7)
        : scheme.onSurface.withValues(alpha: 0.6);

    // 1) Gruppera tusental för huvudtalet (med punkt internt)
    final groupedValue = _groupThousands(widget.valueText);

    // 2) Konvertera visningen till svensk stil
    final displayValue = groupedValue.replaceAll('.', ',');
    final displayStripRaw = widget.stripText.replaceAll('.', ',');

    // Dela upp remsan i rader
    final lines = displayStripRaw
        .split('\n')
        .map((l) => l.trimRight())
        .where((l) => l.isNotEmpty)
        .toList();

    // Höjd för remsan: plats för ~3 rader
    final baseFontSize = theme.textTheme.bodyLarge?.fontSize ?? 16;
    final lineHeight = baseFontSize * 1.4;
    final visibleLines = widget.isLandscape ? 3.0 : 3.4;
    final historyHeight = lineHeight * visibleLines;

    // Mindre yttre padding, vi låter innehållet ha sin egen padding
    final outerPadding = widget.isLandscape
        ? const EdgeInsets.fromLTRB(16, 8, 16, 12)
        : const EdgeInsets.fromLTRB(16, 10, 16, 16);

    const double fadeHeight = 12.0;

    final showTopFade = lines.length > 1;
    final showBottomFade = lines.length > visibleLines;

    final stripHighlightColor = scheme.onSurface.withValues(
      alpha: isDark ? 0.08 : 0.10,
    );
    final valueHighlightColor = scheme.onSurface.withValues(
      alpha: isDark ? 0.08 : 0.10,
    );

    return Stack(
      children: [
        // Själva displayboxen
        Container(
          width: double.infinity,
          color: scheme.surfaceContainerHighest,
          padding: outerPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===== ÖVRE REMSAN – historik, scroll, toningar =====
              SizedBox(
                height: historyHeight,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    color: _highlightStrip
                        ? stripHighlightColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (displayStripRaw.isEmpty) return;

                      setState(() {
                        _highlightStrip = true;
                      });

                      Clipboard.setData(ClipboardData(text: displayStripRaw));

                      final snackBar = SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: isDark
                            ? scheme.surfaceContainerLow
                            : scheme.surfaceContainerHighest,
                        content: Text(
                          'Uträkning kopierad',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        duration: const Duration(milliseconds: 900),
                      );

                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(snackBar);

                      Future.delayed(const Duration(milliseconds: 180), () {
                        if (mounted) {
                          setState(() {
                            _highlightStrip = false;
                          });
                        }
                      });
                    },
                    child: Stack(
                      children: [
                        // Historik-listan
                        Positioned.fill(
                          child: ClipRect(
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              // 🔹 Viktigt: extra padding i botten så
                              // nedersta raden inte hamnar under fade:
                              padding: EdgeInsets.only(
                                bottom: showBottomFade ? fadeHeight : 0,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: historyHeight,
                                ),
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      for (int i = 0;
                                          i < lines.length;
                                          i++) ...[
                                        if (i > 0)
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 2),
                                            height: 0.7,
                                            color: stripColor.withValues(
                                              alpha: 0.35,
                                            ),
                                          ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            reverse: true,
                                            child: Text(
                                              lines[i],
                                              key: i == lines.length - 1
                                                  ? const Key(
                                                      'display-strip-text',
                                                    )
                                                  : null,
                                              softWrap: false,
                                              textAlign: TextAlign.right,
                                              style: theme
                                                  .textTheme.bodyLarge
                                                  ?.copyWith(
                                                color: stripColor,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Fade upptill (när det finns äldre rader)
                        if (showTopFade)
                          IgnorePointer(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                height: fadeHeight,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      scheme.surfaceContainerHighest,
                                      scheme.surfaceContainerHighest
                                          .withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Fade nedtill (bara när mer finns att scrolla nedåt)
                        if (showBottomFade)
                          IgnorePointer(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: fadeHeight,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      scheme.surfaceContainerHighest,
                                      scheme.surfaceContainerHighest
                                          .withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ===== STORA TALLET — klickbart & auto-size + highlight =====
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (widget.valueText.isEmpty) return;

                    setState(() => _highlightValue = true);

                    Clipboard.setData(ClipboardData(text: widget.valueText));

                    final snackBar = SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: isDark
                          ? scheme.surfaceContainerLow
                          : scheme.surfaceContainerHighest,
                      content: Text(
                        'Tal kopierat',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      duration: const Duration(milliseconds: 900),
                    );

                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(snackBar);

                    Future.delayed(const Duration(milliseconds: 180), () {
                      if (mounted) {
                        setState(() => _highlightValue = false);
                      }
                    });
                  },
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: _highlightValue
                            ? valueHighlightColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: AutoSizeText(
                        displayValue,
                        key: const Key('display-main-value'),
                        maxLines: 1,
                        minFontSize: 18,
                        stepGranularity: 1,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ===== KRYSS FÖR ATT RADERA HISTORIK + AKTUELL RAD =====
        if (widget.onClearHistory != null)
          Positioned(
            right: 4,
            top: 0,
            child: IconButton(
              iconSize: 18,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              tooltip: 'Rensa historik',
              icon: const Icon(Icons.close),
              color: stripColor,
              onPressed: widget.onClearHistory,
            ),
          ),
      ],
    );
  }
}