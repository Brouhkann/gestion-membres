import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fidele_model.dart';
import '../../../shared/widgets/avatar_widget.dart';

class FideleCard extends StatelessWidget {
  final FideleModel fidele;
  final VoidCallback? onTap;

  const FideleCard({
    super.key,
    required this.fidele,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: fidele.isAnniversaireAujourdhui
                ? AppColors.secondary.withAlpha(100)
                : AppColors.divider,
            width: fidele.isAnniversaireAujourdhui ? 2 : 1,
          ),
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
            // Avatar avec indicateur de statut
            Stack(
              children: [
                AvatarWidget(
                  name: fidele.nomComplet,
                  photoUrl: fidele.photoUrl,
                  size: 50,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: fidele.actif ? AppColors.actif : AppColors.inactif,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fidele.nomComplet,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Badge anniversaire
                      if (fidele.isAnniversaireAujourdhui)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cake_rounded,
                                size: 14,
                                color: AppColors.secondary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Anniv.',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Sexe
                      Icon(
                        fidele.sexe.name == 'homme' ? Icons.male_rounded : Icons.female_rounded,
                        size: 16,
                        color: fidele.sexe.name == 'homme'
                            ? Colors.blue.shade400
                            : Colors.pink.shade400,
                      ),
                      const SizedBox(width: 8),
                      // Tribu
                      if (fidele.tribuNom != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.patriarcheColor.withAlpha(15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.groups_rounded,
                                size: 12,
                                color: AppColors.patriarcheColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                fidele.tribuNom!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.patriarcheColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Téléphone
                      if (fidele.telephone != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.phone_rounded,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Chevron
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
