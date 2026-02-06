/// Exception de base pour l'application
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Exception d'authentification
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.originalError,
  });

  factory AuthException.invalidCredentials() => const AuthException(
        message: 'Identifiants incorrects',
        code: 'INVALID_CREDENTIALS',
      );

  factory AuthException.userNotFound() => const AuthException(
        message: 'Utilisateur non trouvé',
        code: 'USER_NOT_FOUND',
      );

  factory AuthException.sessionExpired() => const AuthException(
        message: 'Session expirée, veuillez vous reconnecter',
        code: 'SESSION_EXPIRED',
      );

  factory AuthException.unauthorized() => const AuthException(
        message: 'Accès non autorisé',
        code: 'UNAUTHORIZED',
      );
}

/// Exception réseau
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
  });

  factory NetworkException.noConnection() => const NetworkException(
        message: 'Pas de connexion internet',
        code: 'NO_CONNECTION',
      );

  factory NetworkException.timeout() => const NetworkException(
        message: 'La requête a pris trop de temps',
        code: 'TIMEOUT',
      );

  factory NetworkException.serverError() => const NetworkException(
        message: 'Erreur serveur, veuillez réessayer',
        code: 'SERVER_ERROR',
      );
}

/// Exception de base de données
class DatabaseException extends AppException {
  const DatabaseException({
    required super.message,
    super.code,
    super.originalError,
  });

  factory DatabaseException.notFound(String entity) => DatabaseException(
        message: '$entity non trouvé(e)',
        code: 'NOT_FOUND',
      );

  factory DatabaseException.duplicateEntry(String field) => DatabaseException(
        message: '$field existe déjà',
        code: 'DUPLICATE_ENTRY',
      );

  factory DatabaseException.insertFailed() => const DatabaseException(
        message: 'Échec de l\'enregistrement',
        code: 'INSERT_FAILED',
      );

  factory DatabaseException.updateFailed() => const DatabaseException(
        message: 'Échec de la mise à jour',
        code: 'UPDATE_FAILED',
      );

  factory DatabaseException.deleteFailed() => const DatabaseException(
        message: 'Échec de la suppression',
        code: 'DELETE_FAILED',
      );
}

/// Exception de validation
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required super.message,
    super.code,
    this.fieldErrors,
  });

  factory ValidationException.invalidField(String field, String error) =>
      ValidationException(
        message: error,
        code: 'INVALID_FIELD',
        fieldErrors: {field: error},
      );

  factory ValidationException.multipleErrors(Map<String, String> errors) =>
      ValidationException(
        message: 'Veuillez corriger les erreurs',
        code: 'VALIDATION_ERRORS',
        fieldErrors: errors,
      );
}

/// Exception de permission
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
  });

  factory PermissionException.denied(String action) => PermissionException(
        message: 'Vous n\'avez pas la permission de $action',
        code: 'PERMISSION_DENIED',
      );

  factory PermissionException.roleRequired(String role) => PermissionException(
        message: 'Cette action nécessite le rôle $role',
        code: 'ROLE_REQUIRED',
      );
}
