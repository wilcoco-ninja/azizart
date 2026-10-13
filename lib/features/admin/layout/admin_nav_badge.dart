import 'package:flutter/material.dart';

import '../../../theme/admin_colors.dart';

class AdminNavBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final Color backgroundColor;

  const AdminNavBadge({
    super.key,
    required this.child,
    required this.count,
    this.backgroundColor = AdminColors.surface,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    final label = count > 9 ? '9+' : '$count';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        // PositionedDirectional : le badge passe à gauche en langue RTL.
        PositionedDirectional(
          end: -6,
          top: -5,
          child: Semantics(
            label: '$count élément${count > 1 ? 's' : ''} à traiter',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: AdminColors.danger,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: backgroundColor, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}