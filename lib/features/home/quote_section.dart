import 'package:flutter/material.dart';

import '../../theme/aziz_colors.dart';
import 'shared_components.dart';

class QuoteSection extends StatelessWidget {
  const QuoteSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = homeIsMobile(context);
    final isEn = homeIsEn(context);

    return HomeBand(
      color: AzizColors.trueIndigoDark,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 80 : 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '“',
                style: homeSerif(
                  size: 72,
                  color: AzizColors.saffron,
                  height: 0.5,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isEn
                    ? 'Indigo is not merely a dye; it is a living element that connects past traditions to present expression.'
                    : 'L’indigo n’est pas simplement une teinture ; c’est un élément vivant qui relie les traditions du passé à l’expression du présent.',
                textAlign: TextAlign.center,
                style: homeSerif(
                  size: isMobile ? 22 : 32,
                  height: 1.35,
                  color: AzizColors.lightBackground,
                  style: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                '— Olga',
                style: homeSans(
                  size: 15,
                  color: AzizColors.saffron,
                  weight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}