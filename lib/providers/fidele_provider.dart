import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/fidele_model.dart';
import '../data/repositories/fidele_repository.dart';
import '../data/services/supabase_service.dart';
import 'auth_provider.dart';

/// Provider pour le repository des fidèles
final fideleRepositoryProvider = Provider<FideleRepository>((ref) {
  return FideleRepository();
});

/// État pour la liste des fidèles
class FidelesState {
  final List<FideleModel> fideles;
  final bool isLoading;
  final String? error;

  const FidelesState({
    this.fideles = const [],
    this.isLoading = false,
    this.error,
  });

  FidelesState copyWith({
    List<FideleModel>? fideles,
    bool? isLoading,
    String? error,
  }) {
    return FidelesState(
      fideles: fideles ?? this.fideles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier pour la gestion des fidèles
class FidelesNotifier extends StateNotifier<FidelesState> {
  final FideleRepository _repository;

  FidelesNotifier(this._repository) : super(const FidelesState());

  /// Charge tous les fidèles
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final fideles = await _repository.getAll();
      state = state.copyWith(fideles: fideles, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Charge les fidèles d'une tribu
  Future<void> loadByTribu(String tribuId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final fideles = await _repository.getByTribu(tribuId);
      state = state.copyWith(fideles: fideles, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Charge les fidèles d'un département
  Future<void> loadByDepartement(String departementId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final fideles = await _repository.getByDepartement(departementId);
      state = state.copyWith(fideles: fideles, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Crée un nouveau fidèle
  Future<FideleModel?> create(FideleModel fidele) async {
    try {
      final newFidele = await _repository.create(fidele);
      state = state.copyWith(
        fideles: [...state.fideles, newFidele],
      );
      return newFidele;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Met à jour un fidèle
  Future<bool> update(FideleModel fidele) async {
    try {
      final updated = await _repository.update(fidele);
      state = state.copyWith(
        fideles: state.fideles
            .map((f) => f.id == updated.id ? updated : f)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Active/désactive un fidèle
  Future<bool> setActif(String id, bool actif) async {
    try {
      await _repository.setActif(id, actif);
      state = state.copyWith(
        fideles: state.fideles
            .map((f) => f.id == id ? f.copyWith(actif: actif) : f)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Supprime un fidèle
  Future<bool> delete(String id) async {
    try {
      await _repository.delete(id);
      state = state.copyWith(
        fideles: state.fideles.where((f) => f.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Recherche des fidèles
  Future<void> search(String query) async {
    if (query.isEmpty) {
      await loadAll();
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final fideles = await _repository.search(query);
      state = state.copyWith(fideles: fideles, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Efface l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider principal pour les fidèles
final fidelesProvider =
    StateNotifierProvider<FidelesNotifier, FidelesState>((ref) {
  final repository = ref.watch(fideleRepositoryProvider);
  return FidelesNotifier(repository);
});

/// Provider pour un fidèle spécifique par ID
final fideleByIdProvider =
    FutureProvider.family<FideleModel?, String>((ref, id) async {
  final repository = ref.watch(fideleRepositoryProvider);
  try {
    return await repository.getById(id);
  } catch (e) {
    return null;
  }
});

/// Provider pour les fidèles d'une tribu
final fidelesByTribuProvider =
    FutureProvider.family<List<FideleModel>, String>((ref, tribuId) async {
  final repository = ref.watch(fideleRepositoryProvider);
  return await repository.getByTribu(tribuId);
});

/// Provider pour les fidèles d'un département
final fidelesByDepartementProvider =
    FutureProvider.family<List<FideleModel>, String>((ref, deptId) async {
  final repository = ref.watch(fideleRepositoryProvider);
  return await repository.getByDepartement(deptId);
});

/// Provider pour les fidèles actifs
final fidelesActifsProvider = FutureProvider<List<FideleModel>>((ref) async {
  final repository = ref.watch(fideleRepositoryProvider);
  return await repository.getActifs();
});

/// Provider pour le compteur de fidèles
final fidelesCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(fideleRepositoryProvider);
  return await repository.count();
});

/// Provider pour le compteur de fidèles actifs
final fidelesActifsCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(fideleRepositoryProvider);
  return await repository.countActifs();
});

/// Provider pour les fidèles de la tribu de l'utilisateur connecté (patriarche)
final mesFidelesProvider = FutureProvider<List<FideleModel>>((ref) async {
  final tribuId = ref.watch(userTribuIdProvider);
  if (tribuId == null) return [];

  final repository = ref.watch(fideleRepositoryProvider);
  return await repository.getByTribu(tribuId);
});

/// Provider pour tous les responsables (patriarches + resp. départements + resp. cellules)
/// Utilisé par le pasteur pour l'appel des responsables lors des réunions
final responsablesProvider = FutureProvider<List<FideleModel>>((ref) async {
  final supabase = SupabaseService.instance;

  // Récupère les IDs des patriarches (depuis les tribus)
  final tribus = await supabase.tribus
      .select('patriarche_id')
      .not('patriarche_id', 'is', null);
  final patriarcheIds = tribus
      .map((t) => t['patriarche_id'] as String?)
      .where((id) => id != null)
      .cast<String>()
      .toSet();

  // Récupère les IDs des responsables de départements
  final depts = await supabase.departements
      .select('responsable_id')
      .not('responsable_id', 'is', null);
  final deptResponsableIds = depts
      .map((d) => d['responsable_id'] as String?)
      .where((id) => id != null)
      .cast<String>()
      .toSet();

  // Récupère les IDs des responsables de cellules
  final cellules = await supabase.cellules
      .select('responsable_id')
      .not('responsable_id', 'is', null);
  final celluleResponsableIds = cellules
      .map((c) => c['responsable_id'] as String?)
      .where((id) => id != null)
      .cast<String>()
      .toSet();

  // Combine tous les IDs uniques
  final allIds = {...patriarcheIds, ...deptResponsableIds, ...celluleResponsableIds};
  if (allIds.isEmpty) return [];

  // Récupère les fidèles correspondants
  final data = await supabase.fideles
      .select('*, tribu:tribus!fideles_tribu_id_fkey(nom)')
      .inFilter('id', allIds.toList())
      .order('nom');

  return data.map((json) => FideleModel.fromJson(json)).toList();
});
