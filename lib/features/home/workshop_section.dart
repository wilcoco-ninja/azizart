import 'package:flutter/material.dart';

import '../../core/localization/language_provider.dart';
import '../../theme/aziz_colors.dart';
import '../../widgets/optimized_image.dart';
import '../atelier/models/atelier_model.dart';
import 'shared_components.dart';

/// L'atelier : le geste en trois temps (cire, bain de teinture, feu).
///
/// Ici la numérotation est légitime : ce sont réellement des étapes
/// successives. La bande est indigo, veinée de craquelures de cire — le motif
/// que la cire laisse sur le tissu.
class WorkshopSection extends StatelessWidget {
  final Function(int) onNavigate;
  final List<AtelierPhoto> atelierPhotos;

  const WorkshopSection({
    super.key,
    required this.onNavigate,
    required this.atelierPhotos,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = homeIsMobile(context);
    final text = _WorkshopText(onNavigate: onNavigate);
    final collage = _WorkshopCollage(atelierPhotos: atelierPhotos);

    return HomeBand(
      color: AzizColors.trueIndigoDark,
      background: const BatikTexture(opacity: 0.10, seed: 21),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                collage,
                const SizedBox(height: 48),
                text,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: text),
                SizedBox(width: homeColumnGap(context)),
                Expanded(flex: 7, child: collage),
              ],
            ),
    );
  }
}

class _WorkshopText extends StatelessWidget {
  final Function(int) onNavigate;

  const _WorkshopText({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeHeading(
          title: context.tr('home.workshop_title'),
          onDark: true,
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            context.tr('home.workshop_desc'),
            style: homeSans(
              size: 16,
              color: AzizColors.lightBackground.withValues(alpha: 0.78),
              height: 1.8,
            ),
          ),
        ),
        const SizedBox(height: 36),
        const _WorkshopSteps(),
        const SizedBox(height: 40),
        HeroBtn(
          label: context.tr('home.workshop_cta'),
          leading: const Icon(HomeIcons.studio),
          onTap: () => onNavigate(2),
        ),
      ],
    );
  }
}

/// Les trois étapes, en liste filetée.
class _WorkshopSteps extends StatelessWidget {
  const _WorkshopSteps();

  static const List<String> _labelKeys = [
    'about.step1_title',
    'about.step2_title',
    'about.step3_title',
  ];

  // cire → pinceau, bain de teinture → goutte, fixation → flamme
  static const List<IconData> _icons = [
    HomeIcons.brush,
    HomeIcons.dye,
    HomeIcons.fire,
  ];

  @override
  Widget build(BuildContext context) {
    final line = AzizColors.lightBackground.withValues(alpha: 0.16);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        children: [
          for (var i = 0; i < _labelKeys.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: line),
                  bottom: i == _labelKeys.length - 1
                      ? BorderSide(color: line)
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${i + 1}',
                      style: homeSerif(
                        size: 30,
                        color: AzizColors.lightBackground.withValues(alpha: 0.5),
                        height: 1.0,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      context.tr(_labelKeys[i]),
                      style: homeSans(
                        size: 16,
                        color: AzizColors.lightBackground,
                        weight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kHomeRadius),
                      border: Border.all(
                        color: AzizColors.saffron.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(9),
                      child: Icon(
                        _icons[i],
                        size: 20,
                        color: AzizColors.saffronLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkshopCollage extends StatelessWidget {
  final List<AtelierPhoto> atelierPhotos;

  const _WorkshopCollage({required this.atelierPhotos});

  String? _urlAt(int index) {
    if (index < 0 || index >= atelierPhotos.length) return null;
    final url = atelierPhotos[index].displayImage;
    return url.isEmpty ? null : url;
  }

  @override
  Widget build(BuildContext context) {
    // Chemins de secours : `atelier/<fichier>` (résolus vers R2 par OptimizedImage).
    final bigUrl = _urlAt(1) ?? _urlAt(0) ?? 'atelier/exterieur.jpeg';
    final smallUrl =
        _urlAt(2) ?? _urlAt(3) ?? _urlAt(0) ?? 'atelier/banner.jpeg';
    const placeholder =
        SizedBox.expand(child: ColoredBox(color: AzizColors.trueIndigo));
    const placeholderLight =
        SizedBox.expand(child: ColoredBox(color: AzizColors.trueIndigoLight));
    final radius = BorderRadius.circular(kHomeRadius);

    return AspectRatio(
      aspectRatio: 1.05,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: FractionallySizedBox(
              widthFactor: 0.90,
              heightFactor: 0.95,
              child: OptimizedImage(
                url: bigUrl,
                fit: BoxFit.cover,
                memCacheWidth: 1200,
                borderRadius: radius,
                placeholder: placeholder,
                errorWidget: placeholder,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: FractionallySizedBox(
              widthFactor: 0.46,
              heightFactor: 0.48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AzizColors.mat,
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: OptimizedImage(
                    url: smallUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 700,
                    placeholder: placeholderLight,
                    errorWidget: placeholderLight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}