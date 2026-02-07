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
import '../../../providers/cellule_provider.dart';
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
  // Étape 1: cocher les présents, Étape 2: justifier les absents
  int _etape = 1;
  final Set<String> _presentsIds = {};
  final Map<String, bool> _justifications = {};
  final Map<String, String> _motifs = {};
  final Map<String, TextEditingController> _motifControllers = {};

  @override
  void initState() {
    super.initState();
    _initAppel();
  }

  @override
  void dispose() {
    for (final controller in _motifControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initAppel() async {
    // Récupère le nom du groupe selon le type
    String groupeNom = '';
    List fideles = [];

    switch (widget.typeGroupe) {
      case TypeGroupe.tribu:
        final tribu = await ref.read(tribuByIdProvider(widget.groupeId).future);
        groupeNom = tribu?.nom ?? 'Tribu';
        fideles = await ref.read(fidelesByTribuProvider(widget.groupeId).future);
        break;
      case TypeGroupe.departement:
        final dept = await ref.read(departementByIdProvider(widget.groupeId).future);
        groupeNom = dept?.nom ?? 'Département';
        fideles = await ref.read(fidelesByDepartementProvider(widget.groupeId).future);
        break;
      case TypeGroupe.cellule:
        final cellule = await ref.read(celluleByIdProvider(widget.groupeId).future);
        groupeNom = cellule?.nom ?? 'Cellule';
        fideles = await ref.read(fidelesByCelluleProvider(widget.groupeId).future);
        break;
      case TypeGroupe.responsables:
        groupeNom = 'Réunion des responsables';
        fideles = await ref.read(responsablesProvider.future);
        break;
      case TypeGroupe.eglise:
        groupeNom = 'Église';
        fideles = await ref.read(fidelesByTribuProvider(widget.groupeId).future);
        break;
    }

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

  void _togglePresent(String fideleId, bool? value) {
    setState(() {
      if (value == true) {
        _presentsIds.add(fideleId);
      } else {
        _presentsIds.remove(fideleId);
      }
    });
  }

  void _terminerEtape1() {
    final appel = ref.read(appelProvider).appelEnCours;
    if (appel == null) return;

    // Marque les présents et absents dans le provider
    final notifier = ref.read(appelProvider.notifier);

    for (final fidele in appel.fideles) {
      if (_presentsIds.contains(fidele.fideleId)) {
        notifier.marquerPresent(fidele.fideleId);
      } else {
        notifier.marquerAbsent(fidele.fideleId);
      }
    }

    setState(() {
      _etape = 2;
    });
  }

  void _toggleJustification(String fideleId, bool value) {
    setState(() {
      _justifications[fideleId] = value;
      if (!value) {
        _motifs.remove(fideleId);
        _motifControllers[fideleId]?.clear();
      }
    });
    ref.read(appelProvider.notifier).toggleJustification(fideleId, value);
  }

  void _updateMotif(String fideleId, String motif) {
    _motifs[fideleId] = motif;
    ref.read(appelProvider.notifier).justifierAbsence(fideleId, motif);
  }

  TextEditingController _getMotifController(String fideleId) {
    if (!_motifControllers.containsKey(fideleId)) {
      _motifControllers[fideleId] = TextEditingController(text: _motifs[fideleId] ?? '');
    }
    return _motifControllers[fideleId]!;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_etape == 2) {
              setState(() => _etape = 1);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: _etape == 1
          ? _buildEtape1Cocher(appel)
          : _buildEtape2Justifier(appel, appelState),
    );
  }

  /// Étape 1 : cocher les présents
  Widget _buildEtape1Cocher(AppelEnCoursModel appel) {
    final nbPresents = _presentsIds.length;
    final nbAbsents = appel.fideles.length - nbPresents;

    return Column(
      children: [
        // Compteurs
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          color: AppColors.primary.withAlpha(25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip('Présents', nbPresents.toString(), AppColors.present),
              _buildStatChip('Absents', nbAbsents.toString(), AppColors.absent),
              _buildStatChip('Total', appel.fideles.length.toString(), AppColors.textSecondary),
            ],
          ),
        ),
        // Indication
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingS),
          color: AppColors.secondary.withAlpha(15),
          child: const Text(
            'Cochez les fidèles présents, puis appuyez sur "Terminer l\'appel"',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        // Liste avec checkboxes
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            itemCount: appel.fideles.length,
            itemBuilder: (context, index) {
              final fidele = appel.fideles[index];
              return MembreAppelCard(
                fidele: fidele,
                isChecked: _presentsIds.contains(fidele.fideleId),
                onChanged: (value) => _togglePresent(fidele.fideleId, value),
              );
            },
          ),
        ),
        // Bouton Terminer l'appel
        Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeightL,
            child: ElevatedButton.icon(
              onPressed: _terminerEtape1,
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                nbAbsents > 0
                    ? 'Terminer l\'appel ($nbAbsents absents)'
                    : 'Terminer l\'appel',
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Étape 2 : justifier les absences
  Widget _buildEtape2Justifier(AppelEnCoursModel appel, AppelState appelState) {
    final absents = appel.fidelesAppeles
        .where((f) => f.statut == StatutPresence.absent)
        .toList();

    return Column(
      children: [
        // Résumé
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          color: AppColors.primary.withAlpha(25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip('Présents', appel.nombrePresents.toString(), AppColors.present),
              _buildStatChip('Absents', appel.nombreAbsents.toString(), AppColors.absent),
              _buildStatChip(
                'Justifiés',
                absents.where((f) => f.justifie).length.toString(),
                const Color(0xFFFF9800),
              ),
            ],
          ),
        ),
        // Instructions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingS),
          color: const Color(0xFFFF9800).withAlpha(20),
          child: const Text(
            'Justifiez les absences si nécessaire, puis enregistrez l\'appel',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        // Liste des absents
        Expanded(
          child: absents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 64, color: AppColors.actif),
                      const SizedBox(height: AppSizes.paddingM),
                      Text(
                        'Tous présents !',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSizes.paddingS),
                      const Text('Aucun absent à justifier'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  itemCount: absents.length,
                  itemBuilder: (context, index) {
                    final fidele = absents[index];
                    final controller = _getMotifController(fidele.fideleId);
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.paddingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AvatarWidget(
                                  name: fidele.nomComplet,
                                  photoUrl: fidele.photoUrl,
                                  size: AppSizes.avatarM,
                                ),
                                const SizedBox(width: AppSizes.paddingM),
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
                                      const Text(
                                        'Absent(e)',
                                        style: TextStyle(
                                          color: AppColors.absent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Justifié',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: (_justifications[fidele.fideleId] == true)
                                            ? const Color(0xFFFF9800)
                                            : AppColors.textHint,
                                      ),
                                    ),
                                    Switch(
                                      value: _justifications[fidele.fideleId] ?? false,
                                      onChanged: (val) => _toggleJustification(fidele.fideleId, val),
                                      activeColor: const Color(0xFFFF9800),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (_justifications[fidele.fideleId] == true) ...[
                              const SizedBox(height: AppSizes.paddingS),
                              TextField(
                                controller: controller,
                                onChanged: (val) => _updateMotif(fidele.fideleId, val),
                                decoration: InputDecoration(
                                  hintText: 'Motif de l\'absence...',
                                  hintStyle: const TextStyle(fontSize: 13),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.paddingM,
                                    vertical: AppSizes.paddingS,
                                  ),
                                  isDense: true,
                                ),
                                maxLines: 2,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Bouton enregistrer
        Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeightL,
            child: ElevatedButton.icon(
              onPressed: appelState.isSaving ? null : _enregistrerAppel,
              icon: appelState.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: const Text(AppStrings.enregistrerAppel),
            ),
          ),
        ),
      ],
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
