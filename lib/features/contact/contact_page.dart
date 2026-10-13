import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/language_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/aziz_colors.dart';
import '../home/shared_components.dart';
import 'widgets/contact_form.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  static const String email = 'olga_indigo@yahoo.com';
  static const String phone = '+2290166495217';
  static const String phoneDisplay = '+229  01 66 49 52 17';
  static const String address = 'Cotonou, Bénin';
  static const String whatsappUrl = 'https://wa.me/2290166495217';
  static const String instagramUrl =
      'https://www.instagram.com/indigoolga25?igsh=MTdjbGk1NW80bmtmaw==';
  static const String facebookUrl =
      'https://www.facebook.com/profile.php?id=100074832580615';

  Future<void> _launch(Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        debugPrint('ContactPage: launchUrl a échoué pour $uri');
      }
    } catch (e) {
      debugPrint('ContactPage: impossible d\'ouvrir $uri — $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = homeIsDesktop(context);
    final isMobile = homeIsMobile(context);
    final gutter = homeGutter(context);

    final info = _InfoPanel(onLaunch: _launch);
    const form = _FormPanel();

    return Scaffold(
      backgroundColor: AzizColors.lightBackground,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            isMobile ? 48 : 80,
            gutter,
            isMobile ? 64 : 104,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  context.tr('contact.title'),
                  style: homeSerif(
                    size: isMobile ? 40 : 64,
                    height: 1.04,
                    letterSpacing: isMobile ? -0.8 : -1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Text(
                  context.tr('contact.intro'),
                  style: homeSans(size: isMobile ? 15.5 : 17, height: 1.7),
                ),
              ),
              const SizedBox(height: 32),
              _QuickContact(onLaunch: _launch),
              SizedBox(height: isMobile ? 48 : 72),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: info),
                    SizedBox(width: homeColumnGap(context)),
                    const Expanded(flex: 6, child: form),
                  ],
                )
              else ...[
                info,
                const SizedBox(height: 48),
                form,
              ],
              SizedBox(height: isMobile ? 56 : 80),
              const _ContactFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CONTACT RAPIDE
// ══════════════════════════════════════════════════════════════════════════════

class _QuickContact extends StatelessWidget {
  const _QuickContact({required this.onLaunch});
  final Future<void> Function(Uri) onLaunch;

  @override
  Widget build(BuildContext context) {
    final isMobile = homeIsMobile(context);

    final whatsapp = HeroBtn(
      label: context.tr('contact.whatsapp_cta'),
      leading: const Icon(HomeIcons.whatsapp),
      onTap: () => onLaunch(Uri.parse(ContactPage.whatsappUrl)),
    );
    final email = GhostBtn(
      label: context.tr('contact.email_cta'),
      leading: const Icon(HomeIcons.email),
      onTap: () => onLaunch(Uri.parse('mailto:${ContactPage.email}')),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AzizColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.tr('contact.available_now'),
              style: homeSans(
                size: 13.5,
                color: AzizColors.lightTextSecondary,
                weight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [whatsapp, const SizedBox(height: 12), email],
          )
        else
          Wrap(spacing: 12, runSpacing: 12, children: [whatsapp, email]),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COORDONNÉES
// ══════════════════════════════════════════════════════════════════════════════

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.onLaunch});
  final Future<void> Function(Uri) onLaunch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('contact.info_title'),
          style: homeSerif(size: 28, height: 1.2),
        ),
        const SizedBox(height: 20),
        _InfoRow(
          icon: Icons.location_on_outlined,
          label: context.tr('contact.label_address'),
          value: ContactPage.address,
          first: true,
        ),
        _InfoRow(
          icon: Icons.call_outlined,
          label: context.tr('contact.label_phone'),
          value: ContactPage.phoneDisplay,
          onTap: () => onLaunch(Uri.parse('tel:${ContactPage.phone}')),
          copyable: ContactPage.phone,
        ),
        _InfoRow(
          icon: Icons.mail_outline_rounded,
          label: context.tr('contact.label_email'),
          value: ContactPage.email,
          onTap: () => onLaunch(Uri.parse('mailto:${ContactPage.email}')),
          copyable: ContactPage.email,
          last: true,
        ),
        const SizedBox(height: 32),
        Text(
          context.tr('contact.follow'),
          style: homeSans(
            size: 14,
            color: AzizColors.lightTextSecondary,
            weight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            HomeCircleBtn(
              icon: HomeIcons.whatsapp,
              semanticLabel: 'WhatsApp',
              onTap: () => onLaunch(Uri.parse(ContactPage.whatsappUrl)),
            ),
            const SizedBox(width: 10),
            HomeCircleBtn(
              icon: HomeIcons.instagram,
              semanticLabel: 'Instagram',
              onTap: () => onLaunch(Uri.parse(ContactPage.instagramUrl)),
            ),
            const SizedBox(width: 10),
            HomeCircleBtn(
              icon: HomeIcons.facebook,
              semanticLabel: 'Facebook',
              onTap: () => onLaunch(Uri.parse(ContactPage.facebookUrl)),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 18,
              color: AzizColors.trueIndigoLight,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tr('contact.response_time'),
                style: homeSans(size: 13.5, height: 1.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Ligne de coordonnées : icône, libellé, valeur, et copie optionnelle.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final String? copyable;
  final bool first;
  final bool last;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.copyable,
    this.first = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    const line = BorderSide(color: AzizColors.lightBorder);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: line,
          bottom: last ? line : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(icon, size: 22, color: AzizColors.trueIndigo),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: homeSans(
                                size: 12.5,
                                color: AzizColors.lightTextMuted,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              value,
                              style: homeSans(
                                size: 15,
                                color: AzizColors.lightTextPrimary,
                                weight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (copyable != null)
            IconButton(
              tooltip: homeText(context, fr: 'Copier', en: 'Copy'),
              icon: const Icon(Icons.copy_rounded, size: 18),
              color: AzizColors.trueIndigoLight,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: copyable!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('contact.copied')),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FORMULAIRE
// ══════════════════════════════════════════════════════════════════════════════

class _FormPanel extends StatelessWidget {
  const _FormPanel();

  @override
  Widget build(BuildContext context) {
    final isMobile = homeIsMobile(context);
    final base = AppTheme.dark;
    final themed = base.copyWith(
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: Colors.white.withValues(alpha: 0.08),
      ),
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: AzizColors.trueIndigoDark,
        borderRadius: BorderRadius.circular(kHomeRadius),
      ),
      child: Theme(data: themed, child: const ContactForm()),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PIED DE PAGE CONTACT
// ══════════════════════════════════════════════════════════════════════════════

class _ContactFooter extends StatelessWidget {
  const _ContactFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AzizColors.lightBorder)),
      ),
      child: Text(
        context.tr('contact.footer_note'),
        style: homeSans(
          size: 13,
          color: AzizColors.lightTextMuted,
          height: 1.6,
        ),
      ),
    );
  }
}