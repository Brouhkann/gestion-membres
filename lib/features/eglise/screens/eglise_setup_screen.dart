import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/services/supabase_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class EgliseSetupScreen extends ConsumerStatefulWidget {
  const EgliseSetupScreen({super.key});

  @override
  ConsumerState<EgliseSetupScreen> createState() => _EgliseSetupScreenState();
}

class _EgliseSetupScreenState extends ConsumerState<EgliseSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Profil pasteur
  final _nomPasteurController = TextEditingController();
  final _prenomPasteurController = TextEditingController();

  // Profil église
  final _nomEgliseController = TextEditingController();
  final _villeController = TextEditingController();
  final _quartierController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nomPasteurController.dispose();
    _prenomPasteurController.dispose();
    _nomEgliseController.dispose();
    _villeController.dispose();
    _quartierController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).user;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final supabase = SupabaseService.instance;

      // 1. Créer l'église
      final egliseData = {
        'nom': _nomEgliseController.text.trim(),
        'ville': _villeController.text.trim(),
        'adresse': _quartierController.text.trim(),
        'pasteur_id': user.id,
        'configuration_complete': true,
        'actif': true,
      };

      final egliseResult = await supabase.client
          .from('eglises')
          .insert(egliseData)
          .select()
          .single();

      final egliseId = egliseResult['id'];

      // 2. Mettre à jour le profil du pasteur
      await supabase.client
          .from('users')
          .update({
            'nom': _nomPasteurController.text.trim(),
            'prenom': _prenomPasteurController.text.trim(),
            'eglise_id': egliseId,
            'premiere_connexion': false,
          })
          .eq('id', user.id);

      // 3. Recharger l'utilisateur
      final updatedUser = user.copyWith(
        nom: _nomPasteurController.text.trim(),
        prenom: _prenomPasteurController.text.trim(),
        egliseId: egliseId,
        premiereConnexion: false,
      );
      ref.read(authProvider.notifier).updateUser(updatedUser);

      if (mounted) {
        context.showSuccessSnackBar('Configuration terminée !');
        context.go('/dashboard');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête
              const Icon(
                Icons.church,
                size: 60,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSizes.paddingM),
              Text(
                'Bienvenue !',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.paddingS),
              const Text(
                'Complétez votre profil et celui de votre église pour commencer.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSizes.paddingXL),

              // Section Profil Pasteur
              _buildSectionTitle('Votre profil'),
              const SizedBox(height: AppSizes.paddingM),
              AppTextField(
                controller: _prenomPasteurController,
                label: 'Prénom *',
                hint: 'Ex: Mohammed',
                prefixIcon: Icons.person,
                textCapitalization: TextCapitalization.words,
                validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
              ),
              const SizedBox(height: AppSizes.paddingM),
              AppTextField(
                controller: _nomPasteurController,
                label: 'Nom *',
                hint: 'Ex: Sanogo',
                prefixIcon: Icons.person_outline,
                textCapitalization: TextCapitalization.words,
                validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
              ),

              const SizedBox(height: AppSizes.paddingXL),

              // Section Église
              _buildSectionTitle('Votre église'),
              const SizedBox(height: AppSizes.paddingM),
              AppTextField(
                controller: _nomEgliseController,
                label: 'Nom de l\'église *',
                hint: 'Ex: Église Vases d\'Honneur',
                prefixIcon: Icons.church,
                textCapitalization: TextCapitalization.words,
                validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
              ),
              const SizedBox(height: AppSizes.paddingM),
              AppTextField(
                controller: _villeController,
                label: 'Ville *',
                hint: 'Ex: Abidjan',
                prefixIcon: Icons.location_city,
                textCapitalization: TextCapitalization.words,
                validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
              ),
              const SizedBox(height: AppSizes.paddingM),
              AppTextField(
                controller: _quartierController,
                label: 'Quartier / Commune',
                hint: 'Ex: Cocody Angré',
                prefixIcon: Icons.location_on,
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: AppSizes.paddingXXL),

              // Bouton
              AppButton(
                text: 'Commencer',
                onPressed: _saveProfile,
                isLoading: _isLoading,
              ),

              const SizedBox(height: AppSizes.paddingL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSizes.paddingS),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
