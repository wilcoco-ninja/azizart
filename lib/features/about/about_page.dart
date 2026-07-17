import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/language_provider.dart';
import '../../theme/aziz_colors.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PAGE PRINCIPALE : ABOUT (Optimisée pour l'accessibilité multi-générationnelle)
// ═══════════════════════════════════════════════════════════════════════════

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile
              ? 24
              : width * 0.10, // Augmentation douce des marges desktop
          vertical: 40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const FadeSlideIn(delay: Duration.zero, child: _AboutHero()),
            const SizedBox(height: 56),
            const FadeSlideIn(
              delay: Duration(milliseconds: 150),
              child: _IntroTextSection(),
            ),
            const SizedBox(height: 72),
            const FadeSlideIn(
              delay: Duration(milliseconds: 250),
              child: _StorySection(),
            ),
            const SizedBox(height: 64),
            const FadeSlideIn(
              delay: Duration(milliseconds: 300),
              child: _QuoteBlockSection(),
            ),
            const SizedBox(height: 72),
            const FadeSlideIn(
              delay: Duration(milliseconds: 350),
              child: _TechniqueShowcase(),
            ),
            const SizedBox(height: 72),
            const FadeSlideIn(
              delay: Duration(milliseconds: 400),
              child: _NaturalIngredientsSection(),
            ),
            const SizedBox(height: 72),
            const FadeSlideIn(
              delay: Duration(milliseconds: 450),
              child: _TimelineSection(),
            ),
            const SizedBox(height: 72),
            FadeSlideIn(
              delay: const Duration(milliseconds: 500),
              child: _StatsDashboard(isMobile: isMobile),
            ),
            const SizedBox(height: 64),
            const FadeSlideIn(
              delay: Duration(milliseconds: 550),
              child: _RepresentationSection(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGET UTILITAIRE : Animation d'entrée
// ═══════════════════════════════════════════════════════════════════════════

class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const FadeSlideIn({
    super.key,
    required this.child,
    required this.delay,
    this.duration = const Duration(
        milliseconds: 700), // Légèrement ralenti pour plus de douceur visuelle
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
      begin: const Offset(0,
          0.04), // Animation plus subtile (évite le mal des transports visuel)
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

// ═══════════════════════════════════════════════════════════════════════════
// WIDGET UTILITAIRE : Carte avec effet Hover moderne
// ═══════════════════════════════════════════════════════════════════════════

class HoverCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final double height;
  final bool fixedHeight;

  const HoverCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(32), // Espace intérieur augmenté
    this.height = 280,
    this.fixedHeight = true,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: widget.fixedHeight ? widget.height : null,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: _isHovered
              ? AzizColors.surface
              : AzizColors.card.withValues(alpha: 0.7),
          borderRadius:
              BorderRadius.circular(20), // Bords plus arrondis et chaleureux
          border: Border.all(
            color: _isHovered
                ? AzizColors.gold.withValues(alpha: 0.6)
                : AzizColors.divider.withValues(alpha: 0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? AzizColors.gold.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: _isHovered ? 24 : 12,
              offset: _isHovered ? const Offset(0, 8) : const Offset(0, 4),
            )
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGET UTILITAIRE : Compteur animé
// ═══════════════════════════════════════════════════════════════════════════

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

  late final double _targetNumber;
  late final String _prefix;
  late final String _suffix;

  @override
  void initState() {
    super.initState();
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

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.fastOutSlowIn);

    Future.delayed(const Duration(milliseconds: 500), () {
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
    if (_targetNumber < 0) {
      return Text(widget.rawValue, style: widget.style);
    }
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final current = (_anim.value * _targetNumber).round();
        return Text('$_prefix$current$_suffix', style: widget.style);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COMPOSANT : Hero plein cadre optimisé pour le contraste textuel
// ═══════════════════════════════════════════════════════════════════════════

class _AboutHero extends StatelessWidget {
  const _AboutHero();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;
    final heroHeight = isMobile ? 460.0 : 620.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: heroHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/portrait.jpeg',
              fit: BoxFit.cover,
              alignment: const Alignment(
                  0, -0.2), // Recadrage intelligent sur le visage
              errorBuilder: (_, __, ___) => const _PortraitFallback(),
            ),
            // Double voile de lisibilité pour garantir l'accessibilité WCAG du texte
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                  stops: const [0.0, 0.4, 0.75, 1.0],
                ),
              ),
            ),
            Positioned(
              top: isMobile ? 24 : 36,
              left: isMobile ? 24 : 40,
              child: const _HeritageBadgeWidget(),
            ),
            Positioned(
              left: isMobile ? 24 : 48,
              right: isMobile ? 24 : 48,
              bottom: isMobile ? 28 : 44,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('about.title').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      letterSpacing: 7,
                      fontWeight: FontWeight.w700,
                      color: AzizColors.gold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('about.name'),
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: isMobile ? 38 : 58,
                      color: Colors
                          .white, // Forcé en blanc pour un contraste absolu sur fond sombre
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('about.heritage'),
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: isMobile ? 16 : 20,
                      color: AzizColors.gold.withValues(alpha: 0.9),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortraitFallback extends StatelessWidget {
  const _PortraitFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AzizColors.card,
      alignment: Alignment.center,
      child: Icon(
        Icons.brush_outlined,
        size: 72,
        color: AzizColors.gold.withValues(alpha: 0.4),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COMPOSANT : Introduction textuelle
// ═══════════════════════════════════════════════════════════════════════════

class _IntroTextSection extends StatelessWidget {
  const _IntroTextSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment
              .start, // Toujours à gauche pour maximiser l'accessibilité
          children: [
            Text(
              context.tr('about.intro_title'),
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: isMobile ? 24 : 30,
                color: AzizColors.gold,
                fontStyle: FontStyle.italic,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            _ParagraphText(
                text: context.tr('about.intro_text'), emphasis: true),
            const SizedBox(height: 20),
            _ParagraphText(
                text: context.tr('about.intro_text2'), secondary: true),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COMPOSANT : Section Histoire / Origines
// ═══════════════════════════════════════════════════════════════════════════

class _StorySection extends StatelessWidget {
  const _StorySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitleWidget(titleKey: 'about.origins_title'),
        const SizedBox(height: 28),
        _ParagraphText(text: context.tr('about.origins_text1')),
        const SizedBox(height: 20),
        _ParagraphText(text: context.tr('about.origins_text2')),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COMPOSANT : Bloc de citation artistique
// ═══════════════════════════════════════════════════════════════════════════

class _QuoteBlockSection extends StatelessWidget {
  const _QuoteBlockSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 44),
      decoration: BoxDecoration(
        color: AzizColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AzizColors.gold.withValues(alpha: 0.25)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -35,
            child: Text(
              '❞',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 130,
                color: AzizColors.gold.withValues(alpha: 0.06),
                height: 1,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '« ${context.tr('about.grandma_quote')} »',
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 19,
                  color: AzizColors.textPrimary,
                  height: 1.8,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(width: 40, height: 1.5, color: AzizColors.gold),
                  const SizedBox(width: 16),
                  Text(
                    context.tr('about.grandma_author'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AzizColors.gold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COMPOSANT : Savoir-Faire (Batik)
// ═══════════════════════════════════════════════════════════════════════════

class _TechniqueShowcase extends StatelessWidget {
  const _TechniqueShowcase();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 980;

    final steps = [
      _CardModel(
        icon: Icons.water_drop_outlined,
        title: context.tr('about.step1_title'),
        text: context.tr('about.step1_text'),
        stepNumber: '01',
      ),
      _CardModel(
        icon: Icons.color_lens_outlined,
        title: context.tr('about.step2_title'),
        text: context.tr('about.step2_text'),
        stepNumber: '02',
      ),
      _CardModel(
        icon: Icons.auto_fix_high_outlined,
        title: context.tr('about.step3_title'),
        text: context.tr('about.step3_text'),
        stepNumber: '03',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitleWidget(titleKey: 'about.art_title'),
        const SizedBox(height: 28),
        _ParagraphText(text: context.tr('about.art_text1')),
        const SizedBox(height: 20),
        _ParagraphText(text: context.tr('about.art_text2')),
        const SizedBox(height: 44),
        isCompact
            ? Column(
                children: steps
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _TechniqueCard(data: s, isFullWidth: true),
                        ))
                    .toList(),
              )
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: steps
                      .map((s) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child:
                                  _TechniqueCard(data: s, isFullWidth: false),
                            ),
                          ))
                      .toList(),
                ),
              ),
      ],
    );
  }
}

class _TechniqueCard extends StatelessWidget {
  final _CardModel data;
  final bool isFullWidth;

  const _TechniqueCard({required this.data, required this.isFullWidth});

  @override
  Widget build(BuildContext context) {
    return HoverCard(
      fixedHeight: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AzizColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: AzizColors.gold, size: 32),
              ),
              Text(
                data.stepNumber,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AzizColors.gold.withValues(alpha: 0.25),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            data.title,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 19,
              color: AzizColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.text,
            style: const TextStyle(
              fontSize: 14.5,
              color: AzizColors.textSecondary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// COMPOSANT : Teintures Naturelles
// ═══════════════════════════════════════════════════════════════════════════

class _NaturalIngredientsSection extends StatelessWidget {
  const _NaturalIngredientsSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width < 900;

    final dyes = [
      _CardModel(
          icon: Icons.spa_outlined,
          title: context.tr('about.indigo_title'),
          text: context.tr('about.indigo_text')),
      _CardModel(
          icon: Icons.forest_outlined,
          title: context.tr('about.cola_title'),
          text: context.tr('about.cola_text')),
      _CardModel(
          icon: Icons.park_outlined,
          title: context.tr('about.baobab_title'),
          text: context.tr('about.baobab_text')),
      _CardModel(
          icon: Icons.eco_outlined,
          title: context.tr('about.teck_title'),
          text: context.tr('about.teck_text')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitleWidget(titleKey: 'about.dyes_title'),
        const SizedBox(height: 36),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          children: dyes.map((item) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: isTablet
                    ? double.infinity
                    : (width - width * 0.20 - 24) / 2,
                maxWidth: isTablet
                    ? double.infinity
                    : (width - width * 0.20 - 24) / 2,
              ),
              child: _DyeCard(item: item),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DyeCard extends StatelessWidget {
  final _CardModel item;
  const _DyeCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AzizColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AzizColors.gold.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(
                  75, 0, 130, 0.08), // Rappel subtil de l'Indigo
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: AzizColors.gold, size: 26),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AzizColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AzizColors.textSecondary,
                    height: 1.65,
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

// ═══════════════════════════════════════════════════════════════════════════
// COMPOSANT : Chronologie visuelle améliorée pour un scan rapide
// ═══════════════════════════════════════════════════════════════════════════

class _TimelineSection extends StatelessWidget {
  const _TimelineSection();

  @override
  Widget build(BuildContext context) {
    final events = [
      _TimelineEvent(
        year: context.tr('about.timeline_year1'),
        title: context.tr('about.timeline_title1'),
        description: context.tr('about.timeline_desc1'),
        icon: Icons.celebration_outlined,
      ),
      _TimelineEvent(
        year: context.tr('about.timeline_year2'),
        title: context.tr('about.timeline_title2'),
        description: context.tr('about.timeline_desc2'),
        icon: Icons.flight_takeoff_outlined,
      ),
      _TimelineEvent(
        year: context.tr('about.timeline_year3'),
        title: context.tr('about.timeline_title3'),
        description: context.tr('about.timeline_desc3'),
        icon: Icons.map_outlined,
      ),
      _TimelineEvent(
        year: context.tr('about.timeline_year4'),
        title: context.tr('about.timeline_title4'),
        description: context.tr('about.timeline_desc4'),
        icon: Icons.home_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitleWidget(titleKey: 'about.timeline_title'),
        const SizedBox(height: 48),
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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Année stylisée sous forme de badge fixe
          SizedBox(
            width: 80,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                event.year,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AzizColors.gold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Colonne vertébrale graphique de la ligne temporelle
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AzizColors.card,
                  border: Border.all(color: AzizColors.gold, width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: AzizColors.gold.withValues(alpha: 0.1),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Icon(event.icon, size: 18, color: AzizColors.gold),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: AzizColors.gold.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 24),
          // Contenu textuel de l'événement
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 12 : 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AzizColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AzizColors.textSecondary,
                      height: 1.7,
                    ),
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

// ═══════════════════════════════════════════════════════════════════════════
// COMPOSANT : Tableau de Bord des Statistiques
// ═══════════════════════════════════════════════════════════════════════════

class _StatsDashboard extends StatelessWidget {
  final bool isMobile;
  const _StatsDashboard({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatModel(
          value: context.tr('about.stat_aho'),
          label: context.tr('about.stat_aho_label')),
      _StatModel(
          value: context.tr('about.stat_dyes'),
          label: context.tr('about.stat_dyes_label')),
      _StatModel(
          value: context.tr('about.stat_handmade'),
          label: context.tr('about.stat_handmade_label')),
      _StatModel(
          value: context.tr('about.stat_heritage'),
          label: context.tr('about.stat_heritage_label')),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AzizColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AzizColors.divider.withValues(alpha: 0.6)),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 44,
        alignment: WrapAlignment.spaceEvenly,
        children: stats.map((s) {
          return SizedBox(
            width: isMobile ? 150 : 200,
            child: Column(
              children: [
                AnimatedCounter(
                  rawValue: s.value,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: AzizColors.gold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  s.label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AzizColors.textSecondary,
                    letterSpacing: 1.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGET COMPAGNON : Titre de Section Typographique
// ═══════════════════════════════════════════════════════════════════════════

class _SectionTitleWidget extends StatelessWidget {
  final String titleKey;
  const _SectionTitleWidget({required this.titleKey});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(titleKey),
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AzizColors.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 64,
          height: 3.0,
          decoration: BoxDecoration(
            color: AzizColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGET COMPAGNON : Paragraphe Universel (Optimisé Accessibilité)
// ═══════════════════════════════════════════════════════════════════════════

class _ParagraphText extends StatelessWidget {
  final String text;
  final bool emphasis;
  final bool secondary;

  const _ParagraphText({
    required this.text,
    this.emphasis = false,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign
          .start, // UX Correction: Changé de 'justify' à 'start' pour éviter la fatigue cognitive/visuelle
      style: TextStyle(
        fontSize: emphasis
            ? 18.0
            : 16.5, // Légère augmentation de la taille pour toutes les tranches d'âges
        fontWeight: emphasis ? FontWeight.w500 : FontWeight.w400,
        color: secondary ? AzizColors.textSecondary : AzizColors.textPrimary,
        height:
            1.8, // Espacement parfait (Golden Ratio textuel) pour le parcours fluide des yeux
        letterSpacing: 0.2,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGET COMPAGNON : Badge Patrimoine
// ═══════════════════════════════════════════════════════════════════════════

class _HeritageBadgeWidget extends StatelessWidget {
  const _HeritageBadgeWidget();

  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(
              alpha:
                  0.4), // Fond sombre uniforme pour garantir la lisibilité sur l'image
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AzizColors.gold.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_outlined,
                size: 16, color: AzizColors.gold),
            const SizedBox(width: 10),
            Text(
              context.tr('about.heritage_badge'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AzizColors.gold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODÈLES DE DONNÉES LOCAUX
// ═══════════════════════════════════════════════════════════════════════════

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
  final IconData icon;
  const _TimelineEvent({
    required this.year,
    required this.title,
    required this.description,
    required this.icon,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// COMPOSANT : Représentation — Galerie SAGA
// ═══════════════════════════════════════════════════════════════════════════

class _RepresentationSection extends StatelessWidget {
  const _RepresentationSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AzizColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AzizColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AzizColors.gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.business_outlined,
              color: AzizColors.gold,
              size: 28,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('about.representation_title').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w800,
                    color: AzizColors.gold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr('about.representation_text'),
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 16,
                    color: AzizColors.textPrimary,
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
