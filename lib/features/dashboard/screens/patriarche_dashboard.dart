import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/enums.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/fidele_provider.dart';
import '../../../providers/tribu_provider.dart';
import '../../../providers/anniversaire_provider.dart';
import '../../../providers/presence_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/anniversaire_card.dart';
import '../widgets/menu_item_card.dart';

class PatriarcheDashboard extends ConsumerStatefulWidget {
  const PatriarcheDashboard({super.key});

  @override
  ConsumerState<PatriarcheDashboard> createState() =>
      _PatriarcheDashboardState();
}

class _PatriarcheDashboardState extends ConsumerState<PatriarcheDashboard> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final tribuId = ref.watch(userTribuIdProvider);
    final mesFideles = ref.watch(mesFidelesProvider);
    final mesAnniversaires = ref.watch(mesAnniversairesProvider);

    // Tribu info
    final tribuInfo = tribuId != null
        ? ref.watch(tribuByIdProvider(tribuId))
        : const AsyncValue.data(null);

    // Dernière session d'appel
    final derniereSession = tribuId != null
        ? ref.watch(derniereSessionProvider(
            (typeGroupe: TypeGroupe.tribu, groupeId: tribuId)))
        : const AsyncValue.data(null);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(mesFidelesProvider);
          ref.invalidate(mesAnniversairesProvider);
          if (tribuId != null) {
            ref.invalidate(tribuByIdProvider(tribuId));
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Salutation
              Text(
                '${Helpers.getGreeting()}, ${user?.prenom ?? ""}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.groups,
                    size: AppSizes.iconS,
                    color: AppColors.patriarcheColor,
                  ),
                  const SizedBox(width: AppSizes.paddingXS),
                  Text(
                    '${AppStrings.patriarche} - ${tribuInfo.valueOrNull?.nom ?? "Ma tribu"}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.patriarcheColor,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingL),

              // Statistiques de la tribu
              mesFideles.when(
                data: (fideles) {
                  final actifs = fideles.where((f) => f.actif).length;
                  return Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Membres',
                          value: fideles.length.toString(),
                          icon: Icons.people,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSizes.paddingM),
                      Expanded(
                        child: StatCard(
                          title: 'Actifs',
                          value: actifs.toString(),
                          icon: Icons.check_circle,
                          color: AppColors.actif,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Erreur de chargement'),
              ),

              const SizedBox(height: AppSizes.paddingL),

              // Anniversaires de la tribu
              Text(
                'Anniversaires de ma tribu',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSizes.paddingS),

              mesAnniversaires.when(
                data: (anniversaires) => AnniversaireCard(
                  countAujourdhui:
                      anniversaires[PeriodeAnniversaire.aujourdhui]?.length ?? 0,
                  countSemaine:
                      anniversaires[PeriodeAnniversaire.cetteSemaine]?.length ??
                          0,
                  countMois:
                      anniversaires[PeriodeAnniversaire.ceMois]?.length ?? 0,
                  onTap: () => context.go(AppRoutes.anniversaires),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Erreur de chargement'),
              ),

              const SizedBox(height: AppSizes.paddingL),

              // Dernier appel
              Text(
                'Dernier appel',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSizes.paddingS),

              derniereSession.when(
                data: (session) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.fact_check, color: Colors.white),
                    ),
                    title: Text(
                      session != null
                          ? 'Appel du ${session.dateFormatee}'
                          : 'Aucun appel',
                    ),
                    subtitle: session != null
                        ? Text(
                            '${session.nombrePresents ?? 0} présents / ${session.totalMembres ?? 0} membres')
                        : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: tribuId != null
                        ? () => context.goToHistorique(
                              TypeGroupe.tribu,
                              tribuId,
                            )
                        : null,
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Erreur de chargement'),
              ),

              const SizedBox(height: AppSizes.paddingL),

              // Actions rapides
              Text(
                'Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSizes.paddingS),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: AppSizes.paddingM,
                crossAxisSpacing: AppSizes.paddingM,
                childAspectRatio: 1.3,
                children: [
                  MenuItemCard(
                    title: AppStrings.faireAppel,
                    icon: Icons.fact_check,
                    color: AppColors.primary,
                    onTap: tribuId != null
                        ? () => context.goToAppel(TypeGroupe.tribu, tribuId)
                        : null,
                  ),
                  MenuItemCard(
                    title: AppStrings.nouveauFidele,
                    icon: Icons.person_add,
                    color: AppColors.actif,
                    onTap: () => context.go(AppRoutes.fideleForm),
                  ),
                  MenuItemCard(
                    title: 'Mes membres',
                    icon: Icons.people,
                    color: AppColors.patriarcheColor,
                    onTap: () => context.go(AppRoutes.fideles),
                  ),
                  MenuItemCard(
                    title: AppStrings.anniversaires,
                    icon: Icons.cake,
                    color: AppColors.secondary,
                    onTap: () => context.go(AppRoutes.anniversaires),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
