import 'package:flutter/material.dart';

class ConfidenceBar extends StatelessWidget {
  const ConfidenceBar({super.key, required this.value});

  final double value; // 0..1

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final c = Theme.of(context).colorScheme;
    final Color fill = clamped < 0.4
        ? Colors.orange.shade400
        : (clamped < 0.7 ? c.primary : Colors.green.shade500);
    return Stack(
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: c.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        FractionallySizedBox(
          widthFactor: clamped,
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }
}
