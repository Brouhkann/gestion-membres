import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/eglise_model.dart';
import '../../../data/repositories/eglise_repository.dart';

final eglisesProvider = FutureProvider<List<EgliseModel>>((ref) async {
  final repo = EgliseRepository();
  return repo.getAll();
});

class EglisesListScreen extends ConsumerWidget {
  const EglisesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eglisesAsync = ref.watch(eglisesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Églises'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPasteurDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un pasteur'),
      ),
      body: eglisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
        data: (eglises) {
          if (eglises.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.church, size: 64, color: AppColors.textHint),
                  SizedBox(height: AppSizes.paddingM),
                  Text('Aucune église'),
                  Text(
                    'Ajoutez un pasteur pour créer une église',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            itemCount: eglises.length,
            itemBuilder: (context, index) {
              final eglise = eglises[index];
              return _EgliseCard(eglise: eglise);
            },
          );
        },
      ),
    );
  }

  void _showAddPasteurDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController();
    final prenomController = TextEditingController();
    final telephoneController = TextEditingController();
    final nomEgliseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un pasteur'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du pasteur',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                ),
                const SizedBox(height: AppSizes.paddingM),
                TextFormField(
                  controller: prenomController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                ),
                const SizedBox(height: AppSizes.paddingM),
                TextFormField(
                  controller: telephoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone (identifiant)',
                    prefixIcon: Icon(Icons.phone),
                    hintText: '0708091011',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Requis';
                    if (v!.length < 10) return 'Numéro invalide';
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingM),
                TextFormField(
                  controller: nomEgliseController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'église',
                    prefixIcon: Icon(Icons.church),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _createPasteur(
                  context,
                  ref,
                  nom: nomController.text,
                  prenom: prenomController.text,
                  telephone: telephoneController.text,
                  nomEglise: nomEgliseController.text,
                );
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  Future<void> _createPasteur(
    BuildContext context,
    WidgetRef ref, {
    required String nom,
    required String prenom,
    required String telephone,
    required String nomEglise,
  }) async {
    try {
      // Afficher un indicateur de chargement
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Création en cours...')),
      );

      // TODO: Implémenter la création via le repository
      // 1. Créer l'utilisateur dans auth.users
      // 2. Créer l'église
      // 3. Créer le profil utilisateur avec eglise_id

      // Rafraîchir la liste
      ref.invalidate(eglisesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pasteur $prenom $nom créé avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _EgliseCard extends StatelessWidget {
  final EgliseModel eglise;

  const _EgliseCard({required this.eglise});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          backgroundImage:
              eglise.logoUrl != null ? NetworkImage(eglise.logoUrl!) : null,
          child: eglise.logoUrl == null
              ? const Icon(Icons.church, color: Colors.white)
              : null,
        ),
        title: Text(
          eglise.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (eglise.ville != null)
              Text(eglise.ville!, style: const TextStyle(fontSize: 12)),
            Row(
              children: [
                Icon(
                  eglise.configurationComplete
                      ? Icons.check_circle
                      : Icons.pending,
                  size: 14,
                  color: eglise.configurationComplete
                      ? AppColors.success
                      : AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  eglise.configurationComplete ? 'Configurée' : 'En attente',
                  style: TextStyle(
                    fontSize: 11,
                    color: eglise.configurationComplete
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Naviguer vers les détails de l'église
        },
      ),
    );
  }
}
