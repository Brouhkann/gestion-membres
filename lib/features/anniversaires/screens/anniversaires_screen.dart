import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/fidele_model.dart';
import '../../../providers/anniversaire_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/avatar_widget.dart';

class AnniversairesScreen extends ConsumerStatefulWidget {
  const AnniversairesScreen({super.key});

  @override
  ConsumerState<AnniversairesScreen> createState() => _AnniversairesScreenState();
}

class _AnniversairesScreenState extends ConsumerState<AnniversairesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPasteur = ref.watch(isPasteurProvider);
    final isPatriarche = ref.watch(isPatriarcheProvider);

    // Sélectionne le bon provider selon le rôle
    final anniversairesAsync = isPasteur
        ? ref.watch(anniversairesStatsProvider)
        : isPatriarche
            ? ref.watch(mesAnniversairesProvider)
            : ref.watch(anniversairesStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.anniversaires),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Aujourd'hui"),
            Tab(text: 'Semaine'),
            Tab(text: 'Mois'),
          ],
        ),
      ),
      body: anniversairesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
        data: (data) {
          List<FideleModel> aujourdhui;
          List<FideleModel> semaine;
          List<FideleModel> mois;

          if (data is AnniversairesStats) {
            aujourdhui = data.aujourdhui;
            semaine = data.cetteSemaine;
            mois = data.ceMois;
          } else if (data is Map<PeriodeAnniversaire, List<FideleModel>>) {
            aujourdhui = data[PeriodeAnniversaire.aujourdhui] ?? [];
            semaine = data[PeriodeAnniversaire.cetteSemaine] ?? [];
            mois = data[PeriodeAnniversaire.ceMois] ?? [];
          } else {
            aujourdhui = [];
            semaine = [];
            mois = [];
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(context, aujourdhui, "Aucun anniversaire aujourd'hui"),
              _buildList(context, semaine, 'Aucun anniversaire cette semaine'),
              _buildList(context, mois, 'Aucun anniversaire ce mois'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<FideleModel> fideles, String emptyMessage) {
    if (fideles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cake_outlined, size: 64, color: AppColors.textHint),
            const SizedBox(height: AppSizes.paddingM),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      itemCount: fideles.length,
      itemBuilder: (context, index) {
        final fidele = fideles[index];
        return _AnniversaireCard(
          fidele: fidele,
          onTap: () => context.goToFidele(fidele.id),
        );
      },
    );
  }
}

class _AnniversaireCard extends StatelessWidget {
  final FideleModel fidele;
  final VoidCallback? onTap;

  const _AnniversaireCard({
    required this.fidele,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = fidele.isAnniversaireAujourdhui;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
      color: isToday ? AppColors.secondary.withOpacity(0.1) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Row(
            children: [
              // Avatar avec badge
              Stack(
                children: [
                  AvatarWidget(
                    name: fidele.nomComplet,
                    photoUrl: fidele.photoUrl,
                    size: AppSizes.avatarM,
                  ),
                  if (isToday)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cake,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSizes.paddingM),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fidele.nomComplet,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppSizes.paddingXS),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: AppSizes.iconXS,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fidele.dateNaissanceFormatee,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        if (fidele.tribuNom != null) ...[
                          const SizedBox(width: AppSizes.paddingM),
                          const Icon(
                            Icons.groups,
                            size: AppSizes.iconXS,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            fidele.tribuNom!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Jours restants
              if (!isToday && fidele.joursJusquAnniversaire != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingS,
                    vertical: AppSizes.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  child: Text(
                    'J-${fidele.joursJusquAnniversaire}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
