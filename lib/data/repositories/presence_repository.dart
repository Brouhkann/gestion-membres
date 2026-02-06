import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/presence_model.dart';
import '../models/enums.dart';
import '../services/supabase_service.dart';
import '../../core/exceptions/app_exceptions.dart';

/// Repository pour la gestion des présences
class PresenceRepository {
  final SupabaseService _supabase;

  PresenceRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  /// Crée une nouvelle session d'appel
  Future<SessionAppelModel> createSession({
    required DateTime date,
    required TypeGroupe typeGroupe,
    required String groupeId,
    required String createdBy,
  }) async {
    try {
      final data = await _supabase.sessionsAppel
          .insert({
            'date': date.toIso8601String().split('T')[0],
            'type_groupe': typeGroupe.name,
            'groupe_id': groupeId,
            'created_by': createdBy,
          })
          .select()
          .single();

      return SessionAppelModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Enregistre les présences pour une session
  Future<void> enregistrerPresences({
    required String sessionId,
    required List<PresenceModel> presences,
  }) async {
    try {
      final presencesData = presences.map((p) => {
        'session_id': sessionId,
        'fidele_id': p.fideleId,
        'statut': p.statut.name,
      }).toList();

      await _supabase.presences.insert(presencesData);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère les sessions d'appel d'un groupe
  Future<List<SessionAppelModel>> getSessionsByGroupe({
    required TypeGroupe typeGroupe,
    required String groupeId,
    int limit = 10,
  }) async {
    try {
      final data = await _supabase.sessionsAppel
          .select()
          .eq('type_groupe', typeGroupe.name)
          .eq('groupe_id', groupeId)
          .order('date', ascending: false)
          .limit(limit);

      final sessions = <SessionAppelModel>[];

      for (final json in data) {
        // Compte les présents et absents
        final presentsCount = await _supabase.presences
            .select()
            .eq('session_id', json['id'])
            .eq('statut', StatutPresence.present.name)
            .count(CountOption.exact);

        final absentsCount = await _supabase.presences
            .select()
            .eq('session_id', json['id'])
            .eq('statut', StatutPresence.absent.name)
            .count(CountOption.exact);

        sessions.add(SessionAppelModel.fromJson({
          ...json,
          'nombre_presents': presentsCount.count,
          'nombre_absents': absentsCount.count,
          'total_membres': presentsCount.count + absentsCount.count,
        }));
      }

      return sessions;
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère une session par ID avec ses présences
  Future<SessionAppelModel> getSessionById(String sessionId) async {
    try {
      final data = await _supabase.sessionsAppel
          .select()
          .eq('id', sessionId)
          .single();

      // Compte les présents et absents
      final presentsCount = await _supabase.presences
          .select()
          .eq('session_id', sessionId)
          .eq('statut', StatutPresence.present.name)
          .count(CountOption.exact);

      final absentsCount = await _supabase.presences
          .select()
          .eq('session_id', sessionId)
          .eq('statut', StatutPresence.absent.name)
          .count(CountOption.exact);

      return SessionAppelModel.fromJson({
        ...data,
        'nombre_presents': presentsCount.count,
        'nombre_absents': absentsCount.count,
        'total_membres': presentsCount.count + absentsCount.count,
      });
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw DatabaseException.notFound('Session d\'appel');
      }
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère les présences d'une session
  Future<List<PresenceModel>> getPresencesBySession(String sessionId) async {
    try {
      final data = await _supabase.presences
          .select('*, fidele:fideles(nom, prenom, photo_url)')
          .eq('session_id', sessionId)
          .order('created_at');

      return data.map((json) => PresenceModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère l'historique des présences d'un fidèle
  Future<List<PresenceModel>> getHistoriqueFidele(String fideleId, {int limit = 20}) async {
    try {
      final data = await _supabase.presences
          .select('*, session:sessions_appel(date, type_groupe)')
          .eq('fidele_id', fideleId)
          .order('created_at', ascending: false)
          .limit(limit);

      return data.map((json) => PresenceModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Vérifie si un fidèle a une présence récente (dans les X derniers jours)
  Future<bool> hasPresenceRecente(String fideleId, {int jours = 30}) async {
    try {
      final dateLimit = DateTime.now().subtract(Duration(days: jours));

      final data = await _supabase.presences
          .select('id')
          .eq('fidele_id', fideleId)
          .eq('statut', StatutPresence.present.name)
          .gte('created_at', dateLimit.toIso8601String())
          .limit(1);

      return data.isNotEmpty;
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Calcule le taux de présence d'un groupe
  Future<double> getTauxPresence({
    required TypeGroupe typeGroupe,
    required String groupeId,
    int derniersSessions = 4,
  }) async {
    try {
      // Récupère les dernières sessions
      final sessions = await _supabase.sessionsAppel
          .select('id')
          .eq('type_groupe', typeGroupe.name)
          .eq('groupe_id', groupeId)
          .order('date', ascending: false)
          .limit(derniersSessions);

      if (sessions.isEmpty) return 0;

      int totalPresents = 0;
      int totalMembres = 0;

      for (final session in sessions) {
        final presentsCount = await _supabase.presences
            .select()
            .eq('session_id', session['id'])
            .eq('statut', StatutPresence.present.name)
            .count(CountOption.exact);

        final totalCount = await _supabase.presences
            .select()
            .eq('session_id', session['id'])
            .count(CountOption.exact);

        totalPresents += presentsCount.count;
        totalMembres += totalCount.count;
      }

      if (totalMembres == 0) return 0;
      return (totalPresents / totalMembres) * 100;
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère la dernière session d'un groupe
  Future<SessionAppelModel?> getDerniereSession({
    required TypeGroupe typeGroupe,
    required String groupeId,
  }) async {
    try {
      final data = await _supabase.sessionsAppel
          .select()
          .eq('type_groupe', typeGroupe.name)
          .eq('groupe_id', groupeId)
          .order('date', ascending: false)
          .limit(1);

      if (data.isEmpty) return null;

      return SessionAppelModel.fromJson(data.first);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Supprime une session et ses présences
  Future<void> deleteSession(String sessionId) async {
    try {
      // Supprime d'abord les présences
      await _supabase.presences.delete().eq('session_id', sessionId);

      // Puis la session
      await _supabase.sessionsAppel.delete().eq('id', sessionId);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }
}
