import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/contact_model.dart';

// ══════════════════════════════════════════════════════════════════════════
// ContactService — Écrit dans Supabase (table 'messages').
// L'envoi d'e-mail réel est délégué à une Edge Function déclenchée par un
// Database Webhook sur INSERT (voir supabase/functions/send-contact-email).
// Avantage : aucune clé API d'envoi de mail exposée côté client.
// ══════════════════════════════════════════════════════════════════════════

enum ContactResult { success, error, network }

class ContactService {
  final _db = Supabase.instance.client;
  static const _table = 'messages';

  Future<ContactResult> sendMessage(ContactMessage msg) async {
    try {
      await _db.from(_table).insert({
        ...msg.toMap(),
        'status': 'pending', // l'Edge Function passera à 'sent' ou 'failed'
      });
      return ContactResult.success;
    } on PostgrestException catch (e) {
      // FIX (diagnostic) : ces erreurs étaient avalées silencieusement.
      // "42501"/permission-denied = les policies RLS de la table
      // 'messages' n'autorisent pas l'écriture publique — à vérifier dans
      // schema.sql / Dashboard Supabase → Authentication → Policies.
      debugPrint(
          'ContactService: PostgrestException "${e.code}" — ${e.message}');
      return ContactResult.error;
    } on AuthException catch (e) {
      debugPrint('ContactService: AuthException — ${e.message}');
      return ContactResult.error;
    } catch (e) {
      debugPrint('ContactService: erreur inattendue — $e');
      // La plupart des erreurs réseau (offline, DNS, timeout…) atterrissent
      // ici plutôt que dans un type dédié avec ce client.
      return ContactResult.network;
    }
  }
}
