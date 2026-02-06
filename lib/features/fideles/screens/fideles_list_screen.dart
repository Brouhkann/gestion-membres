import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/fidele_provider.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/fidele_card.dart';

class FidelesListScreen extends ConsumerStatefulWidget {
  const FidelesListScreen({super.key});

  @override
  ConsumerState<FidelesListScreen> createState() => _FidelesListScreenState();
}

class _FidelesListScreenState extends ConsumerState<FidelesListScreen> {
  final _searchController = TextEditingController();
  String _filterStatus = 'tous'; // tous, actifs, inactifs

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFideles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadFideles() {
    final isPasteur = ref.read(isPasteurProvider);
    final isPatriarche = ref.read(isPatriarcheProvider);
    final tribuId = ref.read(userTribuIdProvider);
    final departementId = ref.read(userDepartementIdProvider);

    if (isPasteur) {
      ref.read(fidelesProvider.notifier).loadAll();
    } else if (isPatriarche && tribuId != null) {
      ref.read(fidelesProvider.notifier).loadByTribu(tribuId);
    } else if (departementId != null) {
      ref.read(fidelesProvider.notifier).loadByDepartement(departementId);
    }
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      _loadFideles();
    } else {
      ref.read(fidelesProvider.notifier).search(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fidelesState = ref.watch(fidelesProvider);
    final isPasteur = ref.watch(isPasteurProvider);
    final isPatriarche = ref.watch(isPatriarcheProvider);
    final canAddFidele = isPasteur || isPatriarche;

    // Filtrer les fidèles selon le statut
    final filteredFideles = fidelesState.fideles.where((f) {
      if (_filterStatus == 'actifs') return f.actif;
      if (_filterStatus == 'inactifs') return !f.actif;
      return true;
    }).toList();

    final totalCount = fidelesState.fideles.length;
    final actifsCount = fidelesState.fideles.where((f) => f.actif).length;
    final inactifsCount = totalCount - actifsCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Fidèles',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
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
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'tous',
                child: Row(
                  children: [
                    Icon(
                      _filterStatus == 'tous' ? Icons.check_circle : Icons.circle_outlined,
                      color: _filterStatus == 'tous' ? AppColors.primary : AppColors.textHint,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('Tous'),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$totalCount',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'actifs',
                child: Row(
                  children: [
                    Icon(
                      _filterStatus == 'actifs' ? Icons.check_circle : Icons.circle_outlined,
                      color: _filterStatus == 'actifs' ? AppColors.actif : AppColors.textHint,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('Actifs'),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.actif.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$actifsCount',
                        style: TextStyle(fontSize: 12, color: AppColors.actif),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'inactifs',
                child: Row(
                  children: [
                    Icon(
                      _filterStatus == 'inactifs' ? Icons.check_circle : Icons.circle_outlined,
                      color: _filterStatus == 'inactifs' ? AppColors.inactif : AppColors.textHint,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('Inactifs'),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.inactif.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$inactifsCount',
                        style: TextStyle(fontSize: 12, color: AppColors.inactif),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche moderne
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Rechercher un fidèle...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Filtre actif
          if (_filterStatus != 'tous')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface,
              child: Wrap(
                children: [
                  Chip(
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
                    onDeleted: () {
                      setState(() {
                        _filterStatus = 'tous';
                      });
                    },
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ),

          // Liste des fidèles
          Expanded(
            child: fidelesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : fidelesState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.error.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              fidelesState.error!,
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadFideles,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Réessayer'),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : filteredFideles.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(10),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.people_outline_rounded,
                                    size: 64,
                                    color: AppColors.textHint,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _filterStatus != 'tous'
                                      ? 'Aucun fidèle ${_filterStatus == 'actifs' ? 'actif' : 'inactif'}'
                                      : 'Aucun fidèle',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (canAddFidele && _filterStatus == 'tous') ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Ajoutez votre premier fidèle',
                                    style: TextStyle(color: AppColors.textHint),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _loadFideles(),
                            color: AppColors.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredFideles.length,
                              itemBuilder: (context, index) {
                                final fidele = filteredFideles[index];
                                return FideleCard(
                                  fidele: fidele,
                                  onTap: () => context.goToFidele(fidele.id),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: canAddFidele
          ? FloatingActionButton.extended(
              onPressed: () => context.go(AppRoutes.fideleForm),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Nouveau'),
            )
          : null,
    );
  }
}
