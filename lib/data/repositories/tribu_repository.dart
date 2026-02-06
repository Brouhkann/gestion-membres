import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tribu_model.dart';
import '../services/supabase_service.dart';
import '../../core/exceptions/app_exceptions.dart';

/// Repository pour la gestion des tribus
class TribuRepository {
  final SupabaseService _supabase;

  TribuRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  /// Récupère toutes les tribus
  Future<List<TribuModel>> getAll() async {
    try {
      final data = await _supabase.tribus
          .select()
          .order('nom');

      return data.map((json) => TribuModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère toutes les tribus avec statistiques
  Future<List<TribuModel>> getAllWithStats() async {
    try {
      final data = await _supabase.tribus
          .select()
          .order('nom');

      final tribus = <TribuModel>[];

      for (final json in data) {
        // Récupère le nom du patriarche si existe
        String? patriarcheNom;
        if (json['patriarche_id'] != null) {
          try {
            final patriarche = await _supabase.fideles
                .select('nom, prenom')
                .eq('id', json['patriarche_id'])
                .maybeSingle();
            if (patriarche != null) {
              patriarcheNom = '${patriarche['prenom']} ${patriarche['nom']}';
            }
          } catch (_) {}
        }

        // Compte les membres
        final membresCount = await _supabase.fideles
            .select()
            .eq('tribu_id', json['id'])
            .count(CountOption.exact);

        // Compte les membres actifs
        final membresActifsCount = await _supabase.fideles
            .select()
            .eq('tribu_id', json['id'])
            .eq('actif', true)
            .count(CountOption.exact);

        tribus.add(TribuModel.fromJson({
          ...json,
          'patriarche': patriarcheNom != null ? {'prenom': '', 'nom': ''} : null,
          'nombre_membres': membresCount.count,
          'nombre_membres_actifs': membresActifsCount.count,
        }).copyWith(patriarcheNom: patriarcheNom));
      }

      return tribus;
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère une tribu par ID
  Future<TribuModel> getById(String id) async {
    try {
      final data = await _supabase.tribus
          .select()
          .eq('id', id)
          .single();

      // Récupère le nom du patriarche si existe
      String? patriarcheNom;
      if (data['patriarche_id'] != null) {
        try {
          final patriarche = await _supabase.fideles
              .select('nom, prenom')
              .eq('id', data['patriarche_id'])
              .maybeSingle();
          if (patriarche != null) {
            patriarcheNom = '${patriarche['prenom']} ${patriarche['nom']}';
          }
        } catch (_) {}
      }

      // Compte les membres
      final membresCount = await _supabase.fideles
          .select()
          .eq('tribu_id', id)
          .count(CountOption.exact);

      // Compte les membres actifs
      final membresActifsCount = await _supabase.fideles
          .select()
          .eq('tribu_id', id)
          .eq('actif', true)
          .count(CountOption.exact);

      return TribuModel.fromJson({
        ...data,
        'nombre_membres': membresCount.count,
        'nombre_membres_actifs': membresActifsCount.count,
      }).copyWith(patriarcheNom: patriarcheNom);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw DatabaseException.notFound('Tribu');
      }
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Crée une nouvelle tribu
  Future<TribuModel> create(TribuModel tribu) async {
    try {
      final data = await _supabase.tribus
          .insert(tribu.toInsertJson())
          .select()
          .single();

      return TribuModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Met à jour une tribu
  Future<TribuModel> update(TribuModel tribu) async {
    try {
      final data = await _supabase.tribus
          .update({
            'nom': tribu.nom,
            'description': tribu.description,
            'patriarche_id': tribu.patriarcheId,
            'actif': tribu.actif,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tribu.id)
          .select()
          .single();

      return TribuModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Définit le patriarche d'une tribu
  Future<void> setPatriarche(String tribuId, String? patriarcheId) async {
    try {
      await _supabase.tribus
          .update({
            'patriarche_id': patriarcheId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', tribuId);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Supprime une tribu
  Future<void> delete(String id) async {
    try {
      // Vérifie s'il y a des fidèles dans la tribu
      final fideles = await _supabase.fideles
          .select()
          .eq('tribu_id', id)
          .count(CountOption.exact);

      if (fideles.count > 0) {
        throw DatabaseException(
          message: 'Impossible de supprimer une tribu avec des membres',
          code: 'HAS_MEMBERS',
        );
      }

      await _supabase.tribus.delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Compte les tribus
  Future<int> count() async {
    try {
      final response = await _supabase.tribus
          .select()
          .count(CountOption.exact);

      return response.count;
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }
}
