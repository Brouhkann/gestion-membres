import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/presence_model.dart';
import '../data/models/enums.dart';
import '../data/repositories/presence_repository.dart';
import 'auth_provider.dart';

/// Provider pour le repository des présences
final presenceRepositoryProvider = Provider<PresenceRepository>((ref) {
  return PresenceRepository();
});

/// État pour l'appel en cours
class AppelState {
  final AppelEnCoursModel? appelEnCours;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  const AppelState({
    this.appelEnCours,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  AppelState copyWith({
    AppelEnCoursModel? appelEnCours,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
  }) {
    return AppelState(
      appelEnCours: appelEnCours ?? this.appelEnCours,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// Notifier pour la gestion de l'appel
class AppelNotifier extends StateNotifier<AppelState> {
  final PresenceRepository _repository;
  final String? _userId;

  AppelNotifier(this._repository, this._userId) : super(const AppelState());

  /// Initialise un nouvel appel
  void initAppel({
    required TypeGroupe typeGroupe,
    required String groupeId,
    required String groupeNom,
    required List<FideleAppelItem> fideles,
  }) {
    state = state.copyWith(
      appelEnCours: AppelEnCoursModel(
        date: DateTime.now(),
        typeGroupe: typeGroupe,
        groupeId: groupeId,
        groupeNom: groupeNom,
        fideles: fideles,
      ),
      error: null,
      successMessage: null,
    );
  }

  /// Marque un fidèle comme présent
  void marquerPresent(String fideleId) {
    if (state.appelEnCours == null) return;

    final fidele = state.appelEnCours!.fideles.firstWhere(
      (f) => f.fideleId == fideleId,
    );

    final fidelesAppeles = [
      ...state.appelEnCours!.fidelesAppeles,
      fidele.copyWith(statut: StatutPresence.present),
    ];

    state = state.copyWith(
      appelEnCours: state.appelEnCours!.copyWith(
        fidelesAppeles: fidelesAppeles,
      ),
    );
  }

  /// Marque un fidèle comme absent
  void marquerAbsent(String fideleId) {
    if (state.appelEnCours == null) return;

    final fidele = state.appelEnCours!.fideles.firstWhere(
      (f) => f.fideleId == fideleId,
    );

    final fidelesAppeles = [
      ...state.appelEnCours!.fidelesAppeles,
      fidele.copyWith(statut: StatutPresence.absent),
    ];

    state = state.copyWith(
      appelEnCours: state.appelEnCours!.copyWith(
        fidelesAppeles: fidelesAppeles,
      ),
    );
  }

  /// Annule le marquage d'un fidèle
  void annulerMarquage(String fideleId) {
    if (state.appelEnCours == null) return;

    final fidelesAppeles = state.appelEnCours!.fidelesAppeles
        .where((f) => f.fideleId != fideleId)
        .toList();

    state = state.copyWith(
      appelEnCours: state.appelEnCours!.copyWith(
        fidelesAppeles: fidelesAppeles,
      ),
    );
  }

  /// Marque tous les restants comme absents
  void marquerRestantsAbsents() {
    if (state.appelEnCours == null) return;

    final fidelesNonAppeles = state.appelEnCours!.fidelesNonAppeles;
    final nouveauxAppeles = fidelesNonAppeles
        .map((f) => f.copyWith(statut: StatutPresence.absent))
        .toList();

    final fidelesAppeles = [
      ...state.appelEnCours!.fidelesAppeles,
      ...nouveauxAppeles,
    ];

    state = state.copyWith(
      appelEnCours: state.appelEnCours!.copyWith(
        fidelesAppeles: fidelesAppeles,
      ),
    );
  }

  /// Justifie l'absence d'un fidèle avec un motif
  void justifierAbsence(String fideleId, String motif) {
    if (state.appelEnCours == null) return;

    final fidelesAppeles = state.appelEnCours!.fidelesAppeles.map((f) {
      if (f.fideleId == fideleId) {
        return f.copyWith(
          justifie: true,
          motifAbsence: motif,
        );
      }
      return f;
    }).toList();

    state = state.copyWith(
      appelEnCours: state.appelEnCours!.copyWith(
        fidelesAppeles: fidelesAppeles,
      ),
    );
  }

  /// Bascule la justification d'un absent (avec ou sans motif)
  void toggleJustification(String fideleId, bool justifie, {String? motif}) {
    if (state.appelEnCours == null) return;

    final fidelesAppeles = state.appelEnCours!.fidelesAppeles.map((f) {
      if (f.fideleId == fideleId) {
        return f.copyWith(
          justifie: justifie,
          motifAbsence: justifie ? (motif ?? f.motifAbsence) : null,
        );
      }
      return f;
    }).toList();

    state = state.copyWith(
      appelEnCours: state.appelEnCours!.copyWith(
        fidelesAppeles: fidelesAppeles,
      ),
    );
  }

  /// Enregistre l'appel
  Future<bool> enregistrerAppel() async {
    if (state.appelEnCours == null || _userId == null) return false;

    state = state.copyWith(isSaving: true, error: null);

    try {
      // Crée la session
      final session = await _repository.createSession(
        date: state.appelEnCours!.date,
        typeGroupe: state.appelEnCours!.typeGroupe,
        groupeId: state.appelEnCours!.groupeId,
        createdBy: _userId!,
      );

      // Crée les présences
      final presences = state.appelEnCours!.fidelesAppeles.map((f) {
        return PresenceModel(
          id: '',
          sessionId: session.id,
          fideleId: f.fideleId,
          statut: f.statut!,
          justifie: f.justifie,
          motifAbsence: f.motifAbsence,
          createdAt: DateTime.now(),
        );
      }).toList();

      await _repository.enregistrerPresences(
        sessionId: session.id,
        presences: presences,
      );

      state = state.copyWith(
        isSaving: false,
        appelEnCours: null,
        successMessage: 'Appel enregistré avec succès',
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Annule l'appel en cours
  void annulerAppel() {
    state = const AppelState();
  }

  /// Efface les messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

/// Provider pour l'appel en cours
final appelProvider = StateNotifierProvider<AppelNotifier, AppelState>((ref) {
  final repository = ref.watch(presenceRepositoryProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  return AppelNotifier(repository, userId);
});

/// Provider pour l'historique des sessions d'un groupe
final historiqueSessionsProvider = FutureProvider.family<
    List<SessionAppelModel>,
    ({TypeGroupe typeGroupe, String groupeId})>((ref, params) async {
  final repository = ref.watch(presenceRepositoryProvider);
  return await repository.getSessionsByGroupe(
    typeGroupe: params.typeGroupe,
    groupeId: params.groupeId,
  );
});

/// Provider pour les présences d'une session
final presencesSessionProvider =
    FutureProvider.family<List<PresenceModel>, String>((ref, sessionId) async {
  final repository = ref.watch(presenceRepositoryProvider);
  return await repository.getPresencesBySession(sessionId);
});

/// Provider pour le taux de présence d'un groupe
final tauxPresenceProvider = FutureProvider.family<double,
    ({TypeGroupe typeGroupe, String groupeId})>((ref, params) async {
  final repository = ref.watch(presenceRepositoryProvider);
  return await repository.getTauxPresence(
    typeGroupe: params.typeGroupe,
    groupeId: params.groupeId,
  );
});

/// Provider pour la dernière session d'un groupe
final derniereSessionProvider = FutureProvider.family<SessionAppelModel?,
    ({TypeGroupe typeGroupe, String groupeId})>((ref, params) async {
  final repository = ref.watch(presenceRepositoryProvider);
  return await repository.getDerniereSession(
    typeGroupe: params.typeGroupe,
    groupeId: params.groupeId,
  );
});

/// Provider pour les absences consécutives d'un fidèle
final absencesConsecutivesProvider =
    FutureProvider.family<int, String>((ref, fideleId) async {
  final repository = ref.watch(presenceRepositoryProvider);
  return await repository.getAbsencesConsecutives(fideleId);
});

/// Provider pour l'historique des présences d'un fidèle
final historiqueFideleProvider =
    FutureProvider.family<List<PresenceModel>, String>((ref, fideleId) async {
  final repository = ref.watch(presenceRepositoryProvider);
  return await repository.getHistoriqueFidele(fideleId);
});
