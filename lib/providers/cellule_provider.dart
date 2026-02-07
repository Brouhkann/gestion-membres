import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/cellule_model.dart';
import '../data/models/fidele_model.dart';
import '../data/repositories/cellule_repository.dart';
import '../data/services/supabase_service.dart';

/// Provider pour le repository des cellules
final celluleRepositoryProvider = Provider<CelluleRepository>((ref) {
  return CelluleRepository();
});

/// État pour la liste des cellules
class CellulesState {
  final List<CelluleModel> cellules;
  final bool isLoading;
  final String? error;

  const CellulesState({
    this.cellules = const [],
    this.isLoading = false,
    this.error,
  });

  CellulesState copyWith({
    List<CelluleModel>? cellules,
    bool? isLoading,
    String? error,
  }) {
    return CellulesState(
      cellules: cellules ?? this.cellules,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier pour la gestion des cellules
class CellulesNotifier extends StateNotifier<CellulesState> {
  final CelluleRepository _repository;

  CellulesNotifier(this._repository) : super(const CellulesState());

  /// Charge toutes les cellules
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cellules = await _repository.getAll();
      state = state.copyWith(cellules: cellules, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Charge toutes les cellules avec statistiques
  Future<void> loadAllWithStats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cellules = await _repository.getAllWithStats();
      state = state.copyWith(cellules: cellules, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Crée une nouvelle cellule
  Future<CelluleModel?> create(CelluleModel cellule) async {
    try {
      final newCellule = await _repository.create(cellule);
      state = state.copyWith(
        cellules: [...state.cellules, newCellule],
      );
      return newCellule;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Met à jour une cellule
  Future<bool> update(CelluleModel cellule) async {
    try {
      final updated = await _repository.update(cellule);
      state = state.copyWith(
        cellules: state.cellules
            .map((c) => c.id == updated.id ? updated : c)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Définit le responsable d'une cellule
  Future<bool> setResponsable(String celluleId, String? responsableId) async {
    try {
      await _repository.setResponsable(celluleId, responsableId);
      // Recharge pour avoir les données à jour
      await loadAllWithStats();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Ajoute un fidèle à une cellule
  Future<bool> addFidele(String celluleId, String fideleId) async {
    try {
      await _repository.addFidele(celluleId, fideleId);
      // Recharge pour avoir les données à jour
      await loadAllWithStats();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Retire un fidèle d'une cellule
  Future<bool> removeFidele(String celluleId, String fideleId) async {
    try {
      await _repository.removeFidele(celluleId, fideleId);
      // Recharge pour avoir les données à jour
      await loadAllWithStats();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Supprime une cellule
  Future<bool> delete(String id) async {
    try {
      await _repository.delete(id);
      state = state.copyWith(
        cellules: state.cellules.where((c) => c.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Efface l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider principal pour les cellules
final cellulesProvider =
    StateNotifierProvider<CellulesNotifier, CellulesState>((ref) {
  final repository = ref.watch(celluleRepositoryProvider);
  return CellulesNotifier(repository);
});

/// Provider pour une cellule spécifique par ID
final celluleByIdProvider =
    FutureProvider.family<CelluleModel?, String>((ref, id) async {
  final repository = ref.watch(celluleRepositoryProvider);
  try {
    return await repository.getById(id);
  } catch (e) {
    return null;
  }
});

/// Provider pour le compteur de cellules
final cellulesCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(celluleRepositoryProvider);
  return await repository.count();
});

/// Provider pour la liste des cellules (lecture simple)
final cellulesListProvider = FutureProvider<List<CelluleModel>>((ref) async {
  final repository = ref.watch(celluleRepositoryProvider);
  return await repository.getAll();
});

/// Provider pour les fidèles d'une cellule
final fidelesByCelluleProvider =
    FutureProvider.family<List<FideleModel>, String>((ref, celluleId) async {
  final supabase = SupabaseService.instance;
  // Récupère les IDs des fidèles depuis fidele_cellules
  final links = await supabase.fideleCellules
      .select('fidele_id')
      .eq('cellule_id', celluleId);
  final fideleIds = links.map((l) => l['fidele_id'] as String).toList();
  if (fideleIds.isEmpty) return [];
  final data = await supabase.fideles
      .select()
      .inFilter('id', fideleIds)
      .order('nom');
  return data.map((json) => FideleModel.fromJson(json)).toList();
});
