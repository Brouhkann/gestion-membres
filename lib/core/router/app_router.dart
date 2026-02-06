import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/enums.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/super_admin/screens/super_admin_dashboard.dart';
import '../../features/super_admin/screens/eglises_list_screen.dart';
import '../../features/super_admin/screens/pasteurs_list_screen.dart';
import '../../features/eglise/screens/eglise_setup_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/dashboard/screens/patriarche_dashboard.dart';
import '../../features/dashboard/screens/responsable_dashboard.dart';
import '../../features/fideles/screens/fideles_list_screen.dart';
import '../../features/fideles/screens/fidele_form_screen.dart';
import '../../features/fideles/screens/fidele_detail_screen.dart';
import '../../features/tribus/screens/tribus_list_screen.dart';
import '../../features/tribus/screens/tribu_detail_screen.dart';
import '../../features/departements/screens/departements_list_screen.dart';
import '../../features/departements/screens/departement_detail_screen.dart';
import '../../features/presences/screens/appel_screen.dart';
import '../../features/presences/screens/historique_presences_screen.dart';
import '../../features/anniversaires/screens/anniversaires_screen.dart';

/// Clé de navigation globale
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Routes de l'application
class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String egliseSetup = '/eglise/setup';
  static const String eglises = '/eglises';
  static const String pasteurs = '/pasteurs';
  static const String statistiques = '/statistiques';
  static const String parametres = '/parametres';
  static const String fideles = '/fideles';
  static const String fideleDetail = '/fideles/:id';
  static const String fideleForm = '/fideles/form';
  static const String fideleEdit = '/fideles/:id/edit';
  static const String tribus = '/tribus';
  static const String tribuDetail = '/tribus/:id';
  static const String departements = '/departements';
  static const String departementDetail = '/departements/:id';
  static const String appel = '/appel';
  static const String historiquePresences = '/presences/historique';
  static const String anniversaires = '/anniversaires';
}

/// Provider pour le router
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.login,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final user = authState.user;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;
      final isSetupRoute = state.matchedLocation == AppRoutes.egliseSetup;

      // Si pas authentifié et pas sur login, redirige vers login
      if (!isAuthenticated && !isLoginRoute) {
        return AppRoutes.login;
      }

      // Si authentifié et sur login, redirige vers dashboard
      if (isAuthenticated && isLoginRoute) {
        // Si pasteur et première connexion, redirige vers setup
        if (user != null && user.isPasteur && user.premiereConnexion) {
          return AppRoutes.egliseSetup;
        }
        return AppRoutes.dashboard;
      }

      // Si pasteur avec première connexion mais pas sur setup, redirige
      if (isAuthenticated && user != null && user.isPasteur &&
          user.premiereConnexion && !isSetupRoute) {
        return AppRoutes.egliseSetup;
      }

      return null;
    },
    routes: [
      // Login
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Configuration église (première connexion pasteur)
      GoRoute(
        path: AppRoutes.egliseSetup,
        name: 'eglise-setup',
        builder: (context, state) => const EgliseSetupScreen(),
      ),

      // Dashboard (redirige selon le rôle)
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) {
          final user = ref.read(currentUserProvider);
          if (user == null) return const LoginScreen();

          switch (user.role) {
            case UserRole.superAdmin:
              return const SuperAdminDashboard();
            case UserRole.pasteur:
              return const MainShell();
            case UserRole.patriarche:
              return const PatriarcheDashboard();
            case UserRole.responsable:
              return const ResponsableDashboard();
          }
        },
      ),

      // Routes Super Admin
      GoRoute(
        path: AppRoutes.eglises,
        name: 'eglises',
        builder: (context, state) => const EglisesListScreen(),
      ),
      GoRoute(
        path: AppRoutes.pasteurs,
        name: 'pasteurs',
        builder: (context, state) => const PasteursListScreen(),
      ),

      // Fidèles
      GoRoute(
        path: AppRoutes.fideles,
        name: 'fideles',
        builder: (context, state) => const FidelesListScreen(),
      ),
      GoRoute(
        path: AppRoutes.fideleDetail,
        name: 'fidele-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FideleDetailScreen(fideleId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.fideleForm,
        name: 'fidele-form',
        builder: (context, state) {
          final fideleId = state.uri.queryParameters['id'];
          return FideleFormScreen(fideleId: fideleId);
        },
      ),

      // Tribus
      GoRoute(
        path: AppRoutes.tribus,
        name: 'tribus',
        builder: (context, state) => const TribusListScreen(),
      ),
      GoRoute(
        path: AppRoutes.tribuDetail,
        name: 'tribu-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TribuDetailScreen(tribuId: id);
        },
      ),

      // Départements
      GoRoute(
        path: AppRoutes.departements,
        name: 'departements',
        builder: (context, state) => const DepartementsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.departementDetail,
        name: 'departement-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DepartementDetailScreen(departementId: id);
        },
      ),

      // Présences
      GoRoute(
        path: AppRoutes.appel,
        name: 'appel',
        builder: (context, state) {
          final typeGroupe = state.uri.queryParameters['type'] ?? 'tribu';
          final groupeId = state.uri.queryParameters['groupeId'] ?? '';
          return AppelScreen(
            typeGroupe: typeGroupe == 'tribu'
                ? TypeGroupe.tribu
                : TypeGroupe.departement,
            groupeId: groupeId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.historiquePresences,
        name: 'historique-presences',
        builder: (context, state) {
          final typeGroupe = state.uri.queryParameters['type'] ?? 'tribu';
          final groupeId = state.uri.queryParameters['groupeId'] ?? '';
          return HistoriquePresencesScreen(
            typeGroupe: typeGroupe == 'tribu'
                ? TypeGroupe.tribu
                : TypeGroupe.departement,
            groupeId: groupeId,
          );
        },
      ),

      // Anniversaires
      GoRoute(
        path: AppRoutes.anniversaires,
        name: 'anniversaires',
        builder: (context, state) => const AnniversairesScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page non trouvée',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.matchedLocation),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Retour au tableau de bord'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Extension pour la navigation
extension GoRouterExtension on BuildContext {
  void goToFidele(String id) => go('${AppRoutes.fideles}/$id');
  void goToTribu(String id) => go('${AppRoutes.tribus}/$id');
  void goToDepartement(String id) => go('${AppRoutes.departements}/$id');
  void goToAppel(TypeGroupe type, String groupeId) =>
      go('${AppRoutes.appel}?type=${type.name}&groupeId=$groupeId');
  void goToHistorique(TypeGroupe type, String groupeId) =>
      go('${AppRoutes.historiquePresences}?type=${type.name}&groupeId=$groupeId');
}
