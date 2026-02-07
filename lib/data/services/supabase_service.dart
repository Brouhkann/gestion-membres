import 'package:supabase_flutter/supabase_flutter.dart';

/// Service singleton pour Supabase
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  /// Initialise Supabase avec les credentials
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
    _client = Supabase.instance.client;
  }

  /// Client Supabase
  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call SupabaseService.initialize() first.');
    }
    return _client!;
  }

  /// Auth client
  GoTrueClient get auth => client.auth;

  /// Database client
  SupabaseQueryBuilder from(String table) => client.from(table);

  /// Storage client
  SupabaseStorageClient get storage => client.storage;

  /// Realtime client
  RealtimeClient get realtime => client.realtime;

  /// Session actuelle
  Session? get currentSession => auth.currentSession;

  /// Utilisateur actuel
  User? get currentUser => auth.currentUser;

  /// Vérifie si l'utilisateur est connecté
  bool get isAuthenticated => currentUser != null;

  /// Stream des changements d'auth
  Stream<AuthState> get authStateChanges => auth.onAuthStateChange;
}

/// Extension pour faciliter les appels Supabase
extension SupabaseExtensions on SupabaseService {
  /// Tables
  SupabaseQueryBuilder get users => from('users');
  SupabaseQueryBuilder get fideles => from('fideles');
  SupabaseQueryBuilder get tribus => from('tribus');
  SupabaseQueryBuilder get departements => from('departements');
  SupabaseQueryBuilder get fideleDepartements => from('fidele_departements');
  SupabaseQueryBuilder get cellules => from('cellules');
  SupabaseQueryBuilder get fideleCellules => from('fidele_cellules');
  SupabaseQueryBuilder get sessionsAppel => from('sessions_appel');
  SupabaseQueryBuilder get presences => from('presences');
}
