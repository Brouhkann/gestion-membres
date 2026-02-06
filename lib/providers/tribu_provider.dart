import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/tribu_model.dart';
import '../data/repositories/tribu_repository.dart';

/// Provider pour le repository des tribus
final tribuRepositoryProvider = Provider<TribuRepository>((ref) {
  return TribuRepository();
});

/// État pour la liste des tribus
class TribusState {
  final List<TribuModel> tribus;
  final bool isLoading;
  final String? error;

  const TribusState({
    this.tribus = const [],
    this.isLoading = false,
    this.error,
  });

  TribusState copyWith({
    List<TribuModel>? tribus,
    bool? isLoading,
    String? error,
  }) {
    return TribusState(
      tribus: tribus ?? this.tribus,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier pour la gestion des tribus
class TribusNotifier extends StateNotifier<TribusState> {
  final TribuRepository _repository;

  TribusNotifier(this._repository) : super(const TribusState());

  /// Charge toutes les tribus
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tribus = await _repository.getAll();
      state = state.copyWith(tribus: tribus, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Charge toutes les tribus avec statistiques
  Future<void> loadAllWithStats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tribus = await _repository.getAllWithStats();
      state = state.copyWith(tribus: tribus, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Crée une nouvelle tribu
  Future<TribuModel?> create(TribuModel tribu) async {
    try {
      final newTribu = await _repository.create(tribu);
      state = state.copyWith(
        tribus: [...state.tribus, newTribu],
      );
      return newTribu;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Met à jour une tribu
  Future<bool> update(TribuModel tribu) async {
    try {
      final updated = await _repository.update(tribu);
      state = state.copyWith(
        tribus: state.tribus
            .map((t) => t.id == updated.id ? updated : t)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Définit le patriarche d'une tribu
  Future<bool> setPatriarche(String tribuId, String? patriarcheId) async {
    try {
      await _repository.setPatriarche(tribuId, patriarcheId);
      // Recharge pour avoir les données à jour
      await loadAllWithStats();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Supprime une tribu
  Future<bool> delete(String id) async {
    try {
      await _repository.delete(id);
      state = state.copyWith(
        tribus: state.tribus.where((t) => t.id != id).toList(),
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

/// Provider principal pour les tribus
final tribusProvider =
    StateNotifierProvider<TribusNotifier, TribusState>((ref) {
  final repository = ref.watch(tribuRepositoryProvider);
  return TribusNotifier(repository);
});

/// Provider pour une tribu spécifique par ID
final tribuByIdProvider =
    FutureProvider.family<TribuModel?, String>((ref, id) async {
  final repository = ref.watch(tribuRepositoryProvider);
  try {
    return await repository.getById(id);
  } catch (e) {
    return null;
  }
});

/// Provider pour le compteur de tribus
final tribusCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(tribuRepositoryProvider);
  return await repository.count();
});

/// Provider pour la liste des tribus (lecture simple)
final tribusListProvider = FutureProvider<List<TribuModel>>((ref) async {
  final repository = ref.watch(tribuRepositoryProvider);
  return await repository.getAll();
});
