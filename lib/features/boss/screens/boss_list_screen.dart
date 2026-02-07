import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/fidele_provider.dart';
import '../../../providers/departement_provider.dart';
import '../../fideles/widgets/fidele_card.dart';
import '../../../core/router/app_router.dart';

class BossListScreen extends ConsumerStatefulWidget {
  const BossListScreen({super.key});

  @override
  ConsumerState<BossListScreen> createState() => _BossListScreenState();
}

class _BossListScreenState extends ConsumerState<BossListScreen> {
  String _filterStatus = 'tous';
  bool _showServiteurs = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fidelesProvider.notifier).loadAll();
      ref.read(departementsProvider.notifier).loadAllWithStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fidelesState = ref.watch(fidelesProvider);
    final departementsState = ref.watch(departementsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          _showServiteurs ? 'Serviteurs' : 'BOSS',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Toggle BOSS / Serviteurs
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showServiteurs = !_showServiteurs;
              });
            },
            icon: Icon(
              _showServiteurs ? Icons.work_rounded : Icons.star_rounded,
              size: 18,
            ),
            label: Text(_showServiteurs ? 'Voir BOSS' : 'Serviteurs'),
          ),
          // Filtre
          PopupMenuButton<String>(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list_rounded, color: AppColors.textPrimary),
                if (_filterStatus != 'tous')
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onSelected: (value) => setState(() => _filterStatus = value),
            itemBuilder: (context) => [
              _buildFilterItem('tous', 'Tous', Icons.people),
              _buildFilterItem('actifs', 'Actifs', Icons.check_circle),
              _buildFilterItem('inactifs', 'Inactifs', Icons.cancel),
            ],
          ),
        ],
      ),
      body: _showServiteurs
          ? _buildServiteursList(departementsState)
          : _buildBossList(fidelesState),
    );
  }

  Widget _buildBossList(FidelesState fidelesState) {
    if (fidelesState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filtrer les fidèles qui ont des départements (BOSS)
    final bossList = fidelesState.fideles.where((f) {
      if (_filterStatus == 'actifs') return f.actif;
      if (_filterStatus == 'inactifs') return !f.actif;
      return true;
    }).toList();

    if (bossList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                size: 64,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun BOSS trouvé',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'BOSS = Bon Ouvrier au Service du SEIGNEUR',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Info BOSS
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.secondary.withAlpha(15),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.secondary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'BOSS = Bon Ouvrier au Service du SEIGNEUR',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '${bossList.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
        // Filtre actif
        if (_filterStatus != 'tous')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Chip(
              label: Text(
                _filterStatus == 'actifs' ? 'Actifs' : 'Inactifs',
                style: TextStyle(
                  color: _filterStatus == 'actifs' ? AppColors.actif : AppColors.inactif,
                  fontSize: 13,
                ),
              ),
              backgroundColor: (_filterStatus == 'actifs' ? AppColors.actif : AppColors.inactif).withAlpha(20),
              deleteIcon: const Icon(Icons.close, size: 18),
              deleteIconColor: _filterStatus == 'actifs' ? AppColors.actif : AppColors.inactif,
              onDeleted: () => setState(() => _filterStatus = 'tous'),
              side: BorderSide.none,
            ),
          ),
        // Liste
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bossList.length,
            itemBuilder: (context, index) {
              final fidele = bossList[index];
              return FideleCard(
                fidele: fidele,
                onTap: () => context.goToFidele(fidele.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiteursList(DepartementsState departementsState) {
    if (departementsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Les serviteurs = responsables de départements qui ont un responsable
    final departementsAvecResponsable = departementsState.departements
        .where((d) => d.responsableNom != null)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Les serviteurs sont les patriarches et responsables de départements/cellules',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        // Responsables de départements
        const Text(
          'Responsables de départements',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (departementsAvecResponsable.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: Text(
                'Aucun responsable désigné',
                style: TextStyle(color: AppColors.textHint),
              ),
            ),
          )
        else
          ...departementsAvecResponsable.map((dept) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.responsableColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.business_rounded,
                        color: AppColors.responsableColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dept.responsableNom!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Département: ${dept.nom}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.responsableColor.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Responsable',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.responsableColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  PopupMenuItem<String> _buildFilterItem(String value, String label, IconData icon) {
    final isSelected = _filterStatus == value;
    final color = value == 'actifs'
        ? AppColors.actif
        : value == 'inactifs'
            ? AppColors.inactif
            : AppColors.primary;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check_circle : icon,
            color: isSelected ? color : AppColors.textHint,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}
