import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/enums.dart';
import '../services/supabase_service.dart';
import '../../core/exceptions/app_exceptions.dart' as app;

/// Repository pour l'authentification
class AuthRepository {
  final SupabaseService _supabase;

  AuthRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  /// Connexion avec téléphone et mot de passe
  Future<UserModel> signIn({
    required String telephone,
    required String password,
  }) async {
    try {
      // Nettoie le numéro de téléphone
      String cleanPhone = _cleanPhoneNumber(telephone);

      // Crée un email fictif basé sur le téléphone pour Supabase Auth
      final email = '$cleanPhone@eglise.app';

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw app.AuthException.invalidCredentials();
      }

      // Récupère les données utilisateur depuis la table users
      final userData = await _supabase.users
          .select()
          .eq('id', response.user!.id)
          .single();

      return UserModel.fromJson(userData);
    } on app.AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw app.DatabaseException(message: e.message, originalError: e);
    } catch (e) {
      if (e.toString().contains('Invalid login credentials')) {
        throw app.AuthException.invalidCredentials();
      }
      throw app.AuthException(message: 'Erreur de connexion: $e', originalError: e);
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw app.AuthException(message: 'Erreur de déconnexion: $e', originalError: e);
    }
  }

  /// Récupère l'utilisateur actuel
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return null;

      final userData = await _supabase.users
          .select()
          .eq('id', user.id)
          .single();

      return UserModel.fromJson(userData);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // Pas de résultat trouvé
        return null;
      }
      throw app.DatabaseException(message: e.message, originalError: e);
    } catch (e) {
      throw app.AuthException(message: 'Erreur: $e', originalError: e);
    }
  }

  /// Vérifie si l'utilisateur est connecté
  bool get isAuthenticated => _supabase.isAuthenticated;

  /// Stream des changements d'état d'authentification
  Stream<AuthState> get authStateChanges => _supabase.authStateChanges;

  /// Crée un nouvel utilisateur (Super Admin ou Pasteur)
  Future<UserModel> createUser({
    required String telephone,
    required String password,
    required String nom,
    required String prenom,
    required UserRole role,
    String? egliseId,
    String? tribuId,
    String? departementId,
  }) async {
    try {
      String cleanPhone = _cleanPhoneNumber(telephone);
      final email = '$cleanPhone@eglise.app';

      // Crée l'utilisateur dans Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw app.AuthException(message: 'Erreur lors de la création du compte');
      }

      // Crée l'entrée dans la table users
      final userData = {
        'id': authResponse.user!.id,
        'telephone': telephone, // Garde le format original (avec 0)
        'nom': nom,
        'prenom': prenom,
        'role': role.dbValue,
        'eglise_id': egliseId,
        'tribu_id': tribuId,
        'departement_id': departementId,
        'actif': true,
        'premiere_connexion': role == UserRole.pasteur, // true pour pasteur
      };

      final result = await _supabase.users
          .insert(userData)
          .select()
          .single();

      return UserModel.fromJson(result);
    } on app.AuthException {
      rethrow;
    } on PostgrestException catch (e) {
      throw app.DatabaseException(message: e.message, originalError: e);
    } catch (e) {
      throw app.AuthException(message: 'Erreur: $e', originalError: e);
    }
  }

  /// Change le mot de passe
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw app.AuthException(message: 'Erreur: $e', originalError: e);
    }
  }

  /// Met à jour premiere_connexion à false
  Future<void> updatePremiereConnexion(String userId) async {
    try {
      await _supabase.users
          .update({'premiere_connexion': false})
          .eq('id', userId);
    } on PostgrestException catch (e) {
      throw app.DatabaseException(message: e.message, originalError: e);
    }
  }

  /// Nettoie le numéro de téléphone
  String _cleanPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (cleaned.startsWith('+237')) {
      cleaned = cleaned.substring(4);
    } else if (cleaned.startsWith('237')) {
      cleaned = cleaned.substring(3);
    } else if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }

    return cleaned;
  }
}
