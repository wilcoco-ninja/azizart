import 'package:flutter/material.dart';
import '../../../theme/aziz_colors.dart';

class DiamondDivider extends StatelessWidget {
  final Color? color;
  final double size;
  final double lineWidth;
  final EdgeInsets padding;

  const DiamondDivider({
    super.key, this.color, this.size = 10, this.lineWidth = 60,
    this.padding = const EdgeInsets.symmetric(vertical: 20),
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AzizColors.accent;
    return Padding(
      padding: padding,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(width: lineWidth, child: Divider(color: c.withValues(alpha: 0.5), thickness: 0.8)),
        const SizedBox(width: 12),
        Transform.rotate(angle: 0.785398,
          child: Container(width: size, height: size, color: c)),
        const SizedBox(width: 12),
        SizedBox(width: lineWidth, child: Divider(color: c.withValues(alpha: 0.5), thickness: 0.8)),
      ]),
    );
  }
}
