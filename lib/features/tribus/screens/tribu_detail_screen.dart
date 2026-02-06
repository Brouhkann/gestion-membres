import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/fidele_model.dart';
import '../../../providers/tribu_provider.dart';
import '../../../providers/fidele_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../fideles/widgets/fidele_card.dart';

class TribuDetailScreen extends ConsumerStatefulWidget {
  final String tribuId;

  const TribuDetailScreen({super.key, required this.tribuId});

  @override
  ConsumerState<TribuDetailScreen> createState() => _TribuDetailScreenState();
}

class _TribuDetailScreenState extends ConsumerState<TribuDetailScreen> {
  // Filtre: null = tous, true = actifs, false = inactifs
  bool? _filtreActif;

  List<FideleModel> _filtrerMembres(List<FideleModel> membres) {
    if (_filtreActif == null) return membres;
    return membres.where((m) => m.actif == _filtreActif).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tribuAsync = ref.watch(tribuByIdProvider(widget.tribuId));
    final fidelesAsync = ref.watch(fidelesByTribuProvider(widget.tribuId));
    final isPasteur = ref.watch(isPasteurProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la tribu'),
        actions: [
          if (isPasteur)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Navigate to tribu form
              },
            ),
        ],
      ),
      body: tribuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
        data: (tribu) {
          if (tribu == null) {
            return const Center(child: Text('Tribu non trouvée'));
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
                            color: AppColors.patriarcheColor.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.groups,
                            size: 48,
                            color: AppColors.patriarcheColor,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingM),
                        Text(
                          tribu.nom,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: AppSizes.paddingXS),
                        if (tribu.patriarcheNom != null)
                          Text(
                            'Patriarche: ${tribu.patriarcheNom}',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          )
                        else if (isPasteur)
                          TextButton.icon(
                            onPressed: () => _showSelectPatriarcheDialog(
                              context,
                              ref,
                              widget.tribuId,
                            ),
                            icon: const Icon(Icons.person_add, size: 18),
                            label: const Text('Désigner un patriarche'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.patriarcheColor,
                            ),
                          )
                        else
                          Text(
                            'Pas de patriarche',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textHint,
                                      fontStyle: FontStyle.italic,
                                    ),
                          ),
                        if (tribu.description != null &&
                            tribu.description!.isNotEmpty) ...[
                          const SizedBox(height: AppSizes.paddingS),
                          Text(
                            tribu.description!,
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
                            _buildStat(context, 'Membres',
                                tribu.nombreMembres?.toString() ?? '0'),
                            _buildStat(context, 'Actifs',
                                tribu.nombreMembresActifs?.toString() ?? '0'),
                            _buildStat(
                              context,
                              'Taux',
                              '${tribu.tauxActifs.toStringAsFixed(0)}%',
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
                        onPressed: () =>
                            context.goToAppel(TypeGroupe.tribu, widget.tribuId),
                        icon: const Icon(Icons.fact_check),
                        label: const Text(AppStrings.faireAppel),
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingM),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.goToHistorique(
                            TypeGroupe.tribu, widget.tribuId),
                        icon: const Icon(Icons.history),
                        label: const Text('Historique'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.paddingL),

                // Titre et filtre membres
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Membres (${tribu.nombreMembres ?? 0})',
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
                              const Text('Tous les membres'),
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
                              const Text('Membres actifs'),
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
                              const Text('Membres inactifs'),
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

                const SizedBox(height: AppSizes.paddingM),

                // Liste des membres
                fidelesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text('Erreur: $error'),
                  data: (fideles) {
                    final membresFiltres = _filtrerMembres(fideles);

                    if (fideles.isEmpty) {
                      return Center(
                        child: Column(
                          children: [
                            const SizedBox(height: AppSizes.paddingL),
                            Icon(Icons.people_outline,
                                size: 48, color: AppColors.textHint),
                            const SizedBox(height: AppSizes.paddingS),
                            const Text('Aucun membre dans cette tribu'),
                          ],
                        ),
                      );
                    }

                    if (membresFiltres.isEmpty) {
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
                                  ? 'Aucun membre actif'
                                  : 'Aucun membre inactif',
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: membresFiltres.length,
                      itemBuilder: (context, index) {
                        final fidele = membresFiltres[index];
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

  void _showSelectPatriarcheDialog(
    BuildContext context,
    WidgetRef ref,
    String tribuId,
  ) {
    final fideles = ref.read(fidelesByTribuProvider(tribuId));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.patriarcheColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: AppColors.patriarcheColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Désigner un patriarche',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Sélectionnez un membre avec téléphone',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: fideles.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
                data: (membres) {
                  // Filtre les membres avec téléphone
                  final membresAvecTel = membres
                      .where((m) => m.telephone != null && m.telephone!.isNotEmpty)
                      .toList();

                  if (membresAvecTel.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone_disabled,
                              size: 48,
                              color: AppColors.textHint,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Aucun membre avec numéro de téléphone',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Le patriarche doit avoir un numéro pour se connecter',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: membresAvecTel.length,
                    itemBuilder: (context, index) {
                      final fidele = membresAvecTel[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.patriarcheColor.withAlpha(20),
                          child: Text(
                            fidele.initiales,
                            style: const TextStyle(
                              color: AppColors.patriarcheColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          fidele.nomComplet,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          fidele.telephone ?? '',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.textHint,
                        ),
                        onTap: () => _confirmPatriarcheSelection(
                          context,
                          ref,
                          tribuId,
                          fidele,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPatriarcheSelection(
    BuildContext context,
    WidgetRef ref,
    String tribuId,
    FideleModel fidele,
  ) {
    Navigator.pop(context); // Ferme le bottom sheet

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Confirmer la désignation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: AppColors.textPrimary),
                children: [
                  const TextSpan(text: 'Désigner '),
                  TextSpan(
                    text: fidele.nomComplet,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' comme patriarche ?'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary.withAlpha(50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Compte créé automatiquement',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Identifiant: ${fidele.telephone}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const Text(
                    'Mot de passe: 12345678',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _designerPatriarche(context, ref, tribuId, fidele);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.patriarcheColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _designerPatriarche(
    BuildContext context,
    WidgetRef ref,
    String tribuId,
    FideleModel fidele,
  ) async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final egliseId = ref.read(userEgliseIdProvider);

      // 1. Créer le compte utilisateur
      final user = await ref.read(authProvider.notifier).createResponsableAccount(
        fideleId: fidele.id,
        telephone: fidele.telephone!,
        nom: fidele.nom,
        prenom: fidele.prenom,
        role: UserRole.patriarche,
        egliseId: egliseId!,
        tribuId: tribuId,
      );

      // 2. Mettre à jour la tribu avec le patriarche
      await ref.read(tribusProvider.notifier).setPatriarche(tribuId, fidele.id);

      // Fermer le loading
      if (context.mounted) Navigator.pop(context);

      // Afficher le succès
      if (context.mounted) {
        context.showSuccessSnackBar(
          '${fidele.prenom} est maintenant patriarche. '
          'Identifiant: ${fidele.telephone}, Mot de passe: 12345678',
        );
      }

      // Rafraîchir les données
      ref.invalidate(tribuByIdProvider(tribuId));
    } catch (e) {
      // Fermer le loading
      if (context.mounted) Navigator.pop(context);

      // Afficher l'erreur
      if (context.mounted) {
        context.showErrorSnackBar('Erreur: ${e.toString()}');
      }
    }
  }
}
