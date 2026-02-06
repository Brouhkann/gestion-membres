import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/enums.dart';
import '../../../providers/presence_provider.dart';

class HistoriquePresencesScreen extends ConsumerWidget {
  final TypeGroupe typeGroupe;
  final String groupeId;

  const HistoriquePresencesScreen({
    super.key,
    required this.typeGroupe,
    required this.groupeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(
      historiqueSessionsProvider((typeGroupe: typeGroupe, groupeId: groupeId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.historiqueAppels),
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: AppColors.error),
              const SizedBox(height: AppSizes.paddingM),
              Text('Erreur: $error'),
            ],
          ),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: AppColors.textHint),
                  const SizedBox(height: AppSizes.paddingM),
                  Text(
                    'Aucun historique',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final tauxPresence = session.totalMembres != null && session.totalMembres! > 0
                  ? ((session.nombrePresents ?? 0) / session.totalMembres!) * 100
                  : 0.0;

              return Card(
                margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getTauxColor(tauxPresence),
                    child: Text(
                      '${tauxPresence.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    session.dateFormatee,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${session.nombrePresents ?? 0} présents / ${session.totalMembres ?? 0} membres',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.present,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${session.nombrePresents ?? 0}',
                            style: const TextStyle(color: AppColors.present),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.absent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${session.nombreAbsents ?? 0}',
                            style: const TextStyle(color: AppColors.absent),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getTauxColor(double taux) {
    if (taux >= 80) return AppColors.actif;
    if (taux >= 50) return AppColors.warning;
    return AppColors.error;
  }
}
