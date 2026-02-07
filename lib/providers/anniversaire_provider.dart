import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/fidele_model.dart';
import '../data/models/enums.dart';
import '../data/repositories/fidele_repository.dart';
import 'auth_provider.dart';

/// Provider pour les anniversaires du jour
final anniversairesAujourdhuiProvider =
    FutureProvider<List<FideleModel>>((ref) async {
  final repository = ref.watch(fideleRepositoryProvider);
  return await repository.getAnniversairesAujourdhui();
});

/// Provider pour les anniversaires de la semaine
final anniversairesSemaineProvider =
    FutureProvider<List<FideleModel>>((ref) async {
  final repository = ref.watch(fideleRepositoryProvider);
  return await repository.getAnniversairesSemaine();
});

/// Provider pour les anniversaires du mois
final anniversairesMoisProvider =
    FutureProvider<List<FideleModel>>((ref) async {
  final repository = ref.watch(fideleRepositoryProvider);
  return await repository.getAnniversairesMois();
});

/// Provider pour les anniversaires d'une tribu
final anniversairesTribuProvider =
    FutureProvider.family<Map<PeriodeAnniversaire, List<FideleModel>>, String>(
        (ref, tribuId) async {
  final repository = ref.watch(fideleRepositoryProvider);

  // Récupère tous les fidèles de la tribu
  final fideles = await repository.getByTribu(tribuId);

  // Filtre par période
  final aujourdhui = fideles.where((f) => f.isAnniversaireAujourdhui).toList();
  final semaine = fideles.where((f) => f.isAnniversaireCetteSemaine).toList();
  final mois = fideles.where((f) => f.isAnniversaireCeMois).toList();

  return {
    PeriodeAnniversaire.aujourdhui: aujourdhui,
    PeriodeAnniversaire.cetteSemaine: semaine,
    PeriodeAnniversaire.ceMois: mois,
  };
});

/// Provider pour les anniversaires de la tribu de l'utilisateur (patriarche)
final mesAnniversairesProvider =
    FutureProvider<Map<PeriodeAnniversaire, List<FideleModel>>>((ref) async {
  final tribuId = ref.watch(userTribuIdProvider);
  if (tribuId == null) {
    return {
      PeriodeAnniversaire.aujourdhui: [],
      PeriodeAnniversaire.cetteSemaine: [],
      PeriodeAnniversaire.ceMois: [],
    };
  }

  final repository = ref.watch(fideleRepositoryProvider);
  final fideles = await repository.getByTribu(tribuId);

  final aujourdhui = fideles.where((f) => f.isAnniversaireAujourdhui).toList();
  final semaine = fideles.where((f) => f.isAnniversaireCetteSemaine).toList();
  final mois = fideles.where((f) => f.isAnniversaireCeMois).toList();

  return {
    PeriodeAnniversaire.aujourdhui: aujourdhui,
    PeriodeAnniversaire.cetteSemaine: semaine,
    PeriodeAnniversaire.ceMois: mois,
  };
});

/// Provider pour les statistiques globales des anniversaires (pasteur)
final anniversairesStatsProvider = FutureProvider<AnniversairesStats>((ref) async {
  final repository = ref.watch(fideleRepositoryProvider);

  try {
    final aujourdhui = await repository.getAnniversairesAujourdhui();
    final semaine = await repository.getAnniversairesSemaine();
    final mois = await repository.getAnniversairesMois();

    return AnniversairesStats(
      aujourdhui: aujourdhui,
      cetteSemaine: semaine,
      ceMois: mois,
    );
  } catch (e) {
    // En cas d'erreur, essayer au moins de récupérer ce qui marche
    List<FideleModel> aujourdhui = [];
    List<FideleModel> semaine = [];
    List<FideleModel> mois = [];

    try { aujourdhui = await repository.getAnniversairesAujourdhui(); } catch (_) {}
    try { semaine = await repository.getAnniversairesSemaine(); } catch (_) {}
    try { mois = await repository.getAnniversairesMois(); } catch (_) {}

    return AnniversairesStats(
      aujourdhui: aujourdhui,
      cetteSemaine: semaine,
      ceMois: mois,
    );
  }
});

/// Classe pour les statistiques d'anniversaires
class AnniversairesStats {
  final List<FideleModel> aujourdhui;
  final List<FideleModel> cetteSemaine;
  final List<FideleModel> ceMois;

  const AnniversairesStats({
    required this.aujourdhui,
    required this.cetteSemaine,
    required this.ceMois,
  });

  int get countAujourdhui => aujourdhui.length;
  int get countSemaine => cetteSemaine.length;
  int get countMois => ceMois.length;

  bool get hasAnniversairesAujourdhui => aujourdhui.isNotEmpty;
  bool get hasAnniversairesSemaine => cetteSemaine.isNotEmpty;
  bool get hasAnniversairesMois => ceMois.isNotEmpty;
}

/// Provider du repository des fidèles (réexport pour cohérence)
final fideleRepositoryProvider = Provider<FideleRepository>((ref) {
  return FideleRepository();
});
