import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../core/localization/language_provider.dart';
import '../theme/aziz_colors.dart';
import '../theme/responsive.dart';
import 'optimized_image.dart';

/// Nom officiel du site.
const String kSiteName = 'AZIZART COLORS';

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

  /// Chaque icône dit où mène le lien.
  static const List<IconData> _icons = [
    Icons.photo_library_outlined, // galerie : les œuvres
    Icons.palette_outlined, // atelier : le geste de l'artiste
    Icons.play_circle_outline_rounded, // médias : vidéos et presse
    Icons.person_outline_rounded, // à propos : l'artiste
    Icons.mail_outline_rounded, // contact : écrire
  ];

  static const List<int> _targetIndices = [1, 2, 3, 4, 5];

  @override
  Widget build(BuildContext context) {
    assert(
        _keys.length == _icons.length && _keys.length == _targetIndices.length,
        'AzizNavBar : `_keys`, `_icons` et `_targetIndices` doivent avoir la même longueur.');

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
            targetIndices: _targetIndices,
          );
  }
}

class _Logo extends StatelessWidget {
  final double height;
  final VoidCallback? onTap;

  /// Logo public servi depuis Cloudflare R2 (`logo/logo.png`).
  static String get _logoUrl => AppConfig.logoPublicUrl;

  const _Logo({required this.height, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Nom du site en secours si le logo ne se charge pas.
    final fallback = SizedBox(
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          kSiteName,
          maxLines: 2,
          style: TextStyle(
            fontFamily: 'Playfair Display',
            color: AzizColors.lightBackground,
            fontSize: height * 0.3,
            fontWeight: FontWeight.w400,
            letterSpacing: 2.4,
            height: 1.15,
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: '$kSiteName — retour à l\'accueil',
      child: Tooltip(
        message: 'Accueil',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(2),
            mouseCursor: SystemMouseCursors.click,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: OptimizedImage(
                url: _logoUrl,
                folder: 'logo',
                height: height,
                // Largeur proportionnelle : la barre ne « saute » pas au
                // chargement et le logo n'est jamais déformé.
                width: height * 2.4,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
                memCacheHeight: (height * 3).round(),
                placeholder: SizedBox(height: height, width: height * 2.4),
                errorWidget: fallback,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BUREAU / TABLETTE
// ═══════════════════════════════════════════════════════════════════════════

class _DesktopNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final List<String> keys;
  final List<int> targetIndices;

  const _DesktopNav({
    required this.currentIndex,
    required this.onTap,
    required this.keys,
    required this.targetIndices,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AzizColors.backgroundMedium,
        border: Border(
          bottom: BorderSide(
            color: AzizColors.lightBackground.withValues(alpha: 0.12),
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: Responsive.hPad(context)),
      child: Row(
        children: [
          _Logo(height: 48, onTap: () => onTap(0)),
          const SizedBox(width: 32),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < keys.length; i++)
                    _NavLink(
                      label: context.tr(keys[i]),
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
    );
  }
}

/// Lien de navigation : texte seul, trait doré sous l'onglet actif.
class _NavLink extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavLink({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected || _hovered;
    final indicator = widget.isSelected
        ? AzizColors.saffron
        : (_hovered
            ? AzizColors.saffron.withValues(alpha: 0.5)
            : Colors.transparent);

    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: widget.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: SizedBox(
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 14,
                      letterSpacing: 0.3,
                      fontWeight:
                          widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? AzizColors.lightBackground
                          : AzizColors.textSecondary,
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 0,
                  height: 2,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    color: indicator,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MOBILE
// ═══════════════════════════════════════════════════════════════════════════

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
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AzizColors.backgroundMedium,
        border: Border(
          bottom: BorderSide(
            color: AzizColors.lightBackground.withValues(alpha: 0.12),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _Logo(height: 36, onTap: () => onTap(0)),
          const Spacer(),
          const _LangSwitch(compact: true),
          const SizedBox(width: 4),
          Semantics(
            button: true,
            label: 'Ouvrir le menu de navigation',
            child: IconButton(
              tooltip: 'Menu',
              icon: const Icon(
                Icons.menu_rounded,
                color: AzizColors.lightBackground,
                size: 26,
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: () => _openDrawer(context),
            ),
          ),
        ],
      ),
    );
  }

  void _openDrawer(BuildContext context) {
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          border: Border.all(
            color: AzizColors.lightBackground.withValues(alpha: 0.12),
          ),
        ),
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AzizColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      kSiteName,
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: AzizColors.textPrimary,
                        letterSpacing: 2.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Olga Indigo, art batik',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                        color: AzizColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: AzizColors.lightBackground.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 8),
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
    final color =
        isSelected ? AzizColors.saffron : AzizColors.textPrimary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isSelected ? AzizColors.saffron : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      color: color,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AzizColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LANGUE
// ═══════════════════════════════════════════════════════════════════════════

class _LangSwitch extends StatelessWidget {
  final bool compact;
  const _LangSwitch({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final isFr = languageProvider.languageCode == 'fr';
    final width = compact ? 64.0 : 72.0;
    const height = 32.0;
    final radius = BorderRadius.circular(2);

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
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: AzizColors.lightBackground.withValues(alpha: 0.3),
                ),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    alignment:
                        isFr ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      width: width / 2 - 2,
                      height: height - 6,
                      decoration: BoxDecoration(
                        color: AzizColors.saffron,
                        borderRadius: BorderRadius.circular(1),
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
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isFr
                                  ? AzizColors.textOnAccent
                                  : AzizColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'EN',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: !isFr
                                  ? AzizColors.textOnAccent
                                  : AzizColors.textSecondary,
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