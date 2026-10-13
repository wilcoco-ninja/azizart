import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config.dart';
import '../../services/media_url_resolver.dart';
import '../../theme/aziz_colors.dart';
import '../../widgets/optimized_image.dart';

// ════════════════════════════════════════════════════════════════════════════
// MISE EN PAGE & POINTS DE RUPTURE
// ════════════════════════════════════════════════════════════════════════════

const double kHomeMaxWidth = 1320;

/// Rayon commun aux boutons et aux cadres : angles presque droits, comme
/// les cartels et les cadres d'un musée.
const double kHomeRadius = 2;

enum HomeBreakpoint { mobile, tablet, desktop }

HomeBreakpoint homeBreakpoint(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return switch (width) {
    < 768 => HomeBreakpoint.mobile,
    < 1024 => HomeBreakpoint.tablet,
    _ => HomeBreakpoint.desktop,
  };
}

bool homeIsMobile(BuildContext context) =>
    homeBreakpoint(context) == HomeBreakpoint.mobile;

bool homeIsTablet(BuildContext context) =>
    homeBreakpoint(context) == HomeBreakpoint.tablet;

bool homeIsDesktop(BuildContext context) =>
    homeBreakpoint(context) == HomeBreakpoint.desktop;

double homeHPad(BuildContext context) {
  return switch (homeBreakpoint(context)) {
    HomeBreakpoint.mobile => 20.0,
    HomeBreakpoint.tablet => 48.0,
    HomeBreakpoint.desktop => 80.0,
  };
}

double homeGutter(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final content = math.min(width - 2 * homeHPad(context), kHomeMaxWidth);
  return (width - content) / 2;
}

/// Espacement horizontal entre deux colonnes côte-à-côte (tablette/desktop).
double homeColumnGap(BuildContext context) {
  return switch (homeBreakpoint(context)) {
    HomeBreakpoint.mobile => 0.0, // jamais utilisé : mise en page verticale
    HomeBreakpoint.tablet => 40.0,
    HomeBreakpoint.desktop => 72.0,
  };
}

int homeGridColumns(double width) {
  if (width >= 1250) return 4;
  if (width >= 900) return 3;
  if (width >= 480) return 2;
  return 1;
}

int homeGridLimit(int columns) {
  switch (columns) {
    case 4:
      return 8;
    case 3:
      return 6;
    case 2:
      return 6;
    default:
      return 4;
  }
}

double homeClamp01(double value) =>
    value < 0.0 ? 0.0 : (value > 1.0 ? 1.0 : value);

// ════════════════════════════════════════════════════════════════════════════
// KEEP-ALIVE — évite la destruction des sections à images lors du scroll
// ════════════════════════════════════════════════════════════════════════════

class KeepAliveSection extends StatefulWidget {
  final Widget child;

  const KeepAliveSection({super.key, required this.child});

  @override
  State<KeepAliveSection> createState() => _KeepAliveSectionState();
}

class _KeepAliveSectionState extends State<KeepAliveSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TYPOGRAPHIE
// ════════════════════════════════════════════════════════════════════════════

TextStyle homeSerif({
  required double size,
  Color color = AzizColors.lightTextPrimary,
  FontWeight weight = FontWeight.w400,
  double height = 1.15,
  double letterSpacing = 0,
  FontStyle style = FontStyle.normal,
}) {
  return TextStyle(
    fontFamily: 'Playfair Display',
    fontSize: size,
    fontWeight: weight,
    fontStyle: style,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );
}

TextStyle homeSans({
  required double size,
  Color color = AzizColors.lightTextSecondary,
  FontWeight weight = FontWeight.w400,
  double height = 1.6,
  double letterSpacing = 0,
  FontStyle style = FontStyle.normal,
}) {
  return TextStyle(
    fontFamily: 'Raleway',
    fontSize: size,
    fontWeight: weight,
    fontStyle: style,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );
}

// ════════════════════════════════════════════════════════════════════════════
// LANGUE
// ════════════════════════════════════════════════════════════════════════════

bool homeIsEn(BuildContext context) =>
    Localizations.maybeLocaleOf(context)?.languageCode == 'en';

String homeText(
  BuildContext context, {
  required String fr,
  required String en,
}) =>
    homeIsEn(context) ? en : fr;

// ════════════════════════════════════════════════════════════════════════════
// CONTACT & RÉSEAUX
// ════════════════════════════════════════════════════════════════════════════

class HomeContact {
  HomeContact._();

  static const String whatsappNumber = '2290166495217';
  static const String whatsappUrl = 'https://wa.me/$whatsappNumber';
  static const String email = 'olga_indigo@yahoo.com';
  static const String emailUrl = 'mailto:$email';
  static const String youtubeUrl = 'https://www.youtube.com/@azizart-color';
  static const String instagramUrl =
      'https://www.instagram.com/indigoolga25?igsh=MTdjbGk1NW80bmtmaw==';
  static const String tiktokUrl = 'https://www.tiktok.com/@olga.indigo';
  static const String facebookUrl =
      'https://www.facebook.com/profile.php?id=100074832580615';

  static String whatsappWith(String message) =>
      '$whatsappUrl?text=${Uri.encodeComponent(message)}';
}

Future<void> homeLaunch(String url) async {
  final uri = Uri.parse(url);
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      debugPrint('Home: launchUrl a échoué pour $uri');
    }
  } catch (e) {
    debugPrint('Home: impossible d\'ouvrir $uri —$e');
  }
}

// ════════════════════════════════════════════════════════════════════════════
// IMAGES — Cloudflare R2 (bucket « azizart-media »)
// ════════════════════════════════════════════════════════════════════════════

/// URL publique du bucket R2 : définie une seule fois dans [AppConfig]
/// (changeable via --dart-define=R2_PUBLIC_URL=...).
const String kR2PublicBaseUrl = AppConfig.r2PublicUrl;

/// URL publique R2 d'une référence d'image (URL, ancienne URL Supabase ou
/// chemin relatif). Vide si la référence est vide ou désigne un asset local.
String resolvePublicUrl(
  String urlOrPath, {
  String? folder,
  @Deprecated('Bucket unique R2 — paramètre ignoré') String? bucket,
}) =>
    MediaUrlResolver.resolve(urlOrPath, folder: folder);

/// Affiche une image publiée (R2) : shimmer pendant le chargement, repli
/// en cas d'erreur, rendu `<img>` natif sur le Web et cache disque ailleurs.
Widget publishedImage(
  String? path, {
  BoxFit fit = BoxFit.cover,
  Alignment alignment = Alignment.center,
  Widget? errorWidget,
  Widget? placeholder,
  double? width,
  double? height,
  BorderRadius? borderRadius,
  int? memCacheWidth,
  String? folder,
  @Deprecated('Bucket unique R2 — paramètre ignoré') String? bucket,
}) {
  return OptimizedImage(
    url: path,
    folder: folder,
    fit: fit,
    alignment: alignment,
    errorWidget: errorWidget,
    placeholder: placeholder,
    width: width,
    height: height,
    borderRadius: borderRadius,
    memCacheWidth: memCacheWidth,
  );
}

// ════════════════════════════════════════════════════════════════════════════
// BANDES, TITRES
// ════════════════════════════════════════════════════════════════════════════

class HomeBand extends StatelessWidget {
  final Color color;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Widget? background;

  const HomeBand({
    super.key,
    required this.color,
    required this.child,
    this.padding,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (padding != null) {
      content = Padding(padding: padding!, child: child);
    } else {
      final verticalPad = switch (homeBreakpoint(context)) {
        HomeBreakpoint.mobile => 64.0,
        HomeBreakpoint.tablet => 88.0,
        HomeBreakpoint.desktop => 120.0,
      };
      content = Padding(
        padding: EdgeInsets.symmetric(
          horizontal: homeHPad(context),
          vertical: verticalPad,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kHomeMaxWidth),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      );
    }

    return ColoredBox(
      color: color,
      child: background == null
          ? content
          : Stack(
              fit: StackFit.passthrough,
              children: [
                Positioned.fill(child: background!),
                content,
              ],
            ),
    );
  }
}

class SectionTag extends StatelessWidget {
  final String label;
  final bool onDark;

  const SectionTag(this.label, {super.key, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final color = onDark
        ? AzizColors.lightBackground.withValues(alpha: 0.78)
        : AzizColors.trueIndigo;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 24, height: 1, color: color.withValues(alpha: 0.6)),
        const SizedBox(width: 10),
        Text(
          label,
          style: homeSans(
            size: 13,
            color: color,
            weight: FontWeight.w600,
            letterSpacing: 0.4,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class HomeHeading extends StatelessWidget {
  final String tag;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool onDark;
  final CrossAxisAlignment align;

  const HomeHeading({
    super.key,
    this.tag = '',
    required this.title,
    this.subtitle,
    this.trailing,
    this.onDark = false,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = homeIsMobile(context);
    final centered = align == CrossAxisAlignment.center;
    final titleColor =
        onDark ? AzizColors.lightBackground : AzizColors.lightTextPrimary;
    final subtitleColor = onDark
        ? AzizColors.lightBackground.withValues(alpha: 0.74)
        : AzizColors.lightTextSecondary;
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    final titleSize = switch (homeBreakpoint(context)) {
      HomeBreakpoint.mobile => 34.0,
      HomeBreakpoint.tablet => 46.0,
      HomeBreakpoint.desktop => 58.0,
    };

    final heading = Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (tag.isNotEmpty) ...[
          SectionTag(tag, onDark: onDark),
          const SizedBox(height: 18),
        ],
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: homeSerif(
              size: titleSize,
              color: titleColor,
              height: 1.06,
              letterSpacing: -0.8,
            ),
          ),
        ),
        if (hasSubtitle) ...[
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              subtitle!,
              textAlign: centered ? TextAlign.center : TextAlign.start,
              style: homeSans(
                size: isMobile ? 15 : 16,
                color: subtitleColor,
                height: 1.7,
              ),
            ),
          ),
        ],
      ],
    );

    if (trailing == null || isMobile) return heading;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: heading),
        const SizedBox(width: 24),
        trailing!,
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CADRE D'ŒUVRE (passe-partout)
// ════════════════════════════════════════════════════════════════════════════

/// Pose une œuvre sur un passe-partout blanc, comme au mur d'une galerie :
/// l'image n'est jamais recadrée (utiliser `BoxFit.contain` à l'intérieur).
class HomeMat extends StatelessWidget {
  final Widget child;
  final double padding;
  final Color color;
  final bool raised;

  const HomeMat({
    super.key,
    required this.child,
    this.padding = 12,
    this.color = Colors.white,
    this.raised = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: AzizColors.lightBorder.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: raised ? 0.16 : 0.07),
            blurRadius: raised ? 28 : 14,
            offset: Offset(0, raised ? 16 : 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BOUTONS
// ════════════════════════════════════════════════════════════════════════════

/// Hauteur minimale commune à TOUS les boutons pleins / contour : deux
/// boutons côte à côte ont exactement la même hauteur visuelle.
const double kHomeBtnHeight = 48;

/// Côté de la boîte carrée dans laquelle toute icône de bouton est dessinée.
const double kHomeBtnIconBox = 20;

/// Taille des icônes des boutons ronds / carrés (flèches, réseaux sociaux).
const double kHomeSocialIconBox = 20;

/// Dessine n'importe quelle icône dans une boîte carrée fixe (les glyphes de
/// largeurs différentes paraissent ainsi de la même taille).
class HomeIconBox extends StatelessWidget {
  final Widget child;
  final double box;

  const HomeIconBox({
    super.key,
    required this.child,
    this.box = kHomeBtnIconBox,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: box,
      height: box,
      child: Center(child: child),
    );
  }
}

/// Jeu d'icônes unique du site (Material arrondi, police intégrée à Flutter).
///
/// Chaque icône dit ce que fait le bouton :
///   • [arrow]     aller à une autre page du site (flèche vers l'avant)
///   • [external]  ouvrir un site externe (flèche sortante)
///   • [gallery]   parcourir la collection
///   • [studio]    découvrir l'atelier
///   • [viewLarge] agrandir une œuvre
///   • [inquire]   poser une question sur une œuvre
class HomeIcons {
  HomeIcons._();

  // Réseaux & contact
  static const IconData whatsapp = Icons.chat_rounded;
  static const IconData youtube = Icons.play_circle_rounded;
  static const IconData instagram = Icons.photo_camera_rounded;
  static const IconData tiktok = Icons.music_note_rounded;
  static const IconData facebook = Icons.facebook_rounded;
  static const IconData email = Icons.mail_rounded;

  // Navigation
  static const IconData arrow = Icons.arrow_forward_rounded;
  static const IconData external = Icons.arrow_outward_rounded;
  static const IconData back = Icons.chevron_left_rounded;
  static const IconData next = Icons.chevron_right_rounded;

  // Actions
  static const IconData gallery = Icons.grid_view_rounded;
  static const IconData studio = Icons.palette_outlined;
  static const IconData viewLarge = Icons.open_in_full_rounded;
  static const IconData inquire = Icons.chat_bubble_outline_rounded;
  static const IconData artist = Icons.person_outline_rounded;

  // Techniques & divers
  static const IconData brush = Icons.brush_rounded;
  static const IconData dye = Icons.water_drop_rounded;
  static const IconData fire = Icons.local_fire_department_rounded;
  static const IconData admin = Icons.shield_moon_rounded;
}

Widget _buttonRow({
  required String label,
  required TextStyle style,
  required Color iconColor,
  Widget? leading,
  Widget? trailing,
}) {
  final iconTheme = IconThemeData(color: iconColor, size: kHomeBtnIconBox);
  return Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (leading != null) ...[
        IconTheme(data: iconTheme, child: HomeIconBox(child: leading)),
        const SizedBox(width: 10),
      ],
      Flexible(
        child: Text(label, textAlign: TextAlign.center, style: style),
      ),
      if (trailing != null) ...[
        const SizedBox(width: 10),
        IconTheme(data: iconTheme, child: HomeIconBox(child: trailing)),
      ],
    ],
  );
}

/// Bouton principal : aplat de couleur, angles droits, sans lueur.
class HeroBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;

  const HeroBtn({
    super.key,
    required this.label,
    required this.onTap,
    this.leading,
    this.trailing,
  });

  @override
  State<HeroBtn> createState() => _HeroBtnState();
}

class _HeroBtnState extends State<HeroBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(kHomeRadius);

    return Semantics(
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _hovered ? AzizColors.saffronLight : AzizColors.saffron,
          borderRadius: radius,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onTap,
            onHover: (value) => setState(() => _hovered = value),
            hoverColor: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kHomeBtnHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buttonRow(
                  label: widget.label,
                  leading: widget.leading,
                  trailing: widget.trailing,
                  iconColor: AzizColors.textOnAccent,
                  style: homeSans(
                    size: 14.5,
                    color: AzizColors.textOnAccent,
                    weight: FontWeight.w700,
                    letterSpacing: 0.2,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton secondaire : simple filet, même hauteur que [HeroBtn].
class GhostBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool filled;
  final Widget? leading;
  final Widget? trailing;

  const GhostBtn({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AzizColors.trueIndigo,
    this.filled = false,
    this.leading,
    this.trailing,
  });

  @override
  State<GhostBtn> createState() => _GhostBtnState();
}

class _GhostBtnState extends State<GhostBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final radius = BorderRadius.circular(kHomeRadius);
    final Color background;
    if (widget.filled) {
      background = _hovered ? color.withValues(alpha: 0.88) : color;
    } else {
      background = _hovered ? color.withValues(alpha: 0.08) : Colors.transparent;
    }
    final borderColor = widget.filled
        ? Colors.transparent
        : color.withValues(alpha: _hovered ? 0.95 : 0.55);
    final textColor = widget.filled ? Colors.white : color;

    return Semantics(
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          border: Border.all(color: borderColor),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onTap,
            onHover: (value) => setState(() => _hovered = value),
            hoverColor: Colors.transparent,
            child: ConstrainedBox(
              // -2 : la bordure de 1 px est dessinée à l'extérieur, la
              // hauteur totale reste donc égale à celle de HeroBtn.
              constraints:
                  const BoxConstraints(minHeight: kHomeBtnHeight - 2),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 23),
                child: _buttonRow(
                  label: widget.label,
                  leading: widget.leading,
                  trailing: widget.trailing,
                  iconColor: textColor,
                  style: homeSans(
                    size: 14.5,
                    color: textColor,
                    weight: FontWeight.w600,
                    letterSpacing: 0.2,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lien textuel avec flèche vers l'avant (navigation interne).
class TextLinkBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const TextLinkBtn({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AzizColors.trueIndigo,
  });

  @override
  State<TextLinkBtn> createState() => _TextLinkBtnState();
}

class _TextLinkBtnState extends State<TextLinkBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (value) => setState(() => _hovered = value),
          borderRadius: BorderRadius.circular(kHomeRadius),
          hoverColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: homeSans(
                        size: 14.5,
                        color: widget.color,
                        weight: FontWeight.w600,
                        letterSpacing: 0.2,
                        height: 1.2,
                      ).copyWith(
                        decoration: _hovered
                            ? TextDecoration.underline
                            : TextDecoration.none,
                        decorationColor: widget.color,
                        decorationThickness: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 180),
                      offset: Offset(_hovered ? 0.25 : 0.0, 0.0),
                      child: Icon(
                        HomeIcons.arrow,
                        size: 18,
                        color: widget.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton carré à icône seule (précédent / suivant, réseaux sociaux).
/// Zone tactile de 44 px minimum.
class HomeCircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final bool onDark;
  final double size;

  const HomeCircleBtn({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.onDark = false,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final foreground =
        onDark ? AzizColors.lightBackground : AzizColors.trueIndigo;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kHomeRadius),
      side: BorderSide(color: foreground.withValues(alpha: 0.3)),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: Tooltip(
        message: semanticLabel,
        child: Material(
          color: onDark
              ? Colors.white.withValues(alpha: 0.06)
              : AzizColors.lightBackground,
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: Icon(
                  icon,
                  size: kHomeSocialIconBox,
                  color:
                      enabled ? foreground : foreground.withValues(alpha: 0.32),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// RAIL HORIZONTAL — accepte children OU itemCount/itemBuilder
// ════════════════════════════════════════════════════════════════════════════

class HomeRail extends StatefulWidget {
  final double? height;
  final int? itemCount;
  final IndexedWidgetBuilder? itemBuilder;
  final List<Widget>? children;
  final double gap;

  const HomeRail({
    super.key,
    this.height,
    this.itemCount,
    this.itemBuilder,
    this.children,
    this.gap = 20,
  }) : assert(
          children != null || (itemCount != null && itemBuilder != null),
          'HomeRail : fournir soit `children`, soit `itemCount`+`itemBuilder`.',
        );

  @override
  State<HomeRail> createState() => _HomeRailState();
}

class _HomeRailState extends State<HomeRail> {
  final ScrollController _controller = ScrollController();
  bool _canBack = false;
  bool _canForward = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncArrows);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncArrows);
    _controller.dispose();
    super.dispose();
  }

  void _syncArrows() {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    if (!position.hasContentDimensions) return;
    final back = position.pixels > 8;
    final forward = position.pixels < position.maxScrollExtent - 8;
    if (back != _canBack || forward != _canForward) {
      setState(() {
        _canBack = back;
        _canForward = forward;
      });
    }
  }

  void _scrollBy(int direction) {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final target = math.max(
      0.0,
      math.min(
        position.pixels + direction * position.viewportDimension * 0.8,
        position.maxScrollExtent,
      ),
    );
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gutter = homeGutter(context);
    final showArrows = !homeIsMobile(context);

    WidgetsBinding.instance.addPostFrameCallback((_) => _syncArrows());

    final Widget list = widget.children != null
        ? ListView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: gutter),
            children: widget.children!,
          )
        : ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: gutter),
            itemCount: widget.itemCount!,
            separatorBuilder: (_, _) => SizedBox(width: widget.gap),
            itemBuilder: widget.itemBuilder!,
          );

    final stack = Stack(
      children: [
        Positioned.fill(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: const {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
              scrollbars: false,
            ),
            child: list,
          ),
        ),
        if (showArrows && _canBack)
          Positioned(
            left: math.max(8.0, gutter - 24),
            top: 0,
            bottom: 0,
            child: Center(
              child: HomeCircleBtn(
                icon: HomeIcons.back,
                semanticLabel:
                    homeText(context, fr: 'Précédent', en: 'Previous'),
                onTap: () => _scrollBy(-1),
              ),
            ),
          ),
        if (showArrows && _canForward)
          Positioned(
            right: math.max(8.0, gutter - 24),
            top: 0,
            bottom: 0,
            child: Center(
              child: HomeCircleBtn(
                icon: HomeIcons.next,
                semanticLabel: homeText(context, fr: 'Suivant', en: 'Next'),
                onTap: () => _scrollBy(1),
              ),
            ),
          ),
      ],
    );

    if (widget.height == null) return stack;
    return SizedBox(height: widget.height, child: stack);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TEXTURE BATIK
// ════════════════════════════════════════════════════════════════════════════

class BatikTexture extends StatelessWidget {
  final Color color;
  final double opacity;
  final int seed;

  const BatikTexture({
    super.key,
    this.color = const Color(0xFF9DB4D8),
    this.opacity = 0.11,
    this.seed = 5,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          isComplex: true,
          willChange: false,
          painter: _BatikCracklePainter(
            color: color.withValues(alpha: opacity),
            seed: seed,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _BatikCracklePainter extends CustomPainter {
  final Color color;
  final int seed;

  const _BatikCracklePainter({required this.color, required this.seed});

  static const double _space = 1600;
  // Cellule plus large : ~40 % de calcul en moins au premier affichage,
  // important sur les vieux téléphones.
  static const double _cell = 72;
  static final Map<int, List<List<Offset>>> _cache = {};

  static List<List<Offset>> _network(int seed) =>
      _cache.putIfAbsent(seed, () => _buildNetwork(seed));

  static List<List<Offset>> _buildNetwork(int seed) {
    final random = math.Random(seed);
    const jitter = 0.95;
    const skip = 0.3;
    const wobble = 1.6;

    final n = (_space / _cell).ceil() + 2;
    final count = n + 4;
    final points = List<Offset>.generate(count * count, (k) {
      final i = k ~/ count - 2;
      final j = k % count - 2;
      return Offset(
        (i + 0.5 + (random.nextDouble() - 0.5) * jitter) * _cell,
        (j + 0.5 + (random.nextDouble() - 0.5) * jitter) * _cell,
      );
    });
    Offset pointAt(int i, int j) => points[(i + 2) * count + (j + 2)];

    final lines = <List<Offset>>[];
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        final p = pointAt(i, j);
        const reach = _cell * 2.5;
        var polygon = <Offset>[
          Offset(p.dx - reach, p.dy - reach),
          Offset(p.dx + reach, p.dy - reach),
          Offset(p.dx + reach, p.dy + reach),
          Offset(p.dx - reach, p.dy + reach),
        ];

        for (var di = -2; di <= 2 && polygon.isNotEmpty; di++) {
          for (var dj = -2; dj <= 2 && polygon.isNotEmpty; dj++) {
            if (di == 0 && dj == 0) continue;
            final q = pointAt(i + di, j + dj);
            polygon = _clip(
              polygon,
              Offset((p.dx + q.dx) / 2, (p.dy + q.dy) / 2),
              Offset(q.dx - p.dx, q.dy - p.dy),
            );
          }
        }

        for (var k = 0; k < polygon.length; k++) {
          if (random.nextDouble() < skip) continue;
          final a = polygon[k];
          final b = polygon[(k + 1) % polygon.length];
          final middle = Offset(
            (a.dx + b.dx) / 2 + (random.nextDouble() - 0.5) * wobble * 2,
            (a.dy + b.dy) / 2 + (random.nextDouble() - 0.5) * wobble * 2,
          );
          lines.add(<Offset>[a, middle, b]);
        }
      }
    }
    return lines;
  }

  static List<Offset> _clip(List<Offset> polygon, Offset middle, Offset normal) {
    final output = <Offset>[];
    for (var k = 0; k < polygon.length; k++) {
      final a = polygon[k];
      final b = polygon[(k + 1) % polygon.length];
      final sideA =
          (a.dx - middle.dx) * normal.dx + (a.dy - middle.dy) * normal.dy;
      final sideB =
          (b.dx - middle.dx) * normal.dx + (b.dy - middle.dy) * normal.dy;
      if (sideA <= 0) output.add(a);
      if ((sideA <= 0) != (sideB <= 0)) {
        final t = sideA / (sideA - sideB);
        output.add(Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t));
      }
    }
    return output;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale = math.max(size.longestSide / _space, 0.75);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    final path = Path();
    for (final line in _network(seed)) {
      path.moveTo(line[0].dx * scale, line[0].dy * scale);
      for (var i = 1; i < line.length; i++) {
        path.lineTo(line[i].dx * scale, line[i].dy * scale);
      }
    }

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BatikCracklePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.seed != seed;
}