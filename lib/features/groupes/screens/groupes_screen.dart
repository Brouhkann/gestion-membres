import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/tribu_model.dart';
import '../../../data/models/departement_model.dart';
import '../../../data/models/cellule_model.dart';
import '../../../providers/tribu_provider.dart';
import '../../../providers/departement_provider.dart';
import '../../../providers/cellule_provider.dart';
import '../../../providers/auth_provider.dart';

class GroupesScreen extends ConsumerStatefulWidget {
  const GroupesScreen({super.key});

  @override
  ConsumerState<GroupesScreen> createState() => _GroupesScreenState();
}

class _GroupesScreenState extends ConsumerState<GroupesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tribusProvider.notifier).loadAllWithStats();
      ref.read(departementsProvider.notifier).loadAllWithStats();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Groupes',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Tribus'),
            Tab(text: 'Départements'),
            Tab(text: 'Cellules'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TribusTab(),
          _DepartementsTab(),
          _CellulesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddTribuDialog(context);
          } else if (_tabController.index == 1) {
            _showAddDepartementDialog(context);
          } else {
            _showAddCelluleDialog(context);
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: Text(
          _tabController.index == 0
              ? 'Tribu'
              : _tabController.index == 1
                  ? 'Département'
                  : 'Cellule',
        ),
      ),
    );
  }

  void _showAddTribuDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Nouvelle Tribu',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nomController,
                    decoration: InputDecoration(
                      labelText: 'Nom de la tribu',
                      prefixIcon: const Icon(Icons.groups),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (optionnel)',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                setState(() => isLoading = true);

                                final egliseId = ref.read(userEgliseIdProvider);
                                if (egliseId == null) {
                                  context.showErrorSnackBar('Erreur: église non trouvée');
                                  setState(() => isLoading = false);
                                  return;
                                }

                                final tribu = TribuModel(
                                  id: '',
                                  nom: nomController.text.trim(),
                                  description: descriptionController.text.trim().isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                                  egliseId: egliseId,
                                  createdAt: DateTime.now(),
                                );

                                final result = await ref.read(tribusProvider.notifier).create(tribu);

                                if (result != null && context.mounted) {
                                  Navigator.pop(context);
                                  context.showSuccessSnackBar('Tribu créée');
                                } else if (context.mounted) {
                                  context.showErrorSnackBar('Erreur');
                                  setState(() => isLoading = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Créer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDepartementDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Nouveau Département',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nomController,
                    decoration: InputDecoration(
                      labelText: 'Nom du département',
                      prefixIcon: const Icon(Icons.business),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (optionnel)',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                setState(() => isLoading = true);

                                final egliseId = ref.read(userEgliseIdProvider);
                                if (egliseId == null) {
                                  context.showErrorSnackBar('Erreur: église non trouvée');
                                  setState(() => isLoading = false);
                                  return;
                                }

                                final dept = DepartementModel(
                                  id: '',
                                  nom: nomController.text.trim(),
                                  description: descriptionController.text.trim().isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                                  egliseId: egliseId,
                                  createdAt: DateTime.now(),
                                );

                                final result = await ref.read(departementsProvider.notifier).create(dept);

                                if (result != null && context.mounted) {
                                  Navigator.pop(context);
                                  context.showSuccessSnackBar('Département créé');
                                } else if (context.mounted) {
                                  context.showErrorSnackBar('Erreur');
                                  setState(() => isLoading = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Créer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddCelluleDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Nouvelle Cellule',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nomController,
                    decoration: InputDecoration(
                      labelText: 'Nom de la cellule',
                      prefixIcon: const Icon(Icons.cell_tower),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (optionnel)',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                setState(() => isLoading = true);

                                final egliseId = ref.read(userEgliseIdProvider);
                                if (egliseId == null) {
                                  context.showErrorSnackBar('Erreur: église non trouvée');
                                  setState(() => isLoading = false);
                                  return;
                                }

                                final cellule = CelluleModel(
                                  id: '',
                                  nom: nomController.text.trim(),
                                  description: descriptionController.text.trim().isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                                  egliseId: egliseId,
                                  createdAt: DateTime.now(),
                                );

                                final result = await ref.read(cellulesProvider.notifier).create(cellule);

                                if (result != null && context.mounted) {
                                  Navigator.pop(context);
                                  context.showSuccessSnackBar('Cellule créée');
                                } else if (context.mounted) {
                                  context.showErrorSnackBar('Erreur');
                                  setState(() => isLoading = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Créer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TribusTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tribusState = ref.watch(tribusProvider);

    if (tribusState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tribusState.tribus.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 80, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text(
              'Aucune tribu',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Créez votre première tribu',
              style: TextStyle(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(tribusProvider.notifier).loadAllWithStats(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tribusState.tribus.length,
        itemBuilder: (context, index) {
          final tribu = tribusState.tribus[index];
          return _ModernGroupCard(
            title: tribu.nom,
            subtitle: tribu.patriarcheNom ?? 'Pas de patriarche',
            membresCount: tribu.nombreMembres ?? 0,
            membresActifs: tribu.nombreMembresActifs ?? 0,
            icon: Icons.groups_rounded,
            color: AppColors.patriarcheColor,
            onTap: () => context.goToTribu(tribu.id),
          );
        },
      ),
    );
  }
}

class _DepartementsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departementsState = ref.watch(departementsProvider);

    if (departementsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (departementsState.departements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 80, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text(
              'Aucun département',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Créez votre premier département',
              style: TextStyle(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(departementsProvider.notifier).loadAllWithStats(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: departementsState.departements.length,
        itemBuilder: (context, index) {
          final dept = departementsState.departements[index];
          return _ModernGroupCard(
            title: dept.nom,
            subtitle: dept.responsableNom ?? 'Pas de responsable',
            membresCount: dept.nombreMembres ?? 0,
            membresActifs: dept.nombreMembresActifs ?? 0,
            icon: Icons.business_rounded,
            color: AppColors.responsableColor,
            onTap: () => context.goToDepartement(dept.id),
            isBoss: true,
          );
        },
      ),
    );
  }
}

class _CellulesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cellulesState = ref.watch(cellulesProvider);

    if (cellulesState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (cellulesState.cellules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cell_tower_outlined, size: 80, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text(
              'Aucune cellule',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Créez votre première cellule',
              style: TextStyle(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          ref.read(cellulesProvider.notifier).loadAllWithStats(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cellulesState.cellules.length,
        itemBuilder: (context, index) {
          final cellule = cellulesState.cellules[index];
          return _ModernGroupCard(
            title: cellule.nom,
            subtitle: cellule.responsableNom ?? 'Pas de responsable',
            membresCount: cellule.nombreMembres ?? 0,
            membresActifs: cellule.nombreMembresActifs ?? 0,
            icon: Icons.cell_tower_rounded,
            color: AppColors.responsableColor,
            onTap: () => context.goToCellule(cellule.id),
          );
        },
      ),
    );
  }
}

class _ModernGroupCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int membresCount;
  final int membresActifs;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isBoss;

  const _ModernGroupCard({
    required this.title,
    required this.subtitle,
    required this.membresCount,
    required this.membresActifs,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isBoss = false,
  });

  @override
  Widget build(BuildContext context) {
    final tauxActifs = membresCount > 0
        ? ((membresActifs / membresCount) * 100).toStringAsFixed(0)
        : '0';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$membresCount ${isBoss ? "BOSS" : ""}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$tauxActifs% actifs',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
