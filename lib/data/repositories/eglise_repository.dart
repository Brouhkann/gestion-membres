import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/eglise_model.dart';
import '../services/supabase_service.dart';
import '../../core/exceptions/app_exceptions.dart' as app;

/// Repository pour la gestion des églises
class EgliseRepository {
  final SupabaseService _supabase;

  EgliseRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  /// Récupère toutes les églises (Super Admin uniquement)
  Future<List<EgliseModel>> getAll() async {
    try {
      final response = await _supabase.client
          .from('eglises')
          .select()
          .eq('actif', true)
          .order('nom');

      return (response as List)
          .map((json) => EgliseModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw app.DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère une église par son ID
  Future<EgliseModel?> getById(String id) async {
    try {
      final response = await _supabase.client
          .from('eglises')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return EgliseModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw app.DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère l'église d'un pasteur
  Future<EgliseModel?> getByPasteurId(String pasteurId) async {
    try {
      final response = await _supabase.client
          .from('eglises')
          .select()
          .eq('pasteur_id', pasteurId)
          .maybeSingle();

      if (response == null) return null;
      return EgliseModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw app.DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Crée une nouvelle église (Super Admin)
  Future<EgliseModel> create({
    required String nom,
    String? pasteurId,
  }) async {
    try {
      final data = {
        'nom': nom,
        'pasteur_id': pasteurId,
        'configuration_complete': false,
        'actif': true,
      };

      final response = await _supabase.client
          .from('eglises')
          .insert(data)
          .select()
          .single();

      return EgliseModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw app.DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Met à jour le profil d'une église (Pasteur)
  Future<EgliseModel> updateProfile({
    required String egliseId,
    required String nom,
    String? logoUrl,
    String? adresse,
    String? ville,
    String? pays,
    String? telephone,
    String? email,
    String? description,
  }) async {
    try {
      final data = {
        'nom': nom,
        'logo_url': logoUrl,
        'adresse': adresse,
        'ville': ville,
        'pays': pays,
        'telephone': telephone,
        'email': email,
        'description': description,
        'configuration_complete': true,
      };

      final response = await _supabase.client
          .from('eglises')
          .update(data)
          .eq('id', egliseId)
          .select()
          .single();

      return EgliseModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw app.DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Met à jour le logo de l'église
  Future<String> uploadLogo(String egliseId, List<int> bytes, String fileName) async {
    try {
      final path = 'eglises/$egliseId/logo_$fileName';

      await _supabase.client.storage
          .from('logos')
          .uploadBinary(path, bytes as dynamic);

      final url = _supabase.client.storage
          .from('logos')
          .getPublicUrl(path);

      // Met à jour l'URL du logo dans la base
      await _supabase.client
          .from('eglises')
          .update({'logo_url': url})
          .eq('id', egliseId);

      return url;
    } catch (e) {
      throw app.DatabaseException(message: 'Erreur upload logo: $e', originalError: e);
    }
  }

  /// Désactive une église (Super Admin)
  Future<void> deactivate(String id) async {
    try {
      await _supabase.client
          .from('eglises')
          .update({'actif': false})
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw app.DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Statistiques d'une église
  Future<Map<String, int>> getStatistics(String egliseId) async {
    try {
      final fideles = await _supabase.client
          .from('fideles')
          .select('id')
          .eq('eglise_id', egliseId)
          .eq('actif', true);

      final tribus = await _supabase.client
          .from('tribus')
          .select('id')
          .eq('eglise_id', egliseId)
          .eq('actif', true);

      final departements = await _supabase.client
          .from('departements')
          .select('id')
          .eq('eglise_id', egliseId)
          .eq('actif', true);

      return {
        'fideles': (fideles as List).length,
        'tribus': (tribus as List).length,
        'departements': (departements as List).length,
      };
    } on PostgrestException catch (e) {
      throw app.DatabaseException(message: e.message, originalError: e);
    }
  }
}
