import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/models/enums.dart';
import '../data/repositories/auth_repository.dart';

/// Provider pour le repository d'authentification
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// État de l'authentification
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  /// État initial
  factory AuthState.initial() => const AuthState();

  /// État de chargement
  factory AuthState.loading() => const AuthState(isLoading: true);

  /// État authentifié
  factory AuthState.authenticated(UserModel user) => AuthState(
        user: user,
        isAuthenticated: true,
      );

  /// État d'erreur
  factory AuthState.error(String message) => AuthState(error: message);
}

/// Notifier pour la gestion de l'authentification
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial());

  /// Vérifie l'état d'authentification au démarrage
  Future<void> checkAuthStatus() async {
    state = AuthState.loading();
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.initial();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Connexion
  Future<bool> signIn({
    required String telephone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.signIn(
        telephone: telephone,
        password: password,
      );
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.signOut();
      state = AuthState.initial();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Efface l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Met à jour premiere_connexion à false après configuration de l'église
  Future<void> updatePremiereConnexion() async {
    if (state.user == null) return;

    try {
      // Mettre à jour dans la base
      await _repository.updatePremiereConnexion(state.user!.id);

      // Mettre à jour l'état local
      final updatedUser = state.user!.copyWith(premiereConnexion: false);
      state = AuthState.authenticated(updatedUser);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Met à jour l'utilisateur dans l'état
  void updateUser(UserModel user) {
    state = AuthState.authenticated(user);
  }
}

/// Provider principal pour l'authentification
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

/// Provider pour l'utilisateur actuel
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

/// Provider pour vérifier si l'utilisateur est connecté
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Provider pour le rôle de l'utilisateur
final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(currentUserProvider)?.role;
});

/// Provider pour vérifier si l'utilisateur est super admin
final isSuperAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isSuperAdmin ?? false;
});

/// Provider pour vérifier si l'utilisateur est pasteur
final isPasteurProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isPasteur ?? false;
});

/// Provider pour vérifier si l'utilisateur est patriarche
final isPatriarcheProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isPatriarche ?? false;
});

/// Provider pour vérifier si l'utilisateur est responsable
final isResponsableProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isResponsable ?? false;
});

/// Provider pour l'ID de la tribu de l'utilisateur (patriarche)
final userTribuIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.tribuId;
});

/// Provider pour l'ID du département de l'utilisateur (responsable)
final userDepartementIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.departementId;
});

/// Provider pour l'ID de l'église de l'utilisateur
final userEgliseIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.egliseId;
});
