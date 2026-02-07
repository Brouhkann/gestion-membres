import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/fidele_provider.dart';
import '../../../providers/tribu_provider.dart';
import '../../../providers/departement_provider.dart';
import '../../../providers/anniversaire_provider.dart';
import '../widgets/modern_stat_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/anniversaire_widget.dart';
import '../../settings/screens/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
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
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Bar moderne
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primaryLight,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${Helpers.getGreeting()},',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withAlpha(200),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.prenom ?? 'Pasteur',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings_outlined, color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Contenu
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistiques en grille
                    Row(
                      children: [
                        Expanded(
                          child: ModernStatCard(
                            title: 'Fidèles',
                            value: fidelesCount.when(
                              data: (count) => count.toString(),
                              loading: () => '...',
                              error: (_, __) => '-',
                            ),
                            icon: Icons.people_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF025456), Color(0xFF037A7D)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ModernStatCard(
                            title: 'Actifs',
                            value: fidelesActifsCount.when(
                              data: (count) => count.toString(),
                              loading: () => '...',
                              error: (_, __) => '-',
                            ),
                            icon: Icons.verified_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ModernStatCard(
                            title: 'Tribus',
                            value: tribusCount.when(
                              data: (count) => count.toString(),
                              loading: () => '...',
                              error: (_, __) => '-',
                            ),
                            icon: Icons.groups_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD0C140), Color(0xFFE0D160)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ModernStatCard(
                            title: 'Départements',
                            value: departementsCount.when(
                              data: (count) => count.toString(),
                              loading: () => '...',
                              error: (_, __) => '-',
                            ),
                            icon: Icons.business_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFA31621), Color(0xFFC62828)],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Anniversaires
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Anniversaires',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.anniversaires),
                          child: const Text('Voir tout'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    anniversairesStats.when(
                      data: (stats) => AnniversaireWidget(
                        countAujourdhui: stats.countAujourdhui,
                        countSemaine: stats.countSemaine,
                        countMois: stats.countMois,
                        onTap: () => context.go(AppRoutes.anniversaires),
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Erreur anniversaires: $error',
                                style: const TextStyle(fontSize: 12, color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Actions rapides
                    const Text(
                      'Actions rapides',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: QuickActionCard(
                            icon: Icons.person_add_rounded,
                            label: 'Nouveau\nFidèle',
                            color: AppColors.primary,
                            onTap: () => context.go(AppRoutes.fideleForm),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionCard(
                            icon: Icons.fact_check_rounded,
                            label: 'Faire\nl\'appel',
                            color: AppColors.secondary,
                            onTap: () => context.go(AppRoutes.tribus),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: QuickActionCard(
                            icon: Icons.groups_rounded,
                            label: 'Nouvelle\nTribu',
                            color: AppColors.patriarcheColor,
                            onTap: () => context.go(AppRoutes.tribus),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 100), // Espace pour la bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
