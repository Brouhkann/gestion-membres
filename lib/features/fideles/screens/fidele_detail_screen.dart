import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../../../providers/fidele_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/avatar_widget.dart';

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
                        ? AppColors.actif.withOpacity(0.1)
                        : AppColors.inactif.withOpacity(0.1),
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
