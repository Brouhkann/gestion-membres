import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/fidele_provider.dart';
import '../../../providers/tribu_provider.dart';
import '../../../providers/departement_provider.dart';
import '../../../providers/anniversaire_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/anniversaire_card.dart';
import '../widgets/menu_item_card.dart';

class PasteurDashboard extends ConsumerStatefulWidget {
  const PasteurDashboard({super.key});

  @override
  ConsumerState<PasteurDashboard> createState() => _PasteurDashboardState();
}

class _PasteurDashboardState extends ConsumerState<PasteurDashboard> {
  @override
  void initState() {
    super.initState();
    // Utilise addPostFrameCallback pour éviter l'erreur de modification pendant le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // Charge les données au démarrage
    ref.read(tribusProvider.notifier).loadAllWithStats();
    ref.read(departementsProvider.notifier).loadAllWithStats();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final fidelesCount = ref.watch(fidelesCountProvider);
    final fidelesActifsCount = ref.watch(fidelesActifsCountProvider);
    final tribusCount = ref.watch(tribusCountProvider);
    final departementsCount = ref.watch(departementsCountProvider);
    final anniversairesStats = ref.watch(anniversairesStatsProvider);

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
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Salutation
              Text(
                '${Helpers.getGreeting()}, ${user?.prenom ?? "Pasteur"}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                AppStrings.pasteur,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.pasteurColor,
                    ),
              ),

              const SizedBox(height: AppSizes.paddingL),

              // Statistiques
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: AppStrings.totalFideles,
                      value: fidelesCount.when(
                        data: (count) => count.toString(),
                        loading: () => '...',
                        error: (_, __) => '-',
                      ),
                      icon: Icons.people,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingM),
                  Expanded(
                    child: StatCard(
                      title: AppStrings.membresActifs,
                      value: fidelesActifsCount.when(
                        data: (count) => count.toString(),
                        loading: () => '...',
                        error: (_, __) => '-',
                      ),
                      icon: Icons.check_circle,
                      color: AppColors.actif,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingM),

              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: AppStrings.tribus,
                      value: tribusCount.when(
                        data: (count) => count.toString(),
                        loading: () => '...',
                        error: (_, __) => '-',
                      ),
                      icon: Icons.groups,
                      color: AppColors.patriarcheColor,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingM),
                  Expanded(
                    child: StatCard(
                      title: AppStrings.departements,
                      value: departementsCount.when(
                        data: (count) => count.toString(),
                        loading: () => '...',
                        error: (_, __) => '-',
                      ),
                      icon: Icons.business,
                      color: AppColors.responsableColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.paddingL),

              // Anniversaires
              Text(
                AppStrings.anniversaires,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSizes.paddingS),

              anniversairesStats.when(
                data: (stats) => AnniversaireCard(
                  countAujourdhui: stats.countAujourdhui,
                  countSemaine: stats.countSemaine,
                  countMois: stats.countMois,
                  onTap: () => context.go(AppRoutes.anniversaires),
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (_, __) => const Text('Erreur de chargement'),
              ),

              const SizedBox(height: AppSizes.paddingL),

              // Menu rapide
              Text(
                'Accès rapide',
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
                    title: AppStrings.fideles,
                    icon: Icons.people,
                    color: AppColors.primary,
                    onTap: () => context.go(AppRoutes.fideles),
                  ),
                  MenuItemCard(
                    title: AppStrings.tribus,
                    icon: Icons.groups,
                    color: AppColors.patriarcheColor,
                    onTap: () => context.go(AppRoutes.tribus),
                  ),
                  MenuItemCard(
                    title: AppStrings.departements,
                    icon: Icons.business,
                    color: AppColors.responsableColor,
                    onTap: () => context.go(AppRoutes.departements),
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
