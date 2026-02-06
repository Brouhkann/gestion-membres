import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/tribu_model.dart';
import '../../../providers/tribu_provider.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/tribu_card.dart';

class TribusListScreen extends ConsumerStatefulWidget {
  const TribusListScreen({super.key});

  @override
  ConsumerState<TribusListScreen> createState() => _TribusListScreenState();
}

class _TribusListScreenState extends ConsumerState<TribusListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tribusProvider.notifier).loadAllWithStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tribusState = ref.watch(tribusProvider);
    final isPasteur = ref.watch(isPasteurProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.tribus),
      ),
      body: tribusState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : tribusState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: AppColors.error),
                      const SizedBox(height: AppSizes.paddingM),
                      Text(tribusState.error!),
                      const SizedBox(height: AppSizes.paddingM),
                      ElevatedButton(
                        onPressed: () => ref.read(tribusProvider.notifier).loadAllWithStats(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : tribusState.tribus.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.groups_outlined, size: 64, color: AppColors.textHint),
                          const SizedBox(height: AppSizes.paddingM),
                          Text(
                            'Aucune tribu',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.read(tribusProvider.notifier).loadAllWithStats(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSizes.paddingM),
                        itemCount: tribusState.tribus.length,
                        itemBuilder: (context, index) {
                          final tribu = tribusState.tribus[index];
                          return TribuCard(
                            tribu: tribu,
                            onTap: () => context.goToTribu(tribu.id),
                          );
                        },
                      ),
                    ),
      floatingActionButton: isPasteur
          ? FloatingActionButton(
              onPressed: () => _showAddTribuDialog(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showAddTribuDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nouvelle Tribu'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la tribu *',
                    prefixIcon: Icon(Icons.groups),
                    hintText: 'Ex: Tribu de Juda',
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

                        final tribu = TribuModel(
                          id: '', // Généré par Supabase
                          nom: nomController.text.trim(),
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                          egliseId: egliseId,
                          createdAt: DateTime.now(),
                        );

                        final result = await ref.read(tribusProvider.notifier).create(tribu);

                        if (result != null && context.mounted) {
                          Navigator.pop(context);
                          context.showSuccessSnackBar('Tribu créée avec succès');
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
