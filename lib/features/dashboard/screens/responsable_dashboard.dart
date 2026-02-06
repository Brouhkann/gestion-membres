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
import '../../../providers/departement_provider.dart';
import '../../../providers/presence_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/menu_item_card.dart';

class ResponsableDashboard extends ConsumerStatefulWidget {
  const ResponsableDashboard({super.key});

  @override
  ConsumerState<ResponsableDashboard> createState() =>
      _ResponsableDashboardState();
}

class _ResponsableDashboardState extends ConsumerState<ResponsableDashboard> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final departementId = ref.watch(userDepartementIdProvider);

    // Département info
    final deptInfo = departementId != null
        ? ref.watch(departementByIdProvider(departementId))
        : const AsyncValue.data(null);

    // Membres du département
    final mesMembres = departementId != null
        ? ref.watch(fidelesByDepartementProvider(departementId))
        : const AsyncValue<List<dynamic>>.data([]);

    // Dernière session d'appel
    final derniereSession = departementId != null
        ? ref.watch(derniereSessionProvider(
            (typeGroupe: TypeGroupe.departement, groupeId: departementId)))
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
          if (departementId != null) {
            ref.invalidate(departementByIdProvider(departementId));
            ref.invalidate(fidelesByDepartementProvider(departementId));
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
                    Icons.business,
                    size: AppSizes.iconS,
                    color: AppColors.responsableColor,
                  ),
                  const SizedBox(width: AppSizes.paddingXS),
                  Text(
                    '${AppStrings.responsable} - ${deptInfo.valueOrNull?.nom ?? "Mon département"}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.responsableColor,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingL),

              // Statistiques du département
              mesMembres.when(
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
                      backgroundColor: AppColors.responsableColor,
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
                    onTap: departementId != null
                        ? () => context.goToHistorique(
                              TypeGroupe.departement,
                              departementId,
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
                    color: AppColors.responsableColor,
                    onTap: departementId != null
                        ? () => context.goToAppel(
                            TypeGroupe.departement, departementId)
                        : null,
                  ),
                  MenuItemCard(
                    title: 'Mes membres',
                    icon: Icons.people,
                    color: AppColors.primary,
                    onTap: () => context.go(AppRoutes.fideles),
                  ),
                  MenuItemCard(
                    title: 'Historique',
                    icon: Icons.history,
                    color: AppColors.secondary,
                    onTap: departementId != null
                        ? () => context.goToHistorique(
                            TypeGroupe.departement, departementId)
                        : null,
                  ),
                  MenuItemCard(
                    title: AppStrings.anniversaires,
                    icon: Icons.cake,
                    color: AppColors.warning,
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
