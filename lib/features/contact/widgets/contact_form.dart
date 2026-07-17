import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../services/contact_service.dart';
import '../../../theme/aziz_colors.dart';
import '../../../core/localization/language_provider.dart';

/// ContactForm — Formulaire bilingue FR/EN connecté à Firestore.
/// Utilise context.tr() (LanguageProvider) pour que la langue
/// change en temps réel quand l'utilisateur bascule FR ↔ EN.
class ContactForm extends StatefulWidget {
  const ContactForm({super.key});

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  final _phone = TextEditingController();
  bool _sending = false;

  final _service = ContactService();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);

    final msg = ContactMessage(
      name: _name.text.trim(),
      email: _email.text.trim(),
      subject: _subject.text.trim(),
      message: _message.text.trim(),
      phone: _phone.text.trim(),
      sentAt: DateTime.now(),
    );

    final result = await _service.sendMessage(msg);
    if (!mounted) return;
    setState(() => _sending = false);

    final isSuccess = result == ContactResult.success;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isSuccess
                    ? context.tr('contact.success_msg')
                    : result == ContactResult.network
                        ? context.tr('contact.error_network')
                        : context.tr('contact.error'),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? AzizColors.success : AzizColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );

    if (isSuccess) {
      _name.clear();
      _email.clear();
      _subject.clear();
      _message.clear();
      _phone.clear();
    }
  }

  // ── Champ de saisie stylisé ──────────────────────────────────────────────
  Widget _field(
    TextEditingController ctrl,
    String labelKey, {
    int maxLines = 1,
    bool required = true,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    String? hintKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AzizColors.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: context.tr(labelKey),
          hintText: hintKey != null ? context.tr(hintKey) : null,
          hintStyle: const TextStyle(
            color: AzizColors.textMuted,
            fontSize: 13,
          ),
          prefixIcon: prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child:
                      Icon(prefixIcon, color: AzizColors.textMuted, size: 18),
                )
              : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          filled: true,
          fillColor: AzizColors.background.withValues(alpha: 0.5),
          contentPadding: EdgeInsets.symmetric(
            horizontal: prefixIcon != null ? 0 : 16,
            vertical: maxLines > 1 ? 16 : 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AzizColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: AzizColors.border.withValues(alpha: 0.7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AzizColors.saffron, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AzizColors.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AzizColors.error, width: 1.5),
          ),
          labelStyle: const TextStyle(
            color: AzizColors.textSecondary,
            fontSize: 13,
          ),
          errorStyle: const TextStyle(
            color: AzizColors.error,
            fontSize: 11,
          ),
        ),
        validator: required
            ? (v) {
                if (v == null || v.trim().isEmpty) {
                  return context.tr('contact.field_required');
                }
                if (labelKey == 'contact.email' &&
                    !ContactMessage.emailRegex.hasMatch(v.trim())) {
                  return context.tr('contact.invalid_email');
                }
                return null;
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AzizColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AzizColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Titre du formulaire ───────────────────────────────────
            Text(
              context.tr('contact.form_title'),
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AzizColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('contact.form_subtitle'),
              style: const TextStyle(
                fontSize: 12,
                color: AzizColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),

            // ── Champs ────────────────────────────────────────────────
            _field(
              _name,
              'contact.name',
              prefixIcon: Icons.person_outline_rounded,
            ),
            _field(
              _email,
              'contact.email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
            _field(
              _phone,
              'contact.phone',
              required: false,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            _field(
              _subject,
              'contact.subject',
              prefixIcon: Icons.label_outline_rounded,
            ),
            _field(
              _message,
              'contact.message',
              maxLines: 5,
              hintKey: 'contact.message_hint',
            ),

            const SizedBox(height: 6),

            // ── Bouton d'envoi ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _sending ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AzizColors.saffron,
                  foregroundColor: AzizColors.textOnAccent,
                  disabledBackgroundColor:
                      AzizColors.saffron.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AzizColors.textOnAccent,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.send_rounded, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('contact.send'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 12, color: AzizColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  context.tr('contact.privacy_note'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AzizColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
