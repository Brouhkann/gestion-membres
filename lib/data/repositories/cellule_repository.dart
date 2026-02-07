import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cellule_model.dart';
import '../services/supabase_service.dart';
import '../../core/exceptions/app_exceptions.dart';

/// Repository pour la gestion des cellules
class CelluleRepository {
  final SupabaseService _supabase;

  CelluleRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  /// Récupère toutes les cellules
  Future<List<CelluleModel>> getAll() async {
    try {
      final data = await _supabase.cellules
          .select()
          .order('nom');

      return data.map((json) => CelluleModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère toutes les cellules avec statistiques
  Future<List<CelluleModel>> getAllWithStats() async {
    try {
      final data = await _supabase.cellules
          .select()
          .order('nom');

      final cellules = <CelluleModel>[];

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

        // Compte les membres via fidele_cellules
        final membresCount = await _supabase.fideleCellules
            .select()
            .eq('cellule_id', json['id'])
            .count(CountOption.exact);

        // Compte les membres actifs via fidele_cellules join fideles
        final membresActifsCount = await _supabase.fideleCellules
            .select('fidele_id, fideles!inner(actif)')
            .eq('cellule_id', json['id'])
            .eq('fideles.actif', true)
            .count(CountOption.exact);

        cellules.add(CelluleModel.fromJson({
          ...json,
          'responsable': responsableNom != null ? {'prenom': '', 'nom': ''} : null,
          'nombre_membres': membresCount.count,
          'nombre_membres_actifs': membresActifsCount.count,
        }).copyWith(responsableNom: responsableNom));
      }

      return cellules;
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Récupère une cellule par ID
  Future<CelluleModel> getById(String id) async {
    try {
      final data = await _supabase.cellules
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

      // Compte les membres via fidele_cellules
      final membresCount = await _supabase.fideleCellules
          .select()
          .eq('cellule_id', id)
          .count(CountOption.exact);

      // Compte les membres actifs via fidele_cellules join fideles
      final membresActifsCount = await _supabase.fideleCellules
          .select('fidele_id, fideles!inner(actif)')
          .eq('cellule_id', id)
          .eq('fideles.actif', true)
          .count(CountOption.exact);

      return CelluleModel.fromJson({
        ...data,
        'nombre_membres': membresCount.count,
        'nombre_membres_actifs': membresActifsCount.count,
      }).copyWith(responsableNom: responsableNom);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw DatabaseException.notFound('Cellule');
      }
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Crée une nouvelle cellule
  Future<CelluleModel> create(CelluleModel cellule) async {
    try {
      final data = await _supabase.cellules
          .insert(cellule.toInsertJson())
          .select()
          .single();

      return CelluleModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Met à jour une cellule
  Future<CelluleModel> update(CelluleModel cellule) async {
    try {
      final data = await _supabase.cellules
          .update({
            'nom': cellule.nom,
            'description': cellule.description,
            'responsable_id': cellule.responsableId,
            'actif': cellule.actif,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', cellule.id)
          .select()
          .single();

      return CelluleModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Définit le responsable d'une cellule
  Future<void> setResponsable(String celluleId, String? responsableId) async {
    try {
      await _supabase.cellules
          .update({
            'responsable_id': responsableId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', celluleId);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Ajoute un fidèle à une cellule
  Future<void> addFidele(String celluleId, String fideleId) async {
    try {
      await _supabase.fideleCellules
          .insert({
            'cellule_id': celluleId,
            'fidele_id': fideleId,
          });
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Retire un fidèle d'une cellule
  Future<void> removeFidele(String celluleId, String fideleId) async {
    try {
      await _supabase.fideleCellules
          .delete()
          .eq('cellule_id', celluleId)
          .eq('fidele_id', fideleId);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Supprime une cellule
  Future<void> delete(String id) async {
    try {
      // Vérifie s'il y a des fidèles dans la cellule
      final fideles = await _supabase.fideleCellules
          .select()
          .eq('cellule_id', id)
          .count(CountOption.exact);

      if (fideles.count > 0) {
        throw DatabaseException(
          message: 'Impossible de supprimer une cellule avec des membres',
          code: 'HAS_MEMBERS',
        );
      }

      await _supabase.cellules.delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Compte les cellules
  Future<int> count() async {
    try {
      final response = await _supabase.cellules
          .select()
          .count(CountOption.exact);

      return response.count;
    } on PostgrestException catch (e) {
      throw DatabaseException(message: e.message, originalError: e);
    }
  }
}
