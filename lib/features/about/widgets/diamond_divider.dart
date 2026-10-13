import 'package:flutter/material.dart';
import '../../../theme/aziz_colors.dart';

class DiamondDivider extends StatelessWidget {
  final Color? color;
  final double size;
  final double lineWidth;
  final EdgeInsets padding;

  /// Si `true`, les deux traits s'étirent pour remplir toute la largeur
  /// disponible (`Expanded`) au lieu de rester à une largeur fixe
  /// (`lineWidth`). `false` par défaut pour ne rien changer aux appels
  /// existants qui n'en tiennent pas compte.
  final bool expand;

  const DiamondDivider({
    super.key,
    this.color,
    this.size = 10,
    this.lineWidth = 60,
    this.padding = const EdgeInsets.symmetric(vertical: 20),
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AzizColors.accent;
    final line = Divider(color: c.withValues(alpha: 0.5), thickness: 0.8);

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          expand ? Expanded(child: line) : SizedBox(width: lineWidth, child: line),
          const SizedBox(width: 12),
          Transform.rotate(
            angle: 0.785398,
            child: Container(width: size, height: size, color: c),
          ),
          const SizedBox(width: 12),
          expand ? Expanded(child: line) : SizedBox(width: lineWidth, child: line),
        ],
      ),
    );
  }
}