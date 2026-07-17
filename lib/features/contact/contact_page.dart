import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/aziz_colors.dart';
import '../../theme/responsive.dart';
import '../../core/localization/language_provider.dart';
import 'widgets/contact_form.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  // ⚠️ Remplace par tes vraies coordonnées
  static const String email = 'olga_indigo@yahoo.com';
  static const String phone = '+2290166495217'; // Sans espaces pour les URIs
  static const String phoneDisplay = '+229  01 66 49 52 17';
  static const String address = 'Cotonou, Bénin';
  static const String whatsappUrl = 'https://wa.me/2290166495217';
  static const String instagramUrl =
      'https://www.instagram.com/indigoolga25?igsh=MTdjbGk1NW80bmtmaw==';
  static const String facebookUrl =
      'https://www.facebook.com/profile.php?id=100074832580615';

  // ── FIX (bug principal signalé : boutons WhatsApp/e-mail sans réaction) ──
  // L'ancien code n'appelait `launchUrl` que si `canLaunchUrl` répondait
  // `true`. Or, sur Flutter Web, `canLaunchUrl` retourne très souvent
  // `false` pour les schémas `mailto:`, `tel:` et `https://wa.me/...`,
  // même quand `launchUrl` fonctionnerait parfaitement : le plugin web ne
  // peut pas réellement vérifier la présence d'un gestionnaire côté
  // navigateur. Résultat concret : un clic qui ne fait RIEN, sans le
  // moindre message d'erreur — exactement le symptôme "aucune réaction"
  // remonté par les visiteurs.
  //
  // Le correctif consiste à tenter l'ouverture directement, sans ce
  // pré-contrôle bloquant, et à ne s'appuyer sur un try/catch que pour la
  // télémétrie (logs), jamais pour empêcher l'action.
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
    final isWide = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AzizColors.background,
      body: SingleChildScrollView(
        padding: Responsive.pagePadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── En-tête ──────────────────────────────────────────────
                Text(
                  context.tr('contact.title'),
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AzizColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 48,
                  height: 2,
                  color: AzizColors.saffron,
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('contact.intro'),
                  style: const TextStyle(
                    fontSize: 15,
                    color: AzizColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Boutons d'action rapide (WhatsApp / Email) ──────────
                _QuickContactBar(onLaunch: _launch),
                const SizedBox(height: 40),

                // ── Corps principal ──────────────────────────────────────
                isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              flex: 4,
                              child: _InfoCard(
                                  onLaunch: _launch, isMobile: isMobile)),
                          const SizedBox(width: 48),
                          const Expanded(flex: 6, child: ContactForm()),
                        ],
                      )
                    : Column(
                        children: [
                          _InfoCard(onLaunch: _launch, isMobile: isMobile),
                          const SizedBox(height: 40),
                          const ContactForm(),
                        ],
                      ),

                const SizedBox(height: 60),
                // ── Pied de page discret ─────────────────────────────────
                _ContactFooter(onLaunch: _launch),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BARRE D'ACTIONS RAPIDES — WhatsApp & Email pour les visiteurs pressés
// ══════════════════════════════════════════════════════════════════════════════
class _QuickContactBar extends StatelessWidget {
  const _QuickContactBar({required this.onLaunch});
  final Future<void> Function(Uri) onLaunch;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AzizColors.surface,
            AzizColors.surface.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AzizColors.saffron.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AzizColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('contact.available_now'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AzizColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          isMobile
              ? Column(
                  children: [
                    _QuickBtn.whatsapp(context, onLaunch),
                    const SizedBox(height: 12),
                    _QuickBtn.email(context, onLaunch),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _QuickBtn.whatsapp(context, onLaunch)),
                    const SizedBox(width: 16),
                    Expanded(child: _QuickBtn.email(context, onLaunch)),
                  ],
                ),
        ],
      ),
    );
  }
}

class _QuickBtn extends StatefulWidget {
  final FaIconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  factory _QuickBtn.whatsapp(
      BuildContext context, Future<void> Function(Uri) onLaunch) {
    return _QuickBtn(
      icon: FontAwesomeIcons.whatsapp,
      label: context.tr('contact.whatsapp_cta'),
      sublabel: ContactPage.phoneDisplay,
      color: const Color(0xFF25D366),
      onTap: () => onLaunch(Uri.parse(ContactPage.whatsappUrl)),
    );
  }

  factory _QuickBtn.email(
      BuildContext context, Future<void> Function(Uri) onLaunch) {
    return _QuickBtn(
      icon: FontAwesomeIcons.envelope,
      label: context.tr('contact.email_cta'),
      sublabel: ContactPage.email,
      color: AzizColors.saffron,
      onTap: () => onLaunch(Uri(scheme: 'mailto', path: ContactPage.email)),
    );
  }

  @override
  State<_QuickBtn> createState() => _QuickBtnState();
}

class _QuickBtnState extends State<_QuickBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: _ctrl.reverse,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: FaIcon(widget.icon, color: widget.color, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.sublabel,
                      style: const TextStyle(
                        color: AzizColors.textSecondary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: widget.color.withValues(alpha: 0.6),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CARTE D'INFORMATIONS
// ══════════════════════════════════════════════════════════════════════════════
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.onLaunch, required this.isMobile});
  final Future<void> Function(Uri) onLaunch;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AzizColors.surface,
        border: Border.all(color: AzizColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Titre ─────────────────────────────────────────────────────
          Text(
            context.tr('contact.info_title'),
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AzizColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // ── Infos ─────────────────────────────────────────────────────
          _InfoTile(
            icon: Icons.location_on_outlined,
            label: context.tr('contact.label_address'),
            value: ContactPage.address,
          ),
          _InfoTile(
            icon: Icons.phone_outlined,
            label: context.tr('contact.label_phone'),
            value: ContactPage.phoneDisplay,
            onTap: () => onLaunch(
              Uri(scheme: 'tel', path: ContactPage.phone),
            ),
            copyable: ContactPage.phone,
          ),
          _InfoTile(
            icon: Icons.email_outlined,
            label: context.tr('contact.label_email'),
            value: ContactPage.email,
            onTap: () =>
                onLaunch(Uri(scheme: 'mailto', path: ContactPage.email)),
            copyable: ContactPage.email,
          ),

          const SizedBox(height: 8),
          Divider(color: AzizColors.border.withValues(alpha: 0.5)),
          const SizedBox(height: 16),

          // ── Réseaux sociaux ───────────────────────────────────────────
          Text(
            context.tr('contact.follow'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AzizColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _SocialChip(
                icon: FontAwesomeIcons.whatsapp,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => onLaunch(Uri.parse(ContactPage.whatsappUrl)),
              ),
              const SizedBox(width: 10),
              _SocialChip(
                icon: FontAwesomeIcons.instagram,
                label: 'Instagram',
                color: const Color(0xFFE1306C),
                onTap: () => onLaunch(Uri.parse(ContactPage.instagramUrl)),
              ),
              const SizedBox(width: 10),
              _SocialChip(
                icon: FontAwesomeIcons.facebook,
                label: 'Facebook',
                color: const Color(0xFF1877F2),
                onTap: () => onLaunch(Uri.parse(ContactPage.facebookUrl)),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Horaires ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AzizColors.saffron.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AzizColors.saffron.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    color: AzizColors.saffron, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('contact.response_time'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AzizColors.textSecondary,
                      height: 1.5,
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

/// Ligne d'information avec copie au presse-papier optionnelle
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final String? copyable;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.copyable,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AzizColors.saffron.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AzizColors.saffron, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AzizColors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        color: AzizColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (copyable != null)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: copyable!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('contact.copied')),
                        duration: const Duration(seconds: 2),
                        backgroundColor: AzizColors.surface,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: AzizColors.textMuted.withValues(alpha: 0.6),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialChip extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: FaIcon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PIED DE PAGE CONTACT
// ══════════════════════════════════════════════════════════════════════════════
class _ContactFooter extends StatelessWidget {
  const _ContactFooter({required this.onLaunch});
  final Future<void> Function(Uri) onLaunch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 1,
            color: AzizColors.saffron.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('contact.footer_note'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AzizColors.textMuted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}