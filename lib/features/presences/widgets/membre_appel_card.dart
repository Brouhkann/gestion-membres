import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/presence_model.dart';
import '../../../shared/widgets/avatar_widget.dart';

class MembreAppelCard extends StatelessWidget {
  final FideleAppelItem fidele;
  final VoidCallback onPresent;
  final VoidCallback onAbsent;

  const MembreAppelCard({
    super.key,
    required this.fidele,
    required this.onPresent,
    required this.onAbsent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Row(
          children: [
            // Avatar
            AvatarWidget(
              name: fidele.nomComplet,
              photoUrl: fidele.photoUrl,
              size: AppSizes.avatarM,
            ),
            const SizedBox(width: AppSizes.paddingM),

            // Nom
            Expanded(
              child: Text(
                fidele.nomComplet,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),

            // Boutons
            Row(
              children: [
                // Bouton Présent
                _AppelButton(
                  icon: Icons.check,
                  color: AppColors.present,
                  onTap: onPresent,
                ),
                const SizedBox(width: AppSizes.paddingS),
                // Bouton Absent
                _AppelButton(
                  icon: Icons.close,
                  color: AppColors.absent,
                  onTap: onAbsent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppelButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AppelButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, color: color),
        ),
      ),
    );
  }
}
