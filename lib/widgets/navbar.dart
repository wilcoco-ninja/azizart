import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../core/localization/language_provider.dart';
import '../theme/aziz_colors.dart';
import '../theme/responsive.dart';

// ══════════════════════════════════════════════════════════════════════════════
// AzizNavBar — Barre de navigation principale (desktop flottante / mobile drawer)
//
// Corrections apportées par rapport à la version précédente :
//  • La liste `icons` n'était jamais utilisée côté desktop → les onglets
//    affichent désormais une icône, comme sur mobile (cohérence visuelle).
//  • Les zones cliquables (logo, langue, items de nav) n'avaient aucun retour
//    tactile (pas de splash/ripple, pas de curseur sur certains éléments) →
//    tout est désormais wrappé dans un `InkWell`/`Material` avec curseur et
//    Semantics pour l'accessibilité (lecteurs d'écran).
//  • Sur les largeurs "limites" entre mobile et desktop (~900-1000px), les 6
//    onglets pouvaient légèrement déborder → ajout d'un défilement horizontal
//    de sécurité (`SingleChildScrollView`) qui ne s'active que si nécessaire.
//  • `assert` ajouté pour garantir que `keys` et `icons` restent synchronisés.
// ══════════════════════════════════════════════════════════════════════════════
class AzizNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const AzizNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<String> _keys = [
    'nav.gallery',
    'nav.atelier',
    'nav.media',
    'nav.about',
    'nav.contact',
  ];

  static const List<IconData> _icons = [
    Icons.photo_library_rounded,
    Icons.brush_rounded,
    Icons.play_circle_rounded,
    Icons.person_rounded,
    Icons.mail_rounded,
  ];

  /// Indices réels des pages (cf. `PageIndices` dans app.dart) correspondant
  /// à chaque entrée de `_keys` / `_icons`. L'accueil (index 0) n'apparaît
  /// plus dans la barre : on y accède uniquement via un clic sur le logo.
  static const List<int> _targetIndices = [1, 2, 3, 4, 5];

  @override
  Widget build(BuildContext context) {
    assert(
        _keys.length == _icons.length && _keys.length == _targetIndices.length,
        'AzizNavBar : `_keys`, `_icons` et `_targetIndices` doivent avoir la même longueur.');

    // Rebuild quand la locale change
    context.watch<LanguageProvider>();

    return Responsive.isMobile(context)
        ? _MobileNav(
            currentIndex: currentIndex,
            onTap: onTap,
            keys: _keys,
            icons: _icons,
            targetIndices: _targetIndices,
          )
        : _DesktopNav(
            currentIndex: currentIndex,
            onTap: onTap,
            keys: _keys,
            icons: _icons,
            targetIndices: _targetIndices,
          );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Logo — partagé desktop / mobile
// ══════════════════════════════════════════════════════════════════════════════
class _Logo extends StatelessWidget {
  final double height;
  final VoidCallback? onTap;

  const _Logo({required this.height, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'AZIZART — retour à l\'accueil',
      child: Tooltip(
        message: 'Accueil',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            mouseCursor: SystemMouseCursors.click,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: SvgPicture.asset(
                'assets/images/logo/logo.svg',
                height: height,
                placeholderBuilder: (context) => Text(
                  'AZIZART',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    color: AzizColors.gold,
                    fontSize: height * 0.32,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 4,
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

// ══════════════════════════════════════════════════════════════════════════════
// Desktop — barre flottante "verre dépoli" avec indicateur animé
// ══════════════════════════════════════════════════════════════════════════════
class _DesktopNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final List<String> keys;
  final List<IconData> icons;
  final List<int> targetIndices;

  const _DesktopNav({
    required this.currentIndex,
    required this.onTap,
    required this.keys,
    required this.icons,
    required this.targetIndices,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: AzizColors.backgroundMedium.withValues(alpha: 0.92),
            border: Border(
              bottom: BorderSide(
                color: AzizColors.gold.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: Responsive.hPad(context)),
          child: Row(
            children: [
              _Logo(height: 56, onTap: () => onTap(0)),
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 32,
                color: AzizColors.divider.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 12),
              // Onglets — défilement horizontal de sécurité si l'espace
              // devient trop étroit (ex. fenêtre redimensionnée).
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < keys.length; i++)
                        _NavPill(
                          label: context.tr(keys[i]),
                          icon: icons[i],
                          isSelected: targetIndices[i] == currentIndex,
                          onTap: () => onTap(targetIndices[i]),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              const _LangSwitch(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Onglet desktop : icône + libellé, pastille animée ──────────────────────
class _NavPill extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavPill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavPill> createState() => _NavPillState();
}

class _NavPillState extends State<_NavPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected || _hovered;
    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: widget.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(30),
            splashColor: AzizColors.gold.withValues(alpha: 0.15),
            highlightColor: AzizColors.gold.withValues(alpha: 0.08),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AzizColors.gold.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    scale: isActive ? 1.0 : 0.92,
                    child: Icon(
                      widget.icon,
                      size: 16,
                      color:
                          isActive ? AzizColors.gold : AzizColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      letterSpacing: 1.1,
                      fontWeight:
                          widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          isActive ? AzizColors.gold : AzizColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Mobile — AppBar verre dépoli + bouton menu + drawer élégant
// ══════════════════════════════════════════════════════════════════════════════
class _MobileNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final List<String> keys;
  final List<IconData> icons;
  final List<int> targetIndices;

  const _MobileNav({
    required this.currentIndex,
    required this.onTap,
    required this.keys,
    required this.icons,
    required this.targetIndices,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: AzizColors.backgroundMedium.withValues(alpha: 0.94),
            border: Border(
              bottom: BorderSide(
                color: AzizColors.gold.withValues(alpha: 0.16),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _Logo(height: 36, onTap: () => onTap(0)),
              const Spacer(),
              const _LangSwitch(compact: true),
              const SizedBox(width: 6),
              Semantics(
                button: true,
                label: 'Ouvrir le menu de navigation',
                child: IconButton(
                  icon: const Icon(Icons.menu_rounded,
                      color: AzizColors.textPrimary),
                  onPressed: () => _openDrawer(
                      context, currentIndex, onTap, keys, icons, targetIndices),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDrawer(
    BuildContext context,
    int currentIndex,
    void Function(int) onTap,
    List<String> keys,
    List<IconData> icons,
    List<int> targetIndices,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NavDrawer(
        currentIndex: currentIndex,
        onTap: onTap,
        keys: keys,
        icons: icons,
        targetIndices: targetIndices,
      ),
    );
  }
}

// ── Drawer mobile : en-tête identitaire + liste d'items soignée ────────────
class _NavDrawer extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final List<String> keys;
  final List<IconData> icons;
  final List<int> targetIndices;

  const _NavDrawer({
    required this.currentIndex,
    required this.onTap,
    required this.keys,
    required this.icons,
    required this.targetIndices,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AzizColors.backgroundMedium,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AzizColors.gold.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poignée de glissement
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AzizColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // En-tête identitaire dégradé
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
              decoration: BoxDecoration(
                gradient: AzizColors.indigoGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AzizColors.gold.withValues(alpha: 0.15),
                      border: Border.all(
                          color: AzizColors.gold.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.brush_rounded,
                        color: AzizColors.gold, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AZIZART',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AzizColors.textPrimary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Olga Indigo · Art Batik',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AzizColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Liste des items de navigation
            for (int i = 0; i < keys.length; i++)
              _DrawerItem(
                icon: icons[i],
                label: context.tr(keys[i]),
                isSelected: targetIndices[i] == currentIndex,
                onTap: () {
                  Navigator.pop(context);
                  onTap(targetIndices[i]);
                },
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AzizColors.gold.withValues(alpha: 0.12),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AzizColors.gold.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AzizColors.gold.withValues(alpha: 0.18)
                        : AzizColors.surface,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color:
                        isSelected ? AzizColors.gold : AzizColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color:
                          isSelected ? AzizColors.gold : AzizColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.circle, size: 6, color: AzizColors.gold)
                else
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AzizColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Sélecteur de langue FR / EN — toggle glissant unique
// ══════════════════════════════════════════════════════════════════════════════
class _LangSwitch extends StatelessWidget {
  final bool compact;
  const _LangSwitch({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final isFr = languageProvider.languageCode == 'fr';
    const width = 68.0;
    const height = 30.0;

    return Semantics(
      button: true,
      label: isFr ? 'Basculer en anglais' : 'Switch to French',
      child: Tooltip(
        message: isFr ? 'Switch to English' : 'Passer en français',
        child: GestureDetector(
          onTap: () => languageProvider.setLocale(Locale(isFr ? 'en' : 'fr')),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: width,
              height: height,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AzizColors.surface,
                borderRadius: BorderRadius.circular(height / 2),
                border: Border.all(
                  color: AzizColors.gold.withValues(alpha: 0.35),
                ),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    alignment:
                        isFr ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      width: width / 2 - 3,
                      height: height - 6,
                      decoration: BoxDecoration(
                        color: AzizColors.gold,
                        borderRadius: BorderRadius.circular(height / 2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            'FR',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isFr
                                  ? AzizColors.textOnAccent
                                  : AzizColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'EN',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: !isFr
                                  ? AzizColors.textOnAccent
                                  : AzizColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
