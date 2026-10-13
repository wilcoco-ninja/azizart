import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../core/app_data_provider.dart';
import '../../core/localization/language_provider.dart';
import '../../theme/aziz_colors.dart';
import '../../widgets/optimized_image.dart';
import '../home/shared_components.dart';

// ═══════════════════════════════════════════════════════════════════════════
// RÉSOLUTION DES DONNÉES (BASE DE DONNÉES / FALLBACK TRADUCTIONS)
// ═══════════════════════════════════════════════════════════════════════════

const Map<String, String> _aboutKeyToColumn = {
  'about.title': 'hero_label',
  'about.name': 'artist_name',
  'about.heritage': 'heritage_line',
  'about.heritage_badge': 'heritage_badge',
  'about.intro_title': 'intro_title',
  'about.intro_text': 'intro_text',
  'about.intro_text2': 'intro_text2',
  'about.origins_title': 'origins_title',
  'about.origins_text1': 'origins_text1',
  'about.origins_text2': 'origins_text2',
  'about.grandma_quote': 'quote',
  'about.grandma_author': 'quote_author',
  'about.art_title': 'art_title',
  'about.art_text1': 'art_text1',
  'about.art_text2': 'art_text2',
  'about.dyes_title': 'dyes_title',
  'about.timeline_title': 'timeline_title',
  'about.representation_title': 'representation_title',
  'about.representation_text': 'representation_text',
};

/// Vrai si au moins un élément de [before] ET un de [after] sont affichés :
/// sert à n'insérer un espacement qu'entre deux blocs réellement visibles.
bool _gap(BuildContext context, List<String> before, List<String> after) =>
    before.any((c) => !context.aboutHidden(c)) &&
    after.any((c) => !context.aboutHidden(c));

extension AboutContentExtension on BuildContext {
  Map<String, dynamic>? get _aboutData => watch<Map<String, dynamic>?>();

  String aboutTr(String key) {
    final dbKey = _aboutKeyToColumn[key];
    final data = _aboutData;
    if (data != null && dbKey != null) {
      final lang = watch<LanguageProvider>().languageCode;
      final value = data['${dbKey}_$lang'] as String? ?? data[dbKey] as String?;
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return tr(key);
  }

  /// Vrai si l'admin a masqué ce contenu (colonne `hidden_fields`).
  bool aboutHidden(String column) {
    final raw = _aboutData?['hidden_fields'];
    return raw is List && raw.contains(column);
  }

  List<Map<String, dynamic>> aboutList(
    String columnBaseName,
    List<Map<String, dynamic>> fallback,
  ) {
    final data = _aboutData;
    if (data == null) return fallback;
    final lang = watch<LanguageProvider>().languageCode;
    final raw = data['${columnBaseName}_$lang'] ?? data[columnBaseName];
    if (raw is List && raw.isNotEmpty) {
      try {
        return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {
        return fallback;
      }
    }
    return fallback;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAGE PRINCIPALE : ABOUT (MODE VISIONNAGE)
// ═══════════════════════════════════════════════════════════════════════════

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    return Provider<Map<String, dynamic>?>.value(
      value: context.watch<AppDataProvider>().aboutContent,
      child: const _AboutPageBody(),
    );
  }
}

class _AboutPageBody extends StatelessWidget {
  const _AboutPageBody();

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    final isMobile = homeIsMobile(context);
    final gutter = homeGutter(context);

    bool any(List<String> columns) =>
        columns.any((c) => !context.aboutHidden(c));

    // Uniquement les sections visibles (selon l'admin).
    final sections = <Widget>[
      if (any(['intro_title', 'intro_text', 'intro_text2']))
        const _IntroTextSection(),
      if (any(['origins_title', 'origins_text1', 'origins_text2']))
        const _StorySection(),
      if (any(['quote', 'quote_author'])) const _QuoteBlockSection(),
      if (any(['art_title', 'art_text1', 'art_text2', 'technique_steps']))
        const _TechniqueShowcase(),
      if (any(['dyes_title', 'natural_dyes']))
        const _NaturalIngredientsSection(),
      if (any(['timeline_title', 'timeline_events']))
        const _TimelineSection(),
      if (any(['stats'])) const _StatsDashboard(),
      if (!context.aboutHidden('custom_sections') &&
          context.aboutList('custom_sections', const []).isNotEmpty)
        const _CustomSectionsSection(),
      if (any(['representation_title', 'representation_text']))
        const _RepresentationSection(),
    ];

    final sectionGap = isMobile ? 72.0 : 112.0;

    return Scaffold(
      backgroundColor: AzizColors.lightBackground,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, isMobile ? 32 : 56, gutter, 0),
              child: const _AboutHero(),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, 32, gutter, 0),
              child: const _ProfileInfoBar(),
            ),
            SizedBox(height: sectionGap),
            for (var i = 0; i < sections.length; i++) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: sections[i],
              ),
              SizedBox(height: i == sections.length - 1 ? 96 : sectionGap),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS UTILITAIRES PUBLICS (conservés)
// ═══════════════════════════════════════════════════════════════════════════

class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const FadeSlideIn({
    super.key,
    required this.child,
    required this.delay,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class AnimatedCounter extends StatefulWidget {
  final String rawValue;
  final TextStyle style;

  const AnimatedCounter({
    super.key,
    required this.rawValue,
    required this.style,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  late double _targetNumber;
  late String _prefix;
  late String _suffix;

  @override
  void initState() {
    super.initState();
    _parseValue();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.fastOutSlowIn);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _ctrl.forward();
    });
  }

  void _parseValue() {
    final match = RegExp(r'([^0-9]*?)(\d+)(.*)').firstMatch(widget.rawValue);
    if (match != null) {
      _prefix = match.group(1)?.trim() ?? '';
      _targetNumber = double.parse(match.group(2)!);
      _suffix = match.group(3) ?? '';
    } else {
      _prefix = '';
      _targetNumber = -1;
      _suffix = widget.rawValue;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rawValue != widget.rawValue) {
      _parseValue();
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_targetNumber < 0) {
      return Text(widget.rawValue, style: widget.style);
    }
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) {
        final current = (_anim.value * _targetNumber).round();
        return Text('$_prefix$current$_suffix', style: widget.style);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EN-TÊTE : bannière, portrait encadré, nom
// ═══════════════════════════════════════════════════════════════════════════

class _AboutHero extends StatelessWidget {
  const _AboutHero();

  @override
  Widget build(BuildContext context) {
    final isMobile = homeIsMobile(context);

    final data = context.watch<Map<String, dynamic>?>();
    String? clean(Object? value) {
      final text = value is String ? value.trim() : '';
      return text.isEmpty ? null : text;
    }

    // Images de la base (Cloudflare R2). À défaut, visuels R2 par défaut.
    final base = AppConfig.mediaBase;
    final bannerUrl = clean(data?['banner_url']) ??
        '$base/about_banners/1790340121483_283187000.jpeg';
    final avatarUrl = clean(data?['avatar_path']) ??
        clean(data?['avatar_url']) ??
        '$base/about_avatars/1790212952290_501257559.jpeg';
    final displayName =
        clean(data?['artist_name']) ?? context.aboutTr('about.name');

    final banner = SizedBox(
      height: isMobile ? 260 : 460,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kHomeRadius),
        child: OptimizedImage(
          url: bannerUrl,
          folder: 'about_banners',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          memCacheWidth: 1600,
          alignment: const Alignment(0, -0.2),
          errorWidget: const _PortraitFallback(),
        ),
      ),
    );

    final portrait = SizedBox(
      width: isMobile ? 120 : 176,
      height: isMobile ? 150 : 220,
      child: HomeMat(
        raised: true,
        padding: 6,
        child: OptimizedImage(
          url: avatarUrl,
          folder: 'about_avatars',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          memCacheWidth: 400,
          errorWidget: const _PortraitFallback(),
        ),
      ),
    );

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!context.aboutHidden('hero_label')) ...[
          Text(
            context.aboutTr('about.title'),
            style: homeSans(
              size: 15,
              color: AzizColors.trueIndigoLight,
              weight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Semantics(
          header: true,
          child: Text(
            displayName,
            style: homeSerif(
              size: isMobile ? 44 : 72,
              height: 1.04,
              letterSpacing: isMobile ? -0.8 : -1.4,
            ),
          ),
        ),
        if (!context.aboutHidden('heritage_line')) ...[
          const SizedBox(height: 14),
          Text(
            context.aboutTr('about.heritage'),
            style: homeSerif(
              size: isMobile ? 19 : 24,
              color: AzizColors.lightTextMuted,
              style: FontStyle.italic,
              height: 1.35,
            ),
          ),
        ],
        if (!context.aboutHidden('heritage_badge')) ...[
          const SizedBox(height: 20),
          const _HeritageBadgeWidget(),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        banner,
        SizedBox(height: isMobile ? 28 : 40),
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [portrait, const SizedBox(height: 24), text],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              portrait,
              const SizedBox(width: 40),
              Expanded(child: text),
            ],
          ),
      ],
    );
  }
}

class _PortraitFallback extends StatelessWidget {
  const _PortraitFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AzizColors.lightSurface,
      child: Center(
        child: Icon(
          Icons.brush_outlined,
          size: 56,
          color: AzizColors.trueIndigo.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BARRE D'INFORMATIONS DE PROFIL
// ═══════════════════════════════════════════════════════════════════════════

class _ProfileInfoBar extends StatelessWidget {
  const _ProfileInfoBar();

  @override
  Widget build(BuildContext context) {
    final data = context.watch<Map<String, dynamic>?>();
    final lang = context.watch<LanguageProvider>().languageCode;
    final location = (data?['location_$lang'] ?? data?['location']) as String?;
    final startYear = data?['career_start_year'];
    final langDisciplines = data?['disciplines_$lang'];
    final disciplinesRaw =
        (langDisciplines is List && langDisciplines.isNotEmpty)
            ? langDisciplines
            : data?['disciplines'];
    final disciplines = disciplinesRaw is List
        ? disciplinesRaw
            .map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList()
        : <String>[];

    final hasLocation = location != null && location.trim().isNotEmpty;
    final hasStartYear = startYear != null && startYear.toString().isNotEmpty;
    final hasDisciplines = disciplines.isNotEmpty;

    if (!hasLocation && !hasStartYear && !hasDisciplines) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (hasLocation)
          _InfoChip(icon: Icons.location_on_outlined, label: location),
        if (hasStartYear)
          _InfoChip(
            icon: Icons.history_outlined,
            label: homeText(
              context,
              fr: 'Depuis $startYear',
              en: 'Since $startYear',
            ),
          ),
        for (final d in disciplines)
          _InfoChip(icon: Icons.palette_outlined, label: d),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AzizColors.mat,
        borderRadius: BorderRadius.circular(kHomeRadius),
        border: Border.all(color: AzizColors.lightBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AzizColors.trueIndigo),
          const SizedBox(width: 8),
          Text(
            label,
            style: homeSans(
              size: 13.5,
              color: AzizColors.lightTextPrimary,
              weight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTIONS
// ═══════════════════════════════════════════════════════════════════════════

class _IntroTextSection extends StatelessWidget {
  const _IntroTextSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = homeIsMobile(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!context.aboutHidden('intro_title'))
              Text(
                context.aboutTr('about.intro_title'),
                textAlign: TextAlign.center,
                style: homeSerif(
                  size: isMobile ? 30 : 42,
                  color: AzizColors.trueIndigo,
                  style: FontStyle.italic,
                  height: 1.3,
                  letterSpacing: -0.4,
                ),
              ),
            if (_gap(context, ['intro_title'], ['intro_text', 'intro_text2']))
              const SizedBox(height: 40),
            if (!context.aboutHidden('intro_text'))
              _ParagraphText(
                text: context.aboutTr('about.intro_text'),
                emphasis: true,
                center: true,
              ),
            if (_gap(context, ['intro_text'], ['intro_text2']))
              const SizedBox(height: 24),
            if (!context.aboutHidden('intro_text2'))
              _ParagraphText(
                text: context.aboutTr('about.intro_text2'),
                secondary: true,
                center: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _StorySection extends StatelessWidget {
  const _StorySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!context.aboutHidden('origins_title'))
          const _SectionTitleWidget(titleKey: 'about.origins_title'),
        if (_gap(context, ['origins_title'], ['origins_text1', 'origins_text2']))
          const SizedBox(height: 32),
        if (!context.aboutHidden('origins_text1'))
          _ParagraphText(text: context.aboutTr('about.origins_text1')),
        if (_gap(context, ['origins_text1'], ['origins_text2']))
          const SizedBox(height: 24),
        if (!context.aboutHidden('origins_text2'))
          _ParagraphText(text: context.aboutTr('about.origins_text2')),
      ],
    );
  }
}

/// Citation : le temps fort de la page, sur bande indigo.
class _QuoteBlockSection extends StatelessWidget {
  const _QuoteBlockSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = homeIsMobile(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(kHomeRadius),
      child: ColoredBox(
        color: AzizColors.trueIndigoDark,
        child: Stack(
          children: [
            const Positioned.fill(
              child: BatikTexture(opacity: 0.08, seed: 61),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 56 : 88,
                horizontal: isMobile ? 28 : 72,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!context.aboutHidden('quote'))
                        Text(
                          '« ${context.aboutTr('about.grandma_quote')} »',
                          textAlign: TextAlign.center,
                          style: homeSerif(
                            size: isMobile ? 24 : 34,
                            color: AzizColors.lightBackground,
                            style: FontStyle.italic,
                            height: 1.45,
                          ),
                        ),
                      if (_gap(context, ['quote'], ['quote_author']))
                        const SizedBox(height: 28),
                      if (!context.aboutHidden('quote_author'))
                        Text(
                          context.aboutTr('about.grandma_author'),
                          textAlign: TextAlign.center,
                          style: homeSans(
                            size: 15,
                            color: AzizColors.saffronLight,
                            weight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechniqueShowcase extends StatelessWidget {
  const _TechniqueShowcase();

  @override
  Widget build(BuildContext context) {
    final isCompact = !homeIsDesktop(context);

    // cire → goutte, bain de teinture → palette, fixation → éclat
    const stepIcons = [
      Icons.water_drop_outlined,
      Icons.color_lens_outlined,
      Icons.auto_fix_high_outlined,
    ];
    final stepsData = context.aboutList('technique_steps', [
      {
        'title': context.aboutTr('about.step1_title'),
        'text': context.aboutTr('about.step1_text'),
      },
      {
        'title': context.aboutTr('about.step2_title'),
        'text': context.aboutTr('about.step2_text'),
      },
      {
        'title': context.aboutTr('about.step3_title'),
        'text': context.aboutTr('about.step3_text'),
      },
    ]);
    final steps = List.generate(
      stepsData.length,
      (i) => _CardModel(
        icon: stepIcons[i % stepIcons.length],
        title: stepsData[i]['title'] as String? ?? '',
        text: stepsData[i]['text'] as String? ?? '',
        stepNumber: (i + 1).toString().padLeft(2, '0'),
      ),
    );
    final useRow = !isCompact && steps.length <= 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!context.aboutHidden('art_title'))
          const _SectionTitleWidget(titleKey: 'about.art_title'),
        if (_gap(context, ['art_title'],
            ['art_text1', 'art_text2', 'technique_steps']))
          const SizedBox(height: 32),
        if (!context.aboutHidden('art_text1'))
          _ParagraphText(text: context.aboutTr('about.art_text1')),
        if (_gap(context, ['art_text1'], ['art_text2']))
          const SizedBox(height: 24),
        if (!context.aboutHidden('art_text2'))
          _ParagraphText(text: context.aboutTr('about.art_text2')),
        if (_gap(context, ['art_text1', 'art_text2'], ['technique_steps']))
          const SizedBox(height: 56),
        if (!context.aboutHidden('technique_steps'))
          useRow
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < steps.length; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: i == steps.length - 1 ? 0 : 32,
                            ),
                            child: _StepItem(data: steps[i]),
                          ),
                        ),
                    ],
                  ),
                )
              : Column(
                  children: [for (final s in steps) _StepItem(data: s)],
                ),
      ],
    );
  }
}

/// Étape numérotée : les étapes se suivent réellement (cire, bain, fixation).
class _StepItem extends StatelessWidget {
  final _CardModel data;

  const _StepItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 32),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AzizColors.lightBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.stepNumber,
                style: homeSerif(
                  size: 32,
                  color: AzizColors.trueIndigoLight,
                  height: 1.0,
                ),
              ),
              Icon(data.icon, color: AzizColors.trueIndigo, size: 24),
            ],
          ),
          const SizedBox(height: 24),
          Text(data.title, style: homeSerif(size: 24, height: 1.2)),
          const SizedBox(height: 12),
          Text(data.text, style: homeSans(size: 15.5, height: 1.75)),
        ],
      ),
    );
  }
}

class _NaturalIngredientsSection extends StatelessWidget {
  const _NaturalIngredientsSection();

  @override
  Widget build(BuildContext context) {
    // indigo, cola, baobab, teck : plantes et écorces
    const dyeIcons = [
      Icons.spa_outlined,
      Icons.forest_outlined,
      Icons.park_outlined,
      Icons.eco_outlined,
    ];
    final dyesData = context.aboutList('natural_dyes', [
      {
        'title': context.aboutTr('about.indigo_title'),
        'text': context.aboutTr('about.indigo_text'),
      },
      {
        'title': context.aboutTr('about.cola_title'),
        'text': context.aboutTr('about.cola_text'),
      },
      {
        'title': context.aboutTr('about.baobab_title'),
        'text': context.aboutTr('about.baobab_text'),
      },
      {
        'title': context.aboutTr('about.teck_title'),
        'text': context.aboutTr('about.teck_text'),
      },
    ]);
    final dyes = List.generate(
      dyesData.length,
      (i) => _CardModel(
        icon: dyeIcons[i % dyeIcons.length],
        title: dyesData[i]['title'] as String? ?? '',
        text: dyesData[i]['text'] as String? ?? '',
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!context.aboutHidden('dyes_title'))
          const _SectionTitleWidget(titleKey: 'about.dyes_title'),
        if (_gap(context, ['dyes_title'], ['natural_dyes']))
          const SizedBox(height: 40),
        if (!context.aboutHidden('natural_dyes'))
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 48.0;
              final twoColumns = constraints.maxWidth >= 760;
              final itemWidth = twoColumns
                  ? (constraints.maxWidth - gap) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: gap,
                children: [
                  for (final item in dyes)
                    SizedBox(width: itemWidth, child: _DyeItem(item: item)),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _DyeItem extends StatelessWidget {
  final _CardModel item;
  const _DyeItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AzizColors.lightBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: AzizColors.trueIndigo, size: 26),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: homeSerif(size: 22, height: 1.25)),
                const SizedBox(height: 10),
                Text(item.text, style: homeSans(size: 15, height: 1.7)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection();

  @override
  Widget build(BuildContext context) {
    final eventsData = context.aboutList('timeline_events', [
      {
        'year': context.aboutTr('about.timeline_year1'),
        'title': context.aboutTr('about.timeline_title1'),
        'description': context.aboutTr('about.timeline_desc1'),
      },
      {
        'year': context.aboutTr('about.timeline_year2'),
        'title': context.aboutTr('about.timeline_title2'),
        'description': context.aboutTr('about.timeline_desc2'),
      },
      {
        'year': context.aboutTr('about.timeline_year3'),
        'title': context.aboutTr('about.timeline_title3'),
        'description': context.aboutTr('about.timeline_desc3'),
      },
      {
        'year': context.aboutTr('about.timeline_year4'),
        'title': context.aboutTr('about.timeline_title4'),
        'description': context.aboutTr('about.timeline_desc4'),
      },
    ]);
    final events = List.generate(
      eventsData.length,
      (i) => _TimelineEvent(
        year: eventsData[i]['year'] as String? ?? '',
        title: eventsData[i]['title'] as String? ?? '',
        description: eventsData[i]['description'] as String? ?? '',
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!context.aboutHidden('timeline_title'))
          const _SectionTitleWidget(titleKey: 'about.timeline_title'),
        if (_gap(context, ['timeline_title'], ['timeline_events']))
          const SizedBox(height: 56),
        if (!context.aboutHidden('timeline_events'))
          ...List.generate(events.length, (i) {
            return _TimelineItem(
              event: events[i],
              isLast: i == events.length - 1,
            );
          }),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final _TimelineEvent event;
  final bool isLast;

  const _TimelineItem({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isMobile = homeIsMobile(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isMobile ? 64 : 96,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                event.year,
                textAlign: TextAlign.right,
                style: homeSerif(
                  size: 19,
                  color: AzizColors.trueIndigo,
                  weight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: AzizColors.trueIndigo,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: AzizColors.lightBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: homeSerif(size: 22, height: 1.25)),
                  const SizedBox(height: 10),
                  Text(
                    event.description,
                    style: homeSans(size: 15.5, height: 1.7),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsDashboard extends StatelessWidget {
  const _StatsDashboard();

  @override
  Widget build(BuildContext context) {
    final statsData = context.aboutList('stats', [
      {
        'value': context.aboutTr('about.stat_aho'),
        'label': context.aboutTr('about.stat_aho_label'),
      },
      {
        'value': context.aboutTr('about.stat_dyes'),
        'label': context.aboutTr('about.stat_dyes_label'),
      },
      {
        'value': context.aboutTr('about.stat_handmade'),
        'label': context.aboutTr('about.stat_handmade_label'),
      },
      {
        'value': context.aboutTr('about.stat_heritage'),
        'label': context.aboutTr('about.stat_heritage_label'),
      },
    ]);
    final stats = statsData
        .map((s) => _StatModel(
              value: s['value'] as String? ?? '',
              label: s['label'] as String? ?? '',
            ))
        .toList();
    if (stats.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 24.0;
        final columns = math.max(
          1,
          math.min(stats.length, constraints.maxWidth < 560 ? 2 : 4),
        );
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 56),
          decoration: const BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: AzizColors.lightBorder),
            ),
          ),
          child: Wrap(
            spacing: gap,
            runSpacing: 44,
            children: [
              for (final s in stats)
                SizedBox(
                  width: itemWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedCounter(
                        rawValue: s.value,
                        style: homeSerif(
                          size: 56,
                          color: AzizColors.trueIndigo,
                          height: 1.0,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.label,
                        style: homeSans(
                          size: 14,
                          color: AzizColors.lightTextSecondary,
                          weight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitleWidget extends StatelessWidget {
  final String? titleKey;
  final String? text;
  const _SectionTitleWidget({this.titleKey, this.text});

  @override
  Widget build(BuildContext context) {
    final isMobile = homeIsMobile(context);

    return Semantics(
      header: true,
      child: Text(
        text ?? context.aboutTr(titleKey ?? ''),
        style: homeSerif(
          size: isMobile ? 34 : 48,
          height: 1.08,
          letterSpacing: -0.8,
        ),
      ),
    );
  }
}

class _ParagraphText extends StatelessWidget {
  final String text;
  final bool emphasis;
  final bool secondary;
  final bool center;

  const _ParagraphText({
    required this.text,
    this.emphasis = false,
    this.secondary = false,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    final paragraph = Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: homeSans(
        size: emphasis ? 18 : 16.5,
        color: secondary
            ? AzizColors.lightTextSecondary
            : AzizColors.lightTextPrimary,
        weight: emphasis ? FontWeight.w500 : FontWeight.w400,
        height: 1.85,
      ),
    );
    if (center) return paragraph;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: paragraph,
    );
  }
}

class _HeritageBadgeWidget extends StatelessWidget {
  const _HeritageBadgeWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AzizColors.mat,
        borderRadius: BorderRadius.circular(kHomeRadius),
        border: Border.all(
          color: AzizColors.trueIndigo.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance_outlined,
            size: 18,
            color: AzizColors.trueIndigo,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              context.aboutTr('about.heritage_badge'),
              style: homeSans(
                size: 14,
                color: AzizColors.trueIndigo,
                weight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardModel {
  final IconData icon;
  final String title;
  final String text;
  final String stepNumber;
  const _CardModel({
    required this.icon,
    required this.title,
    required this.text,
    this.stepNumber = '',
  });
}

class _StatModel {
  final String value;
  final String label;
  const _StatModel({required this.value, required this.label});
}

class _TimelineEvent {
  final String year;
  final String title;
  final String description;
  const _TimelineEvent({
    required this.year,
    required this.title,
    required this.description,
  });
}

class _RepresentationSection extends StatelessWidget {
  const _RepresentationSection();

  @override
  Widget build(BuildContext context) {
    final isMobile = homeIsMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 36 : 56),
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: AzizColors.lightBorder),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kHomeRadius),
              border: Border.all(color: AzizColors.lightBorder),
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              size: 28,
              color: AzizColors.trueIndigo,
            ),
          ),
          SizedBox(width: isMobile ? 20 : 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!context.aboutHidden('representation_title'))
                  Text(
                    context.aboutTr('about.representation_title'),
                    style: homeSerif(size: isMobile ? 24 : 30, height: 1.2),
                  ),
                if (_gap(context, ['representation_title'],
                    ['representation_text']))
                  const SizedBox(height: 14),
                if (!context.aboutHidden('representation_text'))
                  Text(
                    context.aboutTr('about.representation_text'),
                    style: homeSerif(
                      size: isMobile ? 18 : 21,
                      color: AzizColors.lightTextSecondary,
                      style: FontStyle.italic,
                      height: 1.6,
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

class _CustomSectionsSection extends StatelessWidget {
  const _CustomSectionsSection();

  @override
  Widget build(BuildContext context) {
    final items = context.aboutList('custom_sections', const []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if ((items[i]['title'] as String? ?? '').trim().isNotEmpty) ...[
            _SectionTitleWidget(text: items[i]['title'] as String),
            const SizedBox(height: 28),
          ],
          if ((items[i]['text'] as String? ?? '').trim().isNotEmpty)
            _ParagraphText(text: items[i]['text'] as String),
          if (i < items.length - 1) const SizedBox(height: 72),
        ],
      ],
    );
  }
}