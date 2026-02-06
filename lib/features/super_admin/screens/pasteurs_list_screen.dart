import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/eglise_repository.dart';

/// Provider pour la liste des pasteurs
final pasteursProvider = FutureProvider<List<UserModel>>((ref) async {
  // TODO: Créer un repository pour récupérer les pasteurs
  // Pour l'instant, on retourne une liste vide
  return [];
});

class PasteursListScreen extends ConsumerWidget {
  const PasteursListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pasteursAsync = ref.watch(pasteursProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pasteurs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPasteurDialog(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Ajouter un pasteur'),
      ),
      body: pasteursAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
        data: (pasteurs) {
          if (pasteurs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 64, color: AppColors.textHint),
                  SizedBox(height: AppSizes.paddingM),
                  Text('Aucun pasteur'),
                  Text(
                    'Cliquez sur + pour ajouter un pasteur',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            itemCount: pasteurs.length,
            itemBuilder: (context, index) {
              final pasteur = pasteurs[index];
              return _PasteurCard(pasteur: pasteur);
            },
          );
        },
      ),
    );
  }

  void _showAddPasteurDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final telephoneController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nouveau Pasteur'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Le pasteur remplira son profil et celui de son église à sa première connexion.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingL),
                TextFormField(
                  controller: telephoneController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone *',
                    prefixIcon: Icon(Icons.phone),
                    hintText: '0505000000',
                    helperText: 'Ce numéro sera son identifiant',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Requis';
                    if (v!.replaceAll(RegExp(r'\D'), '').length < 10) {
                      return 'Numéro invalide (10 chiffres)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingM),
                Container(
                  padding: const EdgeInsets.all(AppSizes.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mot de passe par défaut : 12345678\nLe pasteur pourra le changer.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
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

                        final success = await _createPasteur(
                          context,
                          ref,
                          telephone: telephoneController.text.trim(),
                        );

                        if (success && context.mounted) {
                          Navigator.pop(context);
                        } else {
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

  Future<bool> _createPasteur(
    BuildContext context,
    WidgetRef ref, {
    required String telephone,
  }) async {
    try {
      final authRepo = AuthRepository();

      // Créer le compte pasteur avec mot de passe par défaut
      // Le pasteur configurera son profil et église à sa première connexion
      await authRepo.createUser(
        telephone: telephone,
        password: '12345678', // Mot de passe par défaut
        nom: 'Nouveau',
        prenom: 'Pasteur',
        role: UserRole.pasteur,
      );

      // Rafraîchir les listes
      ref.invalidate(pasteursProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pasteur créé : $telephone\nMot de passe : 12345678'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return false;
    }
  }
}

class _PasteurCard extends StatelessWidget {
  final UserModel pasteur;

  const _PasteurCard({required this.pasteur});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.pasteurColor,
          child: Text(
            pasteur.initiales,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          pasteur.nomComplet,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(pasteur.telephone),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              pasteur.actif ? Icons.check_circle : Icons.cancel,
              color: pasteur.actif ? AppColors.success : AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          // TODO: Afficher les détails du pasteur
        },
      ),
    );
  }
}
