import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class AnniversaireCard extends StatelessWidget {
  final int countAujourdhui;
  final int countSemaine;
  final int countMois;
  final VoidCallback? onTap;

  const AnniversaireCard({
    super.key,
    required this.countAujourdhui,
    required this.countSemaine,
    required this.countMois,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingS),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusS),
                    ),
                    child: const Icon(
                      Icons.cake,
                      color: AppColors.secondary,
                      size: AppSizes.iconM,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingM),
                  Expanded(
                    child: Text(
                      'Anniversaires',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingM),
              const Divider(height: 1),
              const SizedBox(height: AppSizes.paddingM),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    context,
                    "Aujourd'hui",
                    countAujourdhui,
                    countAujourdhui > 0 ? AppColors.error : AppColors.textSecondary,
                  ),
                  _buildStat(
                    context,
                    'Cette semaine',
                    countSemaine,
                    countSemaine > 0 ? AppColors.warning : AppColors.textSecondary,
                  ),
                  _buildStat(
                    context,
                    'Ce mois',
                    countMois,
                    AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
