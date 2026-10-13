import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/contact_model.dart';

enum ContactResult { success, error, network }

class ContactService {
  final _db = Supabase.instance.client;
  static const _table = 'messages';

  Future<ContactResult> sendMessage(ContactMessage msg) async {
    try {
      debugPrint('ContactService: Envoi message: ${msg.name}, ${msg.email}');

      final payload = {
        ...msg.toMap(),
        'status': 'pending',
      };

      debugPrint('ContactService: Payload: $payload');

      await _db.from(_table).insert(payload);

      return ContactResult.success;
    } on PostgrestException catch (e) {
      debugPrint('ContactService: PostgrestException "${e.code}" — ${e.message}');
      return ContactResult.error;
    } on AuthException catch (e) {
      debugPrint('ContactService: AuthException — ${e.message}');
      return ContactResult.error;
    } catch (e) {
      debugPrint('ContactService: Erreur inattendue ou réseau — $e');
      return ContactResult.network;
    }
  }
}