import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/helpers.dart';
import '../../../providers/fidele_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/tribu_provider.dart';
import '../../../providers/departement_provider.dart';
import '../../../providers/cellule_provider.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../../data/services/supabase_service.dart';

class FideleDetailScreen extends ConsumerWidget {
  final String fideleId;

  const FideleDetailScreen({super.key, required this.fideleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fideleAsync = ref.watch(fideleByIdProvider(fideleId));
    final isPasteur = ref.watch(isPasteurProvider);
    final isPatriarche = ref.watch(isPatriarcheProvider);
    final canEdit = isPasteur || isPatriarche;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du fidèle'),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.go('${AppRoutes.fideleForm}?id=$fideleId'),
            ),
          if (isPasteur)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                final fidele = fideleAsync.valueOrNull;
                if (fidele == null) return;
                switch (value) {
                  case 'reassign_dept':
                    _showReassignDepartementDialog(context, ref, fidele.id);
                    break;
                  case 'reassign_cellule':
                    _showReassignCelluleDialog(context, ref, fidele.id);
                    break;
                  case 'change_role':
                    _showChangeRoleDialog(context, ref, fidele.id, fidele.nomComplet);
                    break;
                  case 'delete':
                    _showDeleteDialog(context, ref, fidele.id, fidele.nomComplet);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'reassign_dept',
                  child: Row(
                    children: [
                      Icon(Icons.business_rounded, color: AppColors.responsableColor, size: 20),
                      SizedBox(width: 12),
                      Text('Réaffecter département'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reassign_cellule',
                  child: Row(
                    children: [
                      Icon(Icons.cell_tower_rounded, color: AppColors.secondary, size: 20),
                      SizedBox(width: 12),
                      Text('Réaffecter cellule'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'change_role',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz_rounded, color: AppColors.warning, size: 20),
                      SizedBox(width: 12),
                      Text('Changer le rôle'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 20),
                      SizedBox(width: 12),
                      Text('Supprimer', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: fideleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: AppColors.error),
              const SizedBox(height: AppSizes.paddingM),
              Text('Erreur: $error'),
            ],
          ),
        ),
        data: (fidele) {
          if (fidele == null) {
            return const Center(child: Text('Fidèle non trouvé'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Column(
              children: [
                // Avatar et nom
                AvatarWidget(
                  name: fidele.nomComplet,
                  photoUrl: fidele.photoUrl,
                  size: AppSizes.avatarXL,
                ),
                const SizedBox(height: AppSizes.paddingM),
                Text(
                  fidele.nomComplet,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSizes.paddingXS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                    vertical: AppSizes.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    color: fidele.actif
                        ? AppColors.actif.withAlpha(25)
                        : AppColors.inactif.withAlpha(25),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    fidele.actif ? AppStrings.actif : AppStrings.inactif,
                    style: TextStyle(
                      color: fidele.actif ? AppColors.actif : AppColors.inactif,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.paddingL),

                // Informations
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          context,
                          Icons.person,
                          AppStrings.sexe,
                          Helpers.getSexeText(fidele.sexe.name),
                        ),
                        const Divider(),
                        _buildInfoRow(
                          context,
                          Icons.cake,
                          AppStrings.dateNaissance,
                          fidele.dateNaissanceFormatee.isNotEmpty
                              ? fidele.dateNaissanceFormatee
                              : 'Non renseigné',
                        ),
                        if (fidele.telephone != null) ...[
                          const Divider(),
                          _buildInfoRow(
                            context,
                            Icons.phone,
                            AppStrings.telephone,
                            fidele.telephone!,
                          ),
                        ],
                        if (fidele.adresse != null) ...[
                          const Divider(),
                          _buildInfoRow(
                            context,
                            Icons.location_on,
                            AppStrings.adresse,
                            fidele.adresse!,
                          ),
                        ],
                        if (fidele.profession != null) ...[
                          const Divider(),
                          _buildInfoRow(
                            context,
                            Icons.work,
                            AppStrings.profession,
                            fidele.profession!,
                          ),
                        ],
                        const Divider(),
                        _buildInfoRow(
                          context,
                          Icons.groups,
                          AppStrings.tribu,
                          fidele.tribuNom ?? 'Non assigné',
                        ),
                        if (fidele.celluleNom != null) ...[
                          const Divider(),
                          _buildInfoRow(
                            context,
                            Icons.cell_tower,
                            'Cellule',
                            fidele.celluleNom!,
                          ),
                        ],
                        if (fidele.inviteParNom != null) ...[
                          const Divider(),
                          _buildInfoRow(
                            context,
                            Icons.person_add,
                            AppStrings.invitePar,
                            fidele.inviteParNom!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.paddingM),

                // Actions
                if (canEdit) ...[
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            fidele.actif ? Icons.block : Icons.check_circle,
                            color: fidele.actif ? AppColors.error : AppColors.actif,
                          ),
                          title: Text(
                            fidele.actif
                                ? 'Marquer comme inactif'
                                : 'Marquer comme actif',
                          ),
                          onTap: () async {
                            final success = await ref
                                .read(fidelesProvider.notifier)
                                .setActif(fidele.id, !fidele.actif);
                            if (success) {
                              ref.invalidate(fideleByIdProvider(fideleId));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Dialogue pour réaffecter un fidèle dans un autre département
  void _showReassignDepartementDialog(BuildContext context, WidgetRef ref, String fideleId) {
    final departementsState = ref.read(departementsProvider);
    if (departementsState.departements.isEmpty) {
      ref.read(departementsProvider.notifier).loadAllWithStats();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final depts = ref.watch(departementsProvider);
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.6,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Icon(Icons.business_rounded, color: AppColors.responsableColor),
                          SizedBox(width: 12),
                          Text(
                            'Réaffecter dans un département',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Option: Retirer de tous les départements
                ListTile(
                  leading: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                  title: const Text('Retirer de tous les départements'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    // Supprimer toutes les entrées fidele_departements
                    try {
                      await SupabaseService.instance.fideleDepartements
                          .delete()
                          .eq('fidele_id', fideleId);
                      ref.invalidate(fideleByIdProvider(fideleId));
                      if (context.mounted) {
                        context.showSuccessSnackBar('Fidèle retiré de tous les départements');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        context.showErrorSnackBar('Erreur: $e');
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                if (depts.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: depts.departements.length,
                      itemBuilder: (ctx, index) {
                        final dept = depts.departements[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.responsableColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.business_rounded,
                                color: AppColors.responsableColor, size: 20),
                          ),
                          title: Text(dept.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${dept.nombreMembres ?? 0} membres'),
                          trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                          onTap: () async {
                            Navigator.pop(ctx);
                            try {
                              // Ajouter au département
                              await ref.read(departementsProvider.notifier)
                                  .addFidele(dept.id, fideleId);
                              ref.invalidate(fideleByIdProvider(fideleId));
                              if (context.mounted) {
                                context.showSuccessSnackBar(
                                    'Fidèle ajouté au département ${dept.nom}');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                context.showErrorSnackBar('Erreur: $e');
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Dialogue pour réaffecter un fidèle dans une cellule
  void _showReassignCelluleDialog(BuildContext context, WidgetRef ref, String fideleId) {
    final cellulesState = ref.read(cellulesProvider);
    if (cellulesState.cellules.isEmpty) {
      ref.read(cellulesProvider.notifier).loadAllWithStats();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final cells = ref.watch(cellulesProvider);
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.6,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Icon(Icons.cell_tower_rounded, color: AppColors.secondary),
                          SizedBox(width: 12),
                          Text(
                            'Réaffecter dans une cellule',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Option: Retirer de la cellule
                ListTile(
                  leading: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                  title: const Text('Retirer de la cellule actuelle'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await SupabaseService.instance.fideles
                          .update({'cellule_id': null})
                          .eq('id', fideleId);
                      ref.invalidate(fideleByIdProvider(fideleId));
                      if (context.mounted) {
                        context.showSuccessSnackBar('Fidèle retiré de la cellule');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        context.showErrorSnackBar('Erreur: $e');
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                if (cells.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: cells.cellules.length,
                      itemBuilder: (ctx, index) {
                        final cellule = cells.cellules[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.cell_tower_rounded,
                                color: AppColors.secondary, size: 20),
                          ),
                          title: Text(cellule.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${cellule.nombreMembres ?? 0} membres'),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
                          onTap: () async {
                            Navigator.pop(ctx);
                            try {
                              await SupabaseService.instance.fideles
                                  .update({'cellule_id': cellule.id})
                                  .eq('id', fideleId);
                              ref.invalidate(fideleByIdProvider(fideleId));
                              if (context.mounted) {
                                context.showSuccessSnackBar(
                                    'Fidèle affecté à la cellule ${cellule.nom}');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                context.showErrorSnackBar('Erreur: $e');
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Dialogue pour changer le rôle (rétrograder un responsable/patriarche)
  void _showChangeRoleDialog(BuildContext context, WidgetRef ref, String fideleId, String nomComplet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Changer le rôle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modifier le rôle de $nomComplet:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Si cette personne est responsable ou patriarche, '
                      'elle perdra son accès de gestion.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              _retrograderFidele(context, ref, fideleId, nomComplet);
            },
            icon: const Icon(Icons.arrow_downward, size: 18),
            label: const Text('Rétrograder en fidèle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  /// Rétrograde un responsable/patriarche en simple fidèle
  Future<void> _retrograderFidele(
    BuildContext context, WidgetRef ref, String fideleId, String nomComplet,
  ) async {
    // Indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final supabase = SupabaseService.instance;

      // Retirer le patriarche des tribus
      await supabase.tribus
          .update({'patriarche_id': null})
          .eq('patriarche_id', fideleId);

      // Retirer le responsable des départements
      await supabase.departements
          .update({'responsable_id': null})
          .eq('responsable_id', fideleId);

      // Retirer le responsable des cellules
      await supabase.cellules
          .update({'responsable_id': null})
          .eq('responsable_id', fideleId);

      // Fermer le loading
      if (context.mounted) Navigator.pop(context);

      // Rafraîchir
      ref.invalidate(fideleByIdProvider(fideleId));
      ref.invalidate(tribusProvider);
      ref.invalidate(departementsProvider);
      ref.invalidate(cellulesProvider);

      if (context.mounted) {
        context.showSuccessSnackBar(
            '$nomComplet a été rétrogradé en simple fidèle');
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        context.showErrorSnackBar('Erreur: $e');
      }
    }
  }

  /// Dialogue de confirmation pour supprimer un fidèle
  void _showDeleteDialog(BuildContext context, WidgetRef ref, String fideleId, String nomComplet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.error),
            SizedBox(width: 12),
            Text('Supprimer le fidèle'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: AppColors.textPrimary),
                children: [
                  const TextSpan(text: 'Voulez-vous vraiment supprimer '),
                  TextSpan(
                    text: nomComplet,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' ?'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cette action est irréversible. Toutes les données '
                      'associées seront supprimées.',
                      style: TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(fidelesProvider.notifier).delete(fideleId);
              if (success && context.mounted) {
                context.showSuccessSnackBar('$nomComplet a été supprimé');
                context.go(AppRoutes.dashboard);
              } else if (context.mounted) {
                context.showErrorSnackBar('Erreur lors de la suppression');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconS, color: AppColors.textSecondary),
          const SizedBox(width: AppSizes.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
