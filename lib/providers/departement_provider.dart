import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/departement_model.dart';
import '../data/repositories/departement_repository.dart';

/// Provider pour le repository des départements
final departementRepositoryProvider = Provider<DepartementRepository>((ref) {
  return DepartementRepository();
});

/// État pour la liste des départements
class DepartementsState {
  final List<DepartementModel> departements;
  final bool isLoading;
  final String? error;

  const DepartementsState({
    this.departements = const [],
    this.isLoading = false,
    this.error,
  });

  DepartementsState copyWith({
    List<DepartementModel>? departements,
    bool? isLoading,
    String? error,
  }) {
    return DepartementsState(
      departements: departements ?? this.departements,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier pour la gestion des départements
class DepartementsNotifier extends StateNotifier<DepartementsState> {
  final DepartementRepository _repository;

  DepartementsNotifier(this._repository) : super(const DepartementsState());

  /// Charge tous les départements
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final departements = await _repository.getAll();
      state = state.copyWith(departements: departements, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Charge tous les départements avec statistiques
  Future<void> loadAllWithStats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final departements = await _repository.getAllWithStats();
      state = state.copyWith(departements: departements, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Crée un nouveau département
  Future<DepartementModel?> create(DepartementModel departement) async {
    try {
      final newDept = await _repository.create(departement);
      state = state.copyWith(
        departements: [...state.departements, newDept],
      );
      return newDept;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Met à jour un département
  Future<bool> update(DepartementModel departement) async {
    try {
      final updated = await _repository.update(departement);
      state = state.copyWith(
        departements: state.departements
            .map((d) => d.id == updated.id ? updated : d)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Définit le responsable d'un département
  Future<bool> setResponsable(String departementId, String? responsableId) async {
    try {
      await _repository.setResponsable(departementId, responsableId);
      await loadAllWithStats();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Ajoute un fidèle à un département
  Future<bool> addFidele(String departementId, String fideleId) async {
    try {
      await _repository.addFidele(departementId, fideleId);
      await loadAllWithStats();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Retire un fidèle d'un département
  Future<bool> removeFidele(String departementId, String fideleId) async {
    try {
      await _repository.removeFidele(departementId, fideleId);
      await loadAllWithStats();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Supprime un département
  Future<bool> delete(String id) async {
    try {
      await _repository.delete(id);
      state = state.copyWith(
        departements: state.departements.where((d) => d.id != id).toList(),
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

/// Provider principal pour les départements
final departementsProvider =
    StateNotifierProvider<DepartementsNotifier, DepartementsState>((ref) {
  final repository = ref.watch(departementRepositoryProvider);
  return DepartementsNotifier(repository);
});

/// Provider pour un département spécifique par ID
final departementByIdProvider =
    FutureProvider.family<DepartementModel?, String>((ref, id) async {
  final repository = ref.watch(departementRepositoryProvider);
  try {
    return await repository.getById(id);
  } catch (e) {
    return null;
  }
});

/// Provider pour les départements d'un fidèle
final departementsByFideleProvider =
    FutureProvider.family<List<DepartementModel>, String>((ref, fideleId) async {
  final repository = ref.watch(departementRepositoryProvider);
  return await repository.getByFidele(fideleId);
});

/// Provider pour le compteur de départements
final departementsCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(departementRepositoryProvider);
  return await repository.count();
});

/// Provider pour la liste des départements (lecture simple)
final departementsListProvider = FutureProvider<List<DepartementModel>>((ref) async {
  final repository = ref.watch(departementRepositoryProvider);
  return await repository.getAll();
});
