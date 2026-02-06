import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/presence_model.dart';
import '../../../providers/presence_provider.dart';
import '../../../providers/fidele_provider.dart';
import '../../../providers/tribu_provider.dart';
import '../../../providers/departement_provider.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../widgets/membre_appel_card.dart';

class AppelScreen extends ConsumerStatefulWidget {
  final TypeGroupe typeGroupe;
  final String groupeId;

  const AppelScreen({
    super.key,
    required this.typeGroupe,
    required this.groupeId,
  });

  @override
  ConsumerState<AppelScreen> createState() => _AppelScreenState();
}

class _AppelScreenState extends ConsumerState<AppelScreen> {
  @override
  void initState() {
    super.initState();
    _initAppel();
  }

  Future<void> _initAppel() async {
    // Récupère le nom du groupe
    String groupeNom = '';
    if (widget.typeGroupe == TypeGroupe.tribu) {
      final tribu = await ref.read(tribuByIdProvider(widget.groupeId).future);
      groupeNom = tribu?.nom ?? 'Tribu';
    } else {
      final dept = await ref.read(departementByIdProvider(widget.groupeId).future);
      groupeNom = dept?.nom ?? 'Département';
    }

    // Récupère les fidèles
    final fideles = widget.typeGroupe == TypeGroupe.tribu
        ? await ref.read(fidelesByTribuProvider(widget.groupeId).future)
        : await ref.read(fidelesByDepartementProvider(widget.groupeId).future);

    // Convertit en items d'appel
    final fidelesAppel = fideles
        .where((f) => f.actif)
        .map((f) => FideleAppelItem(
              fideleId: f.id,
              nom: f.nom,
              prenom: f.prenom,
              photoUrl: f.photoUrl,
            ))
        .toList();

    // Initialise l'appel
    ref.read(appelProvider.notifier).initAppel(
          typeGroupe: widget.typeGroupe,
          groupeId: widget.groupeId,
          groupeNom: groupeNom,
          fideles: fidelesAppel,
        );
  }

  void _marquerPresent(String fideleId) {
    ref.read(appelProvider.notifier).marquerPresent(fideleId);
  }

  void _marquerAbsent(String fideleId) {
    ref.read(appelProvider.notifier).marquerAbsent(fideleId);
  }

  void _marquerRestantsAbsents() {
    ref.read(appelProvider.notifier).marquerRestantsAbsents();
  }

  Future<void> _enregistrerAppel() async {
    final success = await ref.read(appelProvider.notifier).enregistrerAppel();
    if (success && mounted) {
      context.showSuccessSnackBar('Appel enregistré avec succès');
      context.pop();
    } else if (mounted) {
      final error = ref.read(appelProvider).error;
      context.showErrorSnackBar(error ?? 'Erreur lors de l\'enregistrement');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appelState = ref.watch(appelProvider);
    final appel = appelState.appelEnCours;

    if (appel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.appel)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Appel - ${appel.groupeNom}'),
        actions: [
          if (appel.fidelesNonAppeles.isNotEmpty)
            TextButton(
              onPressed: _marquerRestantsAbsents,
              child: const Text(
                'Tous absents',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Résumé
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            color: AppColors.primary.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip(
                  'Présents',
                  appel.nombrePresents.toString(),
                  AppColors.present,
                ),
                _buildStatChip(
                  'Absents',
                  appel.nombreAbsents.toString(),
                  AppColors.absent,
                ),
                _buildStatChip(
                  'Restants',
                  appel.fidelesNonAppeles.length.toString(),
                  AppColors.textSecondary,
                ),
              ],
            ),
          ),

          // Liste des fidèles non appelés
          Expanded(
            child: appel.fidelesNonAppeles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 64,
                          color: AppColors.actif,
                        ),
                        const SizedBox(height: AppSizes.paddingM),
                        Text(
                          'Appel terminé !',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSizes.paddingS),
                        Text(
                          '${appel.nombrePresents} présents, ${appel.nombreAbsents} absents',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.paddingM),
                    itemCount: appel.fidelesNonAppeles.length,
                    itemBuilder: (context, index) {
                      final fidele = appel.fidelesNonAppeles[index];
                      return MembreAppelCard(
                        fidele: fidele,
                        onPresent: () => _marquerPresent(fidele.fideleId),
                        onAbsent: () => _marquerAbsent(fidele.fideleId),
                      );
                    },
                  ),
          ),

          // Bouton d'enregistrement
          if (appel.estTermine)
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeightL,
                child: ElevatedButton(
                  onPressed: appelState.isSaving ? null : _enregistrerAppel,
                  child: appelState.isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(AppStrings.enregistrerAppel),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
