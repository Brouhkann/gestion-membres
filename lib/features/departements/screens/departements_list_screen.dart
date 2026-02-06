import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/departement_model.dart';
import '../../../providers/departement_provider.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/departement_card.dart';

class DepartementsListScreen extends ConsumerStatefulWidget {
  const DepartementsListScreen({super.key});

  @override
  ConsumerState<DepartementsListScreen> createState() => _DepartementsListScreenState();
}

class _DepartementsListScreenState extends ConsumerState<DepartementsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(departementsProvider.notifier).loadAllWithStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final departementsState = ref.watch(departementsProvider);
    final isPasteur = ref.watch(isPasteurProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.departements),
      ),
      body: departementsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : departementsState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: AppColors.error),
                      const SizedBox(height: AppSizes.paddingM),
                      Text(departementsState.error!),
                      const SizedBox(height: AppSizes.paddingM),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(departementsProvider.notifier).loadAllWithStats(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : departementsState.departements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.business_outlined, size: 64, color: AppColors.textHint),
                          const SizedBox(height: AppSizes.paddingM),
                          Text(
                            'Aucun département',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.read(departementsProvider.notifier).loadAllWithStats(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSizes.paddingM),
                        itemCount: departementsState.departements.length,
                        itemBuilder: (context, index) {
                          final dept = departementsState.departements[index];
                          return DepartementCard(
                            departement: dept,
                            onTap: () => context.goToDepartement(dept.id),
                          );
                        },
                      ),
                    ),
      floatingActionButton: isPasteur
          ? FloatingActionButton(
              onPressed: () => _showAddDepartementDialog(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddDepartementDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nouveau Département'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du département *',
                    prefixIcon: Icon(Icons.business),
                    hintText: 'Ex: Chorale',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                ),
                const SizedBox(height: AppSizes.paddingM),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isLoading = true);

                        final egliseId = ref.read(userEgliseIdProvider);
                        if (egliseId == null) {
                          context.showErrorSnackBar('Erreur: église non trouvée');
                          setState(() => isLoading = false);
                          return;
                        }

                        final departement = DepartementModel(
                          id: '', // Généré par Supabase
                          nom: nomController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          egliseId: egliseId,
                          createdAt: DateTime.now(),
                        );

                        final result = await ref.read(departementsProvider.notifier).create(departement);

                        if (result != null && context.mounted) {
                          Navigator.pop(context);
                          context.showSuccessSnackBar('Département créé avec succès');
                        } else if (context.mounted) {
                          context.showErrorSnackBar('Erreur lors de la création');
                          setState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }
}
