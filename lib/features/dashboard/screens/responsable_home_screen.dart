import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/enums.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/fidele_provider.dart';
import '../../../providers/tribu_provider.dart';
import '../../../providers/departement_provider.dart';
import '../../../providers/presence_provider.dart';
import '../../settings/screens/settings_screen.dart';

/// Écran d'accueil pour les Patriarches et Responsables
class ResponsableHomeScreen extends ConsumerStatefulWidget {
  const ResponsableHomeScreen({super.key});

  @override
  ConsumerState<ResponsableHomeScreen> createState() =>
      _ResponsableHomeScreenState();
}

class _ResponsableHomeScreenState extends ConsumerState<ResponsableHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isPatriarche = user?.isPatriarche ?? false;
    final tribuId = ref.watch(userTribuIdProvider);
    final departementId = ref.watch(userDepartementIdProvider);

    // Déterminer le type de groupe et l'ID
    final typeGroupe = isPatriarche ? TypeGroupe.tribu : TypeGroupe.departement;
    final groupeId = isPatriarche ? tribuId : departementId;

    // Info du groupe
    final groupeInfo = isPatriarche
        ? (tribuId != null
            ? ref.watch(tribuByIdProvider(tribuId))
            : const AsyncValue.data(null))
        : (departementId != null
            ? ref.watch(departementByIdProvider(departementId))
            : const AsyncValue.data(null));

    // Mes fidèles
    final mesFideles = ref.watch(mesFidelesProvider);

    // Dernière session d'appel
    final derniereSession = groupeId != null
        ? ref.watch(derniereSessionProvider(
            (typeGroupe: typeGroupe, groupeId: groupeId)))
        : const AsyncValue.data(null);

    final roleLabel = isPatriarche ? AppStrings.patriarche : AppStrings.responsable;
    final roleColor = isPatriarche ? AppColors.patriarcheColor : AppColors.responsableColor;
    final groupeNom = groupeInfo.when(
      data: (g) {
        if (g == null) return isPatriarche ? 'Ma tribu' : 'Mon département';
        // Both TribuModel and DepartementModel have a nom property
        return (g as dynamic).nom as String;
      },
      loading: () => '...',
      error: (_, __) => '',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(mesFidelesProvider);
          if (groupeId != null) {
            if (isPatriarche) {
              ref.invalidate(tribuByIdProvider(groupeId));
            } else {
              ref.invalidate(departementByIdProvider(groupeId));
            }
          }
        },
        color: roleColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: roleColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        roleColor,
                        roleColor.withAlpha(180),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${Helpers.getGreeting()},',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withAlpha(200),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.prenom ?? roleLabel,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings_outlined, color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Contenu
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge du rôle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: roleColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPatriarche ? Icons.groups_rounded : Icons.business_rounded,
                            size: 16,
                            color: roleColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$roleLabel - $groupeNom',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: roleColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Statistiques
                    mesFideles.when(
                      data: (fideles) {
                        final actifs = fideles.where((f) => f.actif).length;
                        final inactifs = fideles.length - actifs;
                        return Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Membres',
                                value: fideles.length.toString(),
                                icon: Icons.people_rounded,
                                color: roleColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Actifs',
                                value: actifs.toString(),
                                icon: Icons.check_circle_rounded,
                                color: AppColors.actif,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Inactifs',
                                value: inactifs.toString(),
                                icon: Icons.cancel_rounded,
                                color: AppColors.inactif,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text('Erreur de chargement'),
                    ),

                    const SizedBox(height: 28),

                    // Dernier appel
                    const Text(
                      'Dernier appel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    derniereSession.when(
                      data: (session) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow.withAlpha(10),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: roleColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.fact_check_rounded, color: roleColor),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session != null
                                        ? 'Appel du ${session.dateFormatee}'
                                        : 'Aucun appel effectué',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (session != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '${session.nombrePresents ?? 0} présents / ${session.totalMembres ?? 0} membres',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: AppColors.textHint),
                          ],
                        ),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text('Erreur'),
                    ),

                    const SizedBox(height: 28),

                    // Actions rapides
                    const Text(
                      'Actions rapides',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.fact_check_rounded,
                            label: 'Faire\nl\'appel',
                            color: roleColor,
                            onTap: groupeId != null
                                ? () => context.goToAppel(typeGroupe, groupeId)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.history_rounded,
                            label: 'Historique\nprésences',
                            color: AppColors.secondary,
                            onTap: groupeId != null
                                ? () => context.goToHistorique(typeGroupe, groupeId)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.person_add_rounded,
                            label: 'Nouveau\nfidèle',
                            color: AppColors.actif,
                            onTap: () => context.go(AppRoutes.fideleForm),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
