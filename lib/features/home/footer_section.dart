import 'package:flutter/material.dart';

import '../../core/localization/language_provider.dart';
import '../../theme/aziz_colors.dart';
import 'shared_components.dart';

/// Pied de page : contact, réseaux sociaux, mentions légales et accès administration.
class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = homeIsMobile(context);
    final gutter = homeGutter(context);
    final hairline = AzizColors.lightBackground.withValues(alpha: 0.14);

    return HomeBand(
      color: AzizColors.trueIndigoDark,
      background: const BatikTexture(opacity: 0.08, seed: 33),
      padding: EdgeInsets.fromLTRB(
        gutter,
        isMobile ? 72 : 104,
        gutter,
        isMobile ? 24 : 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FooterContact(isMobile: isMobile),
          SizedBox(height: isMobile ? 56 : 80),
          _Hairline(color: hairline),
          const SizedBox(height: 36),
          _FooterBrand(isMobile: isMobile),
          const SizedBox(height: 36),
          _Hairline(color: hairline),
          const SizedBox(height: 20),
          _FooterLegal(isMobile: isMobile),
        ],
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  final Color color;

  const _Hairline({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 1,
      child: ColoredBox(color: color),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// CONTACT
// ═════════════════════════════════════════════════════════════════════════

class _FooterContact extends StatelessWidget {
  final bool isMobile;

  const _FooterContact({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.tr('home.footer_cta_title'),
          style: homeSerif(
            size: isMobile ? 34 : 52,
            color: AzizColors.lightBackground,
            height: 1.1,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            context.tr('home.footer_cta_subtitle'),
            style: homeSans(
              size: 16,
              color: AzizColors.lightBackground.withValues(alpha: 0.74),
              height: 1.7,
            ),
          ),
        ),
      ],
    );

    // WhatsApp : bulle de message ; e-mail : enveloppe.
    final whatsapp = HeroBtn(
      label: 'WhatsApp',
      onTap: () => homeLaunch(HomeContact.whatsappUrl),
      leading: const Icon(HomeIcons.whatsapp),
    );
    final email = GhostBtn(
      label: context.tr('home.footer_email_btn'),
      onTap: () => homeLaunch(HomeContact.emailUrl),
      color: AzizColors.lightBackground,
      leading: const Icon(HomeIcons.email),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          text,
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: whatsapp),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: email),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: text),
        const SizedBox(width: 32),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            whatsapp,
            const SizedBox(width: 12),
            email,
          ],
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// MARQUE & RÉSEAUX
// ═════════════════════════════════════════════════════════════════════════

class _FooterBrand extends StatelessWidget {
  final bool isMobile;

  const _FooterBrand({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final brand = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'AZIZART COLORS',
          style: homeSerif(
            size: 22,
            color: AzizColors.lightBackground,
            letterSpacing: 5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.tr('home.footer_tagline'),
          style: homeSans(
            size: 13.5,
            color: AzizColors.lightBackground.withValues(alpha: 0.62),
            letterSpacing: 0.4,
            height: 1.5,
          ),
        ),
      ],
    );

    const socials = _SocialsBar();

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          brand,
          const SizedBox(height: 28),
          socials,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [brand, socials],
    );
  }
}

class _SocialItem {
  final IconData icon;
  final String label;
  final String url;

  const _SocialItem(this.icon, this.label, this.url);
}

class _SocialsBar extends StatelessWidget {
  const _SocialsBar();

  static const double _size = 44;
  static const double _minGap = 8;
  static const double _maxGap = 14;
  static const double _runGap = 12;

  static const List<_SocialItem> _items = [
    _SocialItem(HomeIcons.whatsapp, 'WhatsApp', HomeContact.whatsappUrl),
    _SocialItem(HomeIcons.youtube, 'YouTube', HomeContact.youtubeUrl),
    _SocialItem(HomeIcons.instagram, 'Instagram', HomeContact.instagramUrl),
    _SocialItem(HomeIcons.tiktok, 'TikTok', HomeContact.tiktokUrl),
    _SocialItem(HomeIcons.facebook, 'Facebook', HomeContact.facebookUrl),
    _SocialItem(HomeIcons.email, 'E-mail', HomeContact.emailUrl),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = _items.length;
        var perRow = n;
        var gap = 12.0;

        if (constraints.maxWidth.isFinite) {
          final maxW = constraints.maxWidth;
          perRow = ((maxW + _minGap) / (_size + _minGap)).floor().clamp(1, n);
          final rows = (n / perRow).ceil();
          perRow = (n / rows).ceil();
          gap = perRow > 1
              ? ((maxW - perRow * _size) / (perRow - 1))
                  .clamp(_minGap, _maxGap)
                  .toDouble()
              : 0.0;
        }

        return Wrap(
          spacing: gap,
          runSpacing: _runGap,
          children: [
            for (final item in _items)
              _SocialBtn(icon: item.icon, label: item.label, url: item.url),
          ],
        );
      },
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _SocialBtn({
    required this.icon,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kHomeRadius),
      side: BorderSide(
        color: AzizColors.lightBackground.withValues(alpha: 0.28),
      ),
    );

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: () => homeLaunch(url),
        child: Material(
          color: AzizColors.lightBackground.withValues(alpha: 0.06),
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: () => homeLaunch(url),
            child: SizedBox(
              width: _SocialsBar._size,
              height: _SocialsBar._size,
              child: Center(
                child: Icon(
                  icon,
                  size: kHomeSocialIconBox,
                  color: AzizColors.lightBackground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// MENTIONS
// ═════════════════════════════════════════════════════════════════════════

class _FooterLegal extends StatelessWidget {
  final bool isMobile;

  const _FooterLegal({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final copyright = Text(
      '© $year AZIZART COLORS, Olga Indigo, Cotonou, Bénin',
      style: homeSans(
        size: 12,
        color: AzizColors.lightBackground.withValues(alpha: 0.5),
        letterSpacing: 0.3,
        height: 1.4,
      ),
    );
    const admin = _AdminLink();

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          copyright,
          const SizedBox(height: 6),
          admin,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: copyright),
        admin,
      ],
    );
  }
}

class _AdminLink extends StatelessWidget {
  const _AdminLink();

  @override
  Widget build(BuildContext context) {
    final color = AzizColors.lightBackground.withValues(alpha: 0.85);

    return Semantics(
      button: true,
      label: 'Espace administration AHO',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/admin'),
          borderRadius: BorderRadius.circular(kHomeRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(HomeIcons.admin, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  'Espace AHO',
                  style: homeSans(
                    size: 12.5,
                    color: color,
                    weight: FontWeight.w600,
                    letterSpacing: 0.3,
                    height: 1.2,
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