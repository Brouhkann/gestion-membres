import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fidele_model.dart';
import '../services/supabase_service.dart';
import '../../core/exceptions/app_exceptions.dart';

/// Repository pour la gestion des fidèles
class FideleRepository {
  final SupabaseService _supabase;

  FideleRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  /// Récupère tous les fidèles
  Future<List<FideleModel>> getAll() async {
    try {
      final data = await _supabase.fideles
          .select('*, tribu:tribus(nom)')
          .order('prenom');

      return data.map((json) => FideleModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère les fidèles d'une tribu
  Future<List<FideleModel>> getByTribu(String tribuId) async {
    try {
      final data = await _supabase.fideles
          .select('*, tribu:tribus(nom)')
          .eq('tribu_id', tribuId)
          .order('prenom');

      return data.map((json) => FideleModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère les fidèles d'un département
  Future<List<FideleModel>> getByDepartement(String departementId) async {
    try {
      final data = await _supabase.client
          .from('fidele_departements')
          .select('fidele:fideles(*, tribu:tribus(nom))')
          .eq('departement_id', departementId);

      return data
          .map((json) => FideleModel.fromJson(json['fidele']))
          .toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère un fidèle par ID
  Future<FideleModel> getById(String id) async {
    try {
      final data = await _supabase.fideles
          .select('*, tribu:tribus(nom)')
          .eq('id', id)
          .single();

      return FideleModel.fromJson(data);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw DatabaseException.notFound('Fidèle');
      }
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Crée un nouveau fidèle
  Future<FideleModel> create(FideleModel fidele) async {
    try {
      final data = await _supabase.fideles
          .insert(fidele.toInsertJson())
          .select('*, tribu:tribus(nom)')
          .single();

      return FideleModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Met à jour un fidèle
  Future<FideleModel> update(FideleModel fidele) async {
    try {
      final data = await _supabase.fideles
          .update({
            'nom': fidele.nom,
            'prenom': fidele.prenom,
            'sexe': fidele.sexe.code,
            'jour_naissance': fidele.jourNaissance,
            'mois_naissance': fidele.moisNaissance,
            'annee_naissance': fidele.anneeNaissance,
            'telephone': fidele.telephone,
            'adresse': fidele.adresse,
            'profession': fidele.profession,
            'invite_par': fidele.invitePar,
            'tribu_id': fidele.tribuId,
            'photo_url': fidele.photoUrl,
            'actif': fidele.actif,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', fidele.id)
          .select('*, tribu:tribus(nom)')
          .single();

      return FideleModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Active/désactive un fidèle
  Future<void> setActif(String id, bool actif) async {
    try {
      await _supabase.fideles
          .update({
            'actif': actif,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Supprime un fidèle
  Future<void> delete(String id) async {
    try {
      await _supabase.fideles.delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Recherche des fidèles
  Future<List<FideleModel>> search(String query) async {
    try {
      final searchTerm = '%$query%';
      final data = await _supabase.fideles
          .select('*, tribu:tribus(nom)')
          .or('nom.ilike.$searchTerm,prenom.ilike.$searchTerm,telephone.ilike.$searchTerm')
          .order('prenom');

      return data.map((json) => FideleModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère les fidèles actifs
  Future<List<FideleModel>> getActifs() async {
    try {
      final data = await _supabase.fideles
          .select('*, tribu:tribus(nom)')
          .eq('actif', true)
          .order('prenom');

      return data.map((json) => FideleModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère les anniversaires du jour
  Future<List<FideleModel>> getAnniversairesAujourdhui() async {
    try {
      final now = DateTime.now();
      final data = await _supabase.fideles
          .select('*, tribu:tribus(nom)')
          .eq('jour_naissance', now.day)
          .eq('mois_naissance', now.month)
          .eq('actif', true)
          .order('prenom');

      return data.map((json) => FideleModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère les anniversaires de la semaine
  Future<List<FideleModel>> getAnniversairesSemaine() async {
    try {
      final now = DateTime.now();
      final anniversaires = <FideleModel>[];

      // Récupère tous les fidèles actifs avec date de naissance
      final data = await _supabase.fideles
          .select('*, tribu:tribus(nom)')
          .eq('actif', true)
          .not('jour_naissance', 'is', null)
          .not('mois_naissance', 'is', null)
          .order('mois_naissance')
          .order('jour_naissance');

      for (final json in data) {
        final fidele = FideleModel.fromJson(json);
        if (fidele.isAnniversaireCetteSemaine) {
          anniversaires.add(fidele);
        }
      }

      return anniversaires;
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère les anniversaires du mois
  Future<List<FideleModel>> getAnniversairesMois() async {
    try {
      final now = DateTime.now();
      final data = await _supabase.fideles
          .select('*, tribu:tribus(nom)')
          .eq('mois_naissance', now.month)
          .eq('actif', true)
          .order('jour_naissance');

      return data.map((json) => FideleModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Compte les fidèles
  Future<int> count() async {
    try {
      final response = await _supabase.fideles
          .select()
          .count(CountOption.exact);

      return response.count;
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Compte les fidèles actifs
  Future<int> countActifs() async {
    try {
      final response = await _supabase.fideles
          .select()
          .eq('actif', true)
          .count(CountOption.exact);

      return response.count;
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }
}
