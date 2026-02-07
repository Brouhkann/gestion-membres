import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/presence_model.dart';
import '../../../shared/widgets/avatar_widget.dart';

class MembreAppelCard extends StatelessWidget {
  final FideleAppelItem fidele;
  final bool isChecked;
  final ValueChanged<bool?> onChanged;

  const MembreAppelCard({
    super.key,
    required this.fidele,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
      child: CheckboxListTile(
        value: isChecked,
        onChanged: onChanged,
        activeColor: AppColors.present,
        secondary: AvatarWidget(
          name: fidele.nomComplet,
          photoUrl: fidele.photoUrl,
          size: AppSizes.avatarM,
        ),
        title: Text(
          fidele.nomComplet,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}

/// Card pour l'étape de justification des absences
class AbsentJustificationCard extends StatelessWidget {
  final FideleAppelItem fidele;
  final bool isJustifie;
  final String? motif;
  final ValueChanged<bool> onJustifieChanged;
  final ValueChanged<String> onMotifChanged;

  const AbsentJustificationCard({
    super.key,
    required this.fidele,
    required this.isJustifie,
    this.motif,
    required this.onJustifieChanged,
    required this.onMotifChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingS),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarWidget(
                  name: fidele.nomComplet,
                  photoUrl: fidele.photoUrl,
                  size: AppSizes.avatarM,
                ),
                const SizedBox(width: AppSizes.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fidele.nomComplet,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Text(
                        'Absent(e)',
                        style: TextStyle(
                          color: AppColors.absent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Switch justifié
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Justifié',
                      style: TextStyle(
                        fontSize: 12,
                        color: isJustifie ? AppColors.warning : AppColors.textHint,
                      ),
                    ),
                    Switch(
                      value: isJustifie,
                      onChanged: onJustifieChanged,
                      activeColor: AppColors.warning,
                    ),
                  ],
                ),
              ],
            ),
            if (isJustifie) ...[
              const SizedBox(height: AppSizes.paddingS),
              TextField(
                onChanged: onMotifChanged,
                controller: motif != null
                    ? (TextEditingController(text: motif)..selection =
                        TextSelection.collapsed(offset: motif!.length))
                    : null,
                decoration: InputDecoration(
                  hintText: 'Motif de l\'absence...',
                  hintStyle: const TextStyle(fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                    vertical: AppSizes.paddingS,
                  ),
                  isDense: true,
                ),
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
