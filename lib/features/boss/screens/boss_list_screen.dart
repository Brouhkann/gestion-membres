import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/fidele_provider.dart';
import '../../../providers/departement_provider.dart';
import '../../../providers/tribu_provider.dart';
import '../../../providers/cellule_provider.dart';
import '../../fideles/widgets/fidele_card.dart';
import '../../../core/router/app_router.dart';

class BossListScreen extends ConsumerStatefulWidget {
  const BossListScreen({super.key});

  @override
  ConsumerState<BossListScreen> createState() => _BossListScreenState();
}

class _BossListScreenState extends ConsumerState<BossListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterStatus = 'tous';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fidelesProvider.notifier).loadAll();
      ref.read(departementsProvider.notifier).loadAllWithStats();
      ref.read(tribusProvider.notifier).loadAllWithStats();
      ref.read(cellulesProvider.notifier).loadAllWithStats();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fidelesState = ref.watch(fidelesProvider);
    final departementsState = ref.watch(departementsProvider);
    final tribusState = ref.watch(tribusProvider);
    final cellulesState = ref.watch(cellulesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'BOSS',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Filtre (seulement pour l'onglet BOSS)
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'BOSS'),
            Tab(text: 'Responsables'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBossList(fidelesState),
          _buildResponsablesList(tribusState, departementsState, cellulesState),
        ],
      ),
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

  Widget _buildResponsablesList(
    TribusState tribusState,
    DepartementsState departementsState,
    CellulesState cellulesState,
  ) {
    final isLoading = tribusState.isLoading || departementsState.isLoading || cellulesState.isLoading;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final tribusAvecPatriarche = tribusState.tribus
        .where((t) => t.patriarcheNom != null)
        .toList();

    final departementsAvecResponsable = departementsState.departements
        .where((d) => d.responsableNom != null)
        .toList();

    final cellulesAvecResponsable = cellulesState.cellules
        .where((c) => c.responsableNom != null)
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
                  'Les responsables sont les patriarches de tribus, responsables de départements et responsables de cellules',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),

        // Section Patriarches
        _buildSectionHeader(
          'Patriarches',
          Icons.groups_rounded,
          AppColors.patriarcheColor,
          tribusAvecPatriarche.length,
        ),
        const SizedBox(height: 8),
        if (tribusAvecPatriarche.isEmpty)
          _buildEmptySection('Aucun patriarche désigné')
        else
          ...tribusAvecPatriarche.map((tribu) => _buildResponsableCard(
                nom: tribu.patriarcheNom!,
                sousTitre: 'Tribu: ${tribu.nom}',
                icon: Icons.groups_rounded,
                color: AppColors.patriarcheColor,
                badge: 'Patriarche',
              )),

        const SizedBox(height: 20),

        // Section Responsables de départements
        _buildSectionHeader(
          'Responsables de départements',
          Icons.business_rounded,
          AppColors.responsableColor,
          departementsAvecResponsable.length,
        ),
        const SizedBox(height: 8),
        if (departementsAvecResponsable.isEmpty)
          _buildEmptySection('Aucun responsable désigné')
        else
          ...departementsAvecResponsable.map((dept) => _buildResponsableCard(
                nom: dept.responsableNom!,
                sousTitre: 'Département: ${dept.nom}',
                icon: Icons.business_rounded,
                color: AppColors.responsableColor,
                badge: 'Responsable',
              )),

        const SizedBox(height: 20),

        // Section Responsables de cellules
        _buildSectionHeader(
          'Responsables de cellules',
          Icons.cell_tower_rounded,
          AppColors.secondary,
          cellulesAvecResponsable.length,
        ),
        const SizedBox(height: 8),
        if (cellulesAvecResponsable.isEmpty)
          _buildEmptySection('Aucun responsable désigné')
        else
          ...cellulesAvecResponsable.map((cellule) => _buildResponsableCard(
                nom: cellule.responsableNom!,
                sousTitre: 'Cellule: ${cellule.nom}',
                icon: Icons.cell_tower_rounded,
                color: AppColors.secondary,
                badge: 'Responsable',
              )),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, int count) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.textHint),
        ),
      ),
    );
  }

  Widget _buildResponsableCard({
    required String nom,
    required String sousTitre,
    required IconData icon,
    required Color color,
    required String badge,
  }) {
    return Container(
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
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sousTitre,
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
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
