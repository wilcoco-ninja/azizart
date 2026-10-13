import 'package:flutter/material.dart';

import '../../core/localization/language_provider.dart';
import '../../theme/aziz_colors.dart';
import 'shared_components.dart';

class ExploreSection extends StatelessWidget {
  const ExploreSection({super.key, required this.onNavigate});

  final Function(int) onNavigate;

  @override
  Widget build(BuildContext context) {
    final isMobile = homeIsMobile(context);

    final title = Text(
      context.tr('home.explore_title'),
      style: homeSerif(
        size: isMobile ? 38 : 68,
        height: 1.05,
        letterSpacing: isMobile ? -0.6 : -1.2,
      ),
    );

    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.tr('home.explore_subtitle'),
          style: homeSans(size: 16, height: 1.75),
        ),
        const SizedBox(height: 28),
        HeroBtn(
          label: context.tr('home.view_full_gallery'),
          onTap: () => onNavigate(1),
        ),
      ],
    );

    return HomeBand(
      color: AzizColors.lightBackground,
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 28),
                side,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(flex: 6, child: title),
                SizedBox(width: homeColumnGap(context)),
                Expanded(flex: 4, child: side),
              ],
            ),
    );
  }
}