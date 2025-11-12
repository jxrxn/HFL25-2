import 'package:flutter/material.dart';
import '../calc_button.dart';

class ButtonGrid extends StatelessWidget {
  final List<String> labels;
  final void Function(String) onTap;
  const ButtonGrid({super.key, required this.labels, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Responsiv kolumnbredd
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width > 520 ? 5 : 4;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      padding: const EdgeInsets.all(8),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final label in labels)
          CalcButton(
            key: Key('btn-$label'),
            label: label,
            onTap: () => onTap(label),
            buttonKey: Key('btn-$label'),
          ),
      ],
    );
  }
}