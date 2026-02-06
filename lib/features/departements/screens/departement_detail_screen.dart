import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/fidele_model.dart';
import '../../../providers/departement_provider.dart';
import '../../../providers/fidele_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../fideles/widgets/fidele_card.dart';

class DepartementDetailScreen extends ConsumerStatefulWidget {
  final String departementId;

  const DepartementDetailScreen({super.key, required this.departementId});

  @override
  ConsumerState<DepartementDetailScreen> createState() =>
      _DepartementDetailScreenState();
}

class _DepartementDetailScreenState
    extends ConsumerState<DepartementDetailScreen> {
  // Filtre: null = tous, true = actifs, false = inactifs
  bool? _filtreActif;

  List<FideleModel> _filtrerBoss(List<FideleModel> boss) {
    if (_filtreActif == null) return boss;
    return boss.where((b) => b.actif == _filtreActif).toList();
  }

  @override
  Widget build(BuildContext context) {
    final deptAsync = ref.watch(departementByIdProvider(widget.departementId));
    final bossAsync =
        ref.watch(fidelesByDepartementProvider(widget.departementId));
    final isPasteur = ref.watch(isPasteurProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du département'),
        actions: [
          if (isPasteur)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Navigate to departement form
              },
            ),
        ],
      ),
      body: deptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
        data: (dept) {
          if (dept == null) {
            return const Center(child: Text('Département non trouvé'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSizes.paddingL),
                          decoration: BoxDecoration(
                            color: AppColors.responsableColor.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.business,
                            size: 48,
                            color: AppColors.responsableColor,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingM),
                        Text(
                          dept.nom,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (dept.responsableNom != null) ...[
                          const SizedBox(height: AppSizes.paddingXS),
                          Text(
                            'Responsable: ${dept.responsableNom}',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                        if (dept.description != null &&
                            dept.description!.isNotEmpty) ...[
                          const SizedBox(height: AppSizes.paddingS),
                          Text(
                            dept.description!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: AppSizes.paddingM),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat(
                                context, 'BOSS', dept.nombreMembres?.toString() ?? '0'),
                            _buildStat(context, 'Actifs',
                                dept.nombreMembresActifs?.toString() ?? '0'),
                            _buildStat(
                              context,
                              'Taux',
                              '${dept.tauxActifs.toStringAsFixed(0)}%',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.paddingM),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.goToAppel(
                            TypeGroupe.departement, widget.departementId),
                        icon: const Icon(Icons.fact_check),
                        label: const Text(AppStrings.faireAppel),
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingM),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.goToHistorique(
                            TypeGroupe.departement, widget.departementId),
                        icon: const Icon(Icons.history),
                        label: const Text('Historique'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.paddingL),

                // Titre et filtre BOSS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BOSS (${dept.nombreMembres ?? 0})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    // Menu filtre
                    PopupMenuButton<bool?>(
                      icon: Icon(
                        Icons.filter_list,
                        color: _filtreActif != null
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      tooltip: 'Filtrer',
                      onSelected: (value) {
                        setState(() => _filtreActif = value);
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: null,
                          child: Row(
                            children: [
                              Icon(
                                Icons.people,
                                color: _filtreActif == null
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              const Text('Tous les BOSS'),
                              if (_filtreActif == null)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(Icons.check,
                                      color: AppColors.primary, size: 18),
                                ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: true,
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: _filtreActif == true
                                    ? AppColors.actif
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              const Text('BOSS Actifs'),
                              if (_filtreActif == true)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(Icons.check,
                                      color: AppColors.actif, size: 18),
                                ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: false,
                          child: Row(
                            children: [
                              Icon(
                                Icons.cancel,
                                color: _filtreActif == false
                                    ? AppColors.inactif
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              const Text('BOSS Inactifs'),
                              if (_filtreActif == false)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(Icons.check,
                                      color: AppColors.inactif, size: 18),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Chips de filtre actif
                if (_filtreActif != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.paddingS),
                    child: Chip(
                      label: Text(
                        _filtreActif == true ? 'Actifs' : 'Inactifs',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: _filtreActif == true
                          ? AppColors.actif.withAlpha(30)
                          : AppColors.inactif.withAlpha(30),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => setState(() => _filtreActif = null),
                    ),
                  ),

                const SizedBox(height: AppSizes.paddingS),

                // Info BOSS
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingS),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(20),
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: AppColors.secondary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'BOSS = Bon Ouvrier au Service du SEIGNEUR',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.paddingM),

                // Liste des BOSS
                bossAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text('Erreur: $error'),
                  data: (boss) {
                    final bossFiltres = _filtrerBoss(boss);

                    if (boss.isEmpty) {
                      return Center(
                        child: Column(
                          children: [
                            const SizedBox(height: AppSizes.paddingL),
                            Icon(Icons.people_outline,
                                size: 48, color: AppColors.textHint),
                            const SizedBox(height: AppSizes.paddingS),
                            const Text('Aucun BOSS dans ce département'),
                          ],
                        ),
                      );
                    }

                    if (bossFiltres.isEmpty) {
                      return Center(
                        child: Column(
                          children: [
                            const SizedBox(height: AppSizes.paddingL),
                            Icon(
                              _filtreActif == true
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined,
                              size: 48,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: AppSizes.paddingS),
                            Text(
                              _filtreActif == true
                                  ? 'Aucun BOSS actif'
                                  : 'Aucun BOSS inactif',
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bossFiltres.length,
                      itemBuilder: (context, index) {
                        final fidele = bossFiltres[index];
                        return FideleCard(
                          fidele: fidele,
                          onTap: () => context.goToFidele(fidele.id),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
