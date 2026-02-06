import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/fidele_model.dart';
import '../../../data/models/enums.dart';
import '../../../providers/fidele_provider.dart';
import '../../../providers/tribu_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_button.dart';

class FideleFormScreen extends ConsumerStatefulWidget {
  final String? fideleId;

  const FideleFormScreen({super.key, this.fideleId});

  @override
  ConsumerState<FideleFormScreen> createState() => _FideleFormScreenState();
}

class _FideleFormScreenState extends ConsumerState<FideleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _professionController = TextEditingController();

  Sexe _sexe = Sexe.homme;
  int? _jourNaissance;
  int? _moisNaissance;
  String? _tribuId;
  bool _isLoading = false;
  bool _isEditMode = false;
  FideleModel? _existingFidele;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.fideleId != null;
    if (_isEditMode) {
      _loadFidele();
    } else {
      // Pour un patriarche, la tribu est automatiquement la sienne
      final userTribuId = ref.read(userTribuIdProvider);
      if (userTribuId != null) {
        _tribuId = userTribuId;
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  Future<void> _loadFidele() async {
    setState(() => _isLoading = true);
    try {
      final fidele = await ref.read(fideleRepositoryProvider).getById(widget.fideleId!);
      _existingFidele = fidele;
      _nomController.text = fidele.nom;
      _prenomController.text = fidele.prenom;
      _sexe = fidele.sexe;
      _jourNaissance = fidele.jourNaissance;
      _moisNaissance = fidele.moisNaissance;
      _telephoneController.text = fidele.telephone ?? '';
      _adresseController.text = fidele.adresse ?? '';
      _professionController.text = fidele.profession ?? '';
      _tribuId = fidele.tribuId;
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Erreur de chargement: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tribuId == null) {
      context.showErrorSnackBar('Veuillez sélectionner une tribu');
      return;
    }

    context.unfocus();
    setState(() => _isLoading = true);

    try {
      final fidele = FideleModel(
        id: _existingFidele?.id ?? '',
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        sexe: _sexe,
        jourNaissance: _jourNaissance,
        moisNaissance: _moisNaissance,
        telephone: _telephoneController.text.trim().isNotEmpty
            ? _telephoneController.text.trim()
            : null,
        adresse: _adresseController.text.trim().isNotEmpty
            ? _adresseController.text.trim()
            : null,
        profession: _professionController.text.trim().isNotEmpty
            ? _professionController.text.trim()
            : null,
        tribuId: _tribuId!,
        actif: _existingFidele?.actif ?? true,
        createdAt: _existingFidele?.createdAt ?? DateTime.now(),
      );

      bool success;
      if (_isEditMode) {
        success = await ref.read(fidelesProvider.notifier).update(fidele);
      } else {
        final created = await ref.read(fidelesProvider.notifier).create(fidele);
        success = created != null;
      }

      if (success && mounted) {
        context.showSuccessSnackBar(
          _isEditMode ? 'Fidèle modifié' : 'Fidèle créé',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectBirthDate() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _BirthDatePicker(
        initialJour: _jourNaissance,
        initialMois: _moisNaissance,
        onSelected: (jour, mois) {
          setState(() {
            _jourNaissance = jour;
            _moisNaissance = mois;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tribusList = ref.watch(tribusListProvider);
    final isPasteur = ref.watch(isPasteurProvider);
    final isPatriarche = ref.watch(isPatriarcheProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? AppStrings.modifierFidele : AppStrings.nouveauFidele),
      ),
      body: _isLoading && _isEditMode
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Prénom
                    AppTextField(
                      controller: _prenomController,
                      label: AppStrings.prenom,
                      hint: 'Entrez le prénom',
                      validator: Validators.name,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSizes.paddingM),

                    // Nom
                    AppTextField(
                      controller: _nomController,
                      label: AppStrings.nom,
                      hint: 'Entrez le nom',
                      validator: Validators.name,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSizes.paddingM),

                    // Sexe
                    Text(
                      AppStrings.sexe,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: AppSizes.paddingXS),
                    Row(
                      children: [
                        Expanded(
                          child: _SexeOption(
                            label: AppStrings.homme,
                            icon: Icons.male,
                            isSelected: _sexe == Sexe.homme,
                            onTap: () => setState(() => _sexe = Sexe.homme),
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingM),
                        Expanded(
                          child: _SexeOption(
                            label: AppStrings.femme,
                            icon: Icons.female,
                            isSelected: _sexe == Sexe.femme,
                            onTap: () => setState(() => _sexe = Sexe.femme),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingM),

                    // Date de naissance
                    Text(
                      AppStrings.dateNaissance,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: AppSizes.paddingXS),
                    InkWell(
                      onTap: _selectBirthDate,
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.paddingM),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppColors.textSecondary),
                            const SizedBox(width: AppSizes.paddingM),
                            Text(
                              _jourNaissance != null && _moisNaissance != null
                                  ? '${_jourNaissance.toString().padLeft(2, '0')}/${_moisNaissance.toString().padLeft(2, '0')}'
                                  : 'Sélectionner jour et mois',
                              style: TextStyle(
                                color: _jourNaissance != null
                                    ? AppColors.textPrimary
                                    : AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingM),

                    // Téléphone
                    AppTextField(
                      controller: _telephoneController,
                      label: AppStrings.telephone,
                      hint: '6XX XXX XXX',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSizes.paddingM),

                    // Adresse
                    AppTextField(
                      controller: _adresseController,
                      label: AppStrings.adresse,
                      hint: 'Entrez l\'adresse',
                      prefixIcon: Icons.location_on,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSizes.paddingM),

                    // Profession
                    AppTextField(
                      controller: _professionController,
                      label: AppStrings.profession,
                      hint: 'Entrez la profession',
                      prefixIcon: Icons.work,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSizes.paddingM),

                    // Tribu (seulement pour le pasteur)
                    if (isPasteur) ...[
                      Text(
                        AppStrings.tribu,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: AppSizes.paddingXS),
                      tribusList.when(
                        data: (tribus) => DropdownButtonFormField<String>(
                          value: _tribuId,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.groups),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusM),
                            ),
                          ),
                          hint: const Text('Sélectionner une tribu'),
                          items: tribus.map((tribu) {
                            return DropdownMenuItem(
                              value: tribu.id,
                              child: Text(tribu.nom),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _tribuId = value),
                          validator: (value) =>
                              value == null ? 'Tribu obligatoire' : null,
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const Text('Erreur de chargement'),
                      ),
                      const SizedBox(height: AppSizes.paddingM),
                    ],

                    const SizedBox(height: AppSizes.paddingL),

                    // Bouton de validation
                    AppButton(
                      text: AppStrings.enregistrer,
                      onPressed: _handleSubmit,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SexeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SexeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSizes.paddingS),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BirthDatePicker extends StatefulWidget {
  final int? initialJour;
  final int? initialMois;
  final void Function(int jour, int mois) onSelected;

  const _BirthDatePicker({
    this.initialJour,
    this.initialMois,
    required this.onSelected,
  });

  @override
  State<_BirthDatePicker> createState() => _BirthDatePickerState();
}

class _BirthDatePickerState extends State<_BirthDatePicker> {
  late int _jour;
  late int _mois;

  final _moisNoms = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  @override
  void initState() {
    super.initState();
    _jour = widget.initialJour ?? 1;
    _mois = widget.initialMois ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sélectionner jour et mois',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSizes.paddingL),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('Jour'),
                    const SizedBox(height: AppSizes.paddingS),
                    DropdownButton<int>(
                      value: _jour,
                      items: List.generate(31, (i) => i + 1)
                          .map((j) => DropdownMenuItem(
                                value: j,
                                child: Text(j.toString().padLeft(2, '0')),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _jour = v!),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text('Mois'),
                    const SizedBox(height: AppSizes.paddingS),
                    DropdownButton<int>(
                      value: _mois,
                      items: List.generate(12, (i) => i + 1)
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(_moisNoms[m - 1]),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _mois = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingL),
          AppButton(
            text: 'Confirmer',
            onPressed: () => widget.onSelected(_jour, _mois),
          ),
        ],
      ),
    );
  }
}
