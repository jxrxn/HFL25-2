// lib/ui/display_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DisplayWidget extends StatefulWidget {
  final String text;
  const DisplayWidget({super.key, required this.text});

  @override
  State<DisplayWidget> createState() => _DisplayWidgetState();
}

class _DisplayWidgetState extends State<DisplayWidget> {
  final _controller = ScrollController();

  @override
  void didUpdateWidget(covariant DisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) _controller.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context) {
    if (widget.text.trim().isEmpty) return;

    Clipboard.setData(ClipboardData(text: widget.text));
    final scheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        content: Text(
          'Kopierat till urklipp',
          style: TextStyle(color: scheme.onInverseSurface),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _copyToClipboard(context),
      child: Container(
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: scheme.surfaceContainerHighest,
        child: SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Text(
            widget.text,
            key: const Key('display'),
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}