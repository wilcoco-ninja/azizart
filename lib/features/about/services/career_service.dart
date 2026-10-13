import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service pour gérer les étapes de carrière (career_milestones)
class CareerService {
  final _db = Supabase.instance.client;
  static const _table = 'career_milestones';

  // ── CONTROL D'ACCÈS ADMIN ───────────────────────────────────────────────

  Future<User> _checkAdmin() async {
    final user = _db.auth.currentUser;
    if (user == null) {
      throw Exception(
        'Utilisateur non connecté. Veuillez vous connecter pour publier.',
      );
    }
    try {
      final isAdmin = await _db.rpc('is_admin');
      if (isAdmin != true) {
        throw Exception(
          'Permissions insuffisantes. Votre compte n\'a pas les droits administrateur.',
        );
      }
    } on PostgrestException catch (e) {
      throw Exception(
        'Impossible de vérifier vos droits administrateur (${e.message}). Réessayez.',
      );
    }
    return user;
  }

  // ── LECTURE ────────────────────────────────────────────────────────────

  /// Récupère toutes les étapes de carrière triées par ordre d'affichage
  Future<List<Map<String, dynamic>>> getMilestones() async {
    try {
      return await _db
          .from(_table)
          .select()
          .order('display_order', ascending: true);
    } catch (e) {
      debugPrint('CareerService: erreur getMilestones — $e');
      return [];
    }
  }

  // ── ÉCRITURE ───────────────────────────────────────────────────────────

  /// Ajoute une nouvelle étape de carrière
  Future<void> addMilestone({
    required String year,
    required String title,
    String description = '',
    int displayOrder = 0,
  }) async {
    await _checkAdmin();
    await _db.from(_table).insert({
      'year': year,
      'title': title,
      'description': description,
      'display_order': displayOrder,
    });
    debugPrint('CareerService: étape de carrière ajoutée');
  }

  /// Met à jour une étape de carrière
  Future<void> updateMilestone({
    required String id,
    required String year,
    required String title,
    String description = '',
    int displayOrder = 0,
  }) async {
    await _checkAdmin();
    await _db.from(_table)
        .update({
          'year': year,
          'title': title,
          'description': description,
          'display_order': displayOrder,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
    debugPrint('CareerService: étape de carrière $id mise à jour');
  }

  /// Supprime une étape de carrière
  Future<void> deleteMilestone(String id) async {
    await _checkAdmin();
    await _db.from(_table).delete().eq('id', id);
    debugPrint('CareerService: étape de carrière $id supprimée');
  }

  /// Supprime plusieurs étapes de carrière en une seule requête SQL
  Future<void> deleteMultipleMilestones(List<String> ids) async {
    if (ids.isEmpty) return;
    await _checkAdmin();
    await _db.from(_table).delete().inFilter('id', ids);
    debugPrint('CareerService: ${ids.length} étapes supprimées');
  }
}

/// Service pour gérer les compétences (skills)
class SkillsService {
  final _db = Supabase.instance.client;
  static const _table = 'skills';

  // ── CONTROL D'ACCÈS ADMIN ───────────────────────────────────────────────

  Future<User> _checkAdmin() async {
    final user = _db.auth.currentUser;
    if (user == null) {
      throw Exception(
        'Utilisateur non connecté. Veuillez vous connecter pour publier.',
      );
    }
    try {
      final isAdmin = await _db.rpc('is_admin');
      if (isAdmin != true) {
        throw Exception(
          'Permissions insuffisantes. Votre compte n\'a pas les droits administrateur.',
        );
      }
    } on PostgrestException catch (e) {
      throw Exception(
        'Impossible de vérifier vos droits administrateur (${e.message}). Réessayez.',
      );
    }
    return user;
  }

  // ── LECTURE ────────────────────────────────────────────────────────────

  /// Récupère toutes les compétences triées par ordre d'affichage
  Future<List<Map<String, dynamic>>> getSkills() async {
    try {
      return await _db
          .from(_table)
          .select()
          .order('display_order', ascending: true);
    } catch (e) {
      debugPrint('SkillsService: erreur getSkills — $e');
      return [];
    }
  }

  // ── ÉCRITURE ───────────────────────────────────────────────────────────

  /// Ajoute une nouvelle compétence
  Future<void> addSkill({
    required String name,
    int level = 50,
    int displayOrder = 0,
  }) async {
    await _checkAdmin();
    await _db.from(_table).insert({
      'name': name,
      'level': level,
      'display_order': displayOrder,
    });
    debugPrint('SkillsService: compétence ajoutée');
  }

  /// Met à jour une compétence
  Future<void> updateSkill({
    required String id,
    required String name,
    int level = 50,
    int displayOrder = 0,
  }) async {
    await _checkAdmin();
    await _db.from(_table)
        .update({
          'name': name,
          'level': level,
          'display_order': displayOrder,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
    debugPrint('SkillsService: compétence $id mise à jour');
  }

  /// Supprime une compétence
  Future<void> deleteSkill(String id) async {
    await _checkAdmin();
    await _db.from(_table).delete().eq('id', id);
    debugPrint('SkillsService: compétence $id supprimée');
  }

  /// Supprime plusieurs compétences en une seule requête SQL
  Future<void> deleteMultipleSkills(List<String> ids) async {
    if (ids.isEmpty) return;
    await _checkAdmin();
    await _db.from(_table).delete().inFilter('id', ids);
    debugPrint('SkillsService: ${ids.length} compétences supprimées');
  }
}