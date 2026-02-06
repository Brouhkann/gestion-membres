import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/departement_model.dart';
import '../services/supabase_service.dart';
import '../../core/exceptions/app_exceptions.dart';

/// Repository pour la gestion des départements
class DepartementRepository {
  final SupabaseService _supabase;

  DepartementRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  /// Récupère tous les départements
  Future<List<DepartementModel>> getAll() async {
    try {
      final data = await _supabase.departements
          .select()
          .order('nom');

      return data.map((json) => DepartementModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère tous les départements avec statistiques
  Future<List<DepartementModel>> getAllWithStats() async {
    try {
      final data = await _supabase.departements
          .select()
          .order('nom');

      final departements = <DepartementModel>[];

      for (final json in data) {
        // Récupère le nom du responsable si existe
        String? responsableNom;
        if (json['responsable_id'] != null) {
          try {
            final responsable = await _supabase.fideles
                .select('nom, prenom')
                .eq('id', json['responsable_id'])
                .maybeSingle();
            if (responsable != null) {
              responsableNom = '${responsable['prenom']} ${responsable['nom']}';
            }
          } catch (_) {}
        }

        // Compte les membres via la table de liaison
        final membresCount = await _supabase.fideleDepartements
            .select()
            .eq('departement_id', json['id'])
            .count(CountOption.exact);

        // Pour les membres actifs, on doit faire une jointure
        int membresActifsCount = 0;
        try {
          final membresActifsData = await _supabase.client
              .from('fidele_departements')
              .select('fidele_id, fideles!inner(actif)')
              .eq('departement_id', json['id'])
              .eq('fideles.actif', true);
          membresActifsCount = membresActifsData.length;
        } catch (_) {
          // Si la jointure échoue, on compte manuellement
          final allMembres = await _supabase.fideleDepartements
              .select('fidele_id')
              .eq('departement_id', json['id']);
          for (final m in allMembres) {
            final fidele = await _supabase.fideles
                .select('actif')
                .eq('id', m['fidele_id'])
                .maybeSingle();
            if (fidele != null && fidele['actif'] == true) {
              membresActifsCount++;
            }
          }
        }

        departements.add(DepartementModel.fromJson({
          ...json,
          'nombre_membres': membresCount.count,
          'nombre_membres_actifs': membresActifsCount,
        }).copyWith(responsableNom: responsableNom));
      }

      return departements;
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère un département par ID
  Future<DepartementModel> getById(String id) async {
    try {
      final data = await _supabase.departements
          .select()
          .eq('id', id)
          .single();

      // Récupère le nom du responsable si existe
      String? responsableNom;
      if (data['responsable_id'] != null) {
        try {
          final responsable = await _supabase.fideles
              .select('nom, prenom')
              .eq('id', data['responsable_id'])
              .maybeSingle();
          if (responsable != null) {
            responsableNom = '${responsable['prenom']} ${responsable['nom']}';
          }
        } catch (_) {}
      }

      // Compte les membres
      final membresCount = await _supabase.fideleDepartements
          .select()
          .eq('departement_id', id)
          .count(CountOption.exact);

      // Membres actifs
      int membresActifsCount = 0;
      try {
        final membresActifsData = await _supabase.client
            .from('fidele_departements')
            .select('fidele_id, fideles!inner(actif)')
            .eq('departement_id', id)
            .eq('fideles.actif', true);
        membresActifsCount = membresActifsData.length;
      } catch (_) {}

      return DepartementModel.fromJson({
        ...data,
        'nombre_membres': membresCount.count,
        'nombre_membres_actifs': membresActifsCount,
      }).copyWith(responsableNom: responsableNom);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw DatabaseException.notFound('Département');
      }
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Crée un nouveau département
  Future<DepartementModel> create(DepartementModel departement) async {
    try {
      final data = await _supabase.departements
          .insert(departement.toInsertJson())
          .select()
          .single();

      return DepartementModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Met à jour un département
  Future<DepartementModel> update(DepartementModel departement) async {
    try {
      final data = await _supabase.departements
          .update({
            'nom': departement.nom,
            'description': departement.description,
            'responsable_id': departement.responsableId,
            'actif': departement.actif,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', departement.id)
          .select()
          .single();

      return DepartementModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Définit le responsable d'un département
  Future<void> setResponsable(String departementId, String? responsableId) async {
    try {
      await _supabase.departements
          .update({
            'responsable_id': responsableId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', departementId);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Ajoute un fidèle à un département
  Future<void> addFidele(String departementId, String fideleId) async {
    try {
      await _supabase.fideleDepartements.insert({
        'departement_id': departementId,
        'fidele_id': fideleId,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Duplicate key - déjà membre
        throw DatabaseException.duplicateEntry('Ce fidèle est déjà dans ce département');
      }
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Retire un fidèle d'un département
  Future<void> removeFidele(String departementId, String fideleId) async {
    try {
      await _supabase.fideleDepartements
          .delete()
          .eq('departement_id', departementId)
          .eq('fidele_id', fideleId);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère les départements d'un fidèle
  Future<List<DepartementModel>> getByFidele(String fideleId) async {
    try {
      final links = await _supabase.fideleDepartements
          .select('departement_id')
          .eq('fidele_id', fideleId);

      final departements = <DepartementModel>[];
      for (final link in links) {
        final dept = await _supabase.departements
            .select()
            .eq('id', link['departement_id'])
            .maybeSingle();
        if (dept != null) {
          departements.add(DepartementModel.fromJson(dept));
        }
      }

      return departements;
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Supprime un département
  Future<void> delete(String id) async {
    try {
      // Supprime d'abord les associations
      await _supabase.fideleDepartements
          .delete()
          .eq('departement_id', id);

      // Puis le département
      await _supabase.departements.delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Compte les départements
  Future<int> count() async {
    try {
      final response = await _supabase.departements
          .select()
          .count(CountOption.exact);

      return response.count;
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }
}
