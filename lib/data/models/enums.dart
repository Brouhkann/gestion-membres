/// Rôles des utilisateurs de l'application
enum UserRole {
  superAdmin,
  pasteur,
  patriarche,
  responsable;

  String get label {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.pasteur:
        return 'Pasteur';
      case UserRole.patriarche:
        return 'Patriarche';
      case UserRole.responsable:
        return 'Responsable';
    }
  }

  String get description {
    switch (this) {
      case UserRole.superAdmin:
        return 'Administrateur plateforme - Gère toutes les églises';
      case UserRole.pasteur:
        return 'Administrateur église - Accès total à son église';
      case UserRole.patriarche:
        return 'Responsable de tribu';
      case UserRole.responsable:
        return 'Responsable de département';
    }
  }

  /// Convertit en valeur pour la base de données
  String get dbValue {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.pasteur:
        return 'pasteur';
      case UserRole.patriarche:
        return 'patriarche';
      case UserRole.responsable:
        return 'responsable';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'super_admin':
      case 'superadmin':
        return UserRole.superAdmin;
      case 'pasteur':
      case 'admin':
        return UserRole.pasteur;
      case 'patriarche':
        return UserRole.patriarche;
      case 'responsable':
        return UserRole.responsable;
      default:
        throw ArgumentError('Rôle inconnu: $value');
    }
  }
}

/// Sexe / Genre
enum Sexe {
  homme,
  femme;

  String get label {
    switch (this) {
      case Sexe.homme:
        return 'Homme';
      case Sexe.femme:
        return 'Femme';
    }
  }

  String get code {
    switch (this) {
      case Sexe.homme:
        return 'M';
      case Sexe.femme:
        return 'F';
    }
  }

  static Sexe fromString(String value) {
    switch (value.toLowerCase()) {
      case 'm':
      case 'homme':
      case 'masculin':
        return Sexe.homme;
      case 'f':
      case 'femme':
      case 'feminin':
        return Sexe.femme;
      default:
        throw ArgumentError('Sexe inconnu: $value');
    }
  }
}

/// Statut de présence
enum StatutPresence {
  present,
  absent;

  String get label {
    switch (this) {
      case StatutPresence.present:
        return 'Présent';
      case StatutPresence.absent:
        return 'Absent';
    }
  }

  static StatutPresence fromString(String value) {
    switch (value.toLowerCase()) {
      case 'present':
      case 'présent':
        return StatutPresence.present;
      case 'absent':
        return StatutPresence.absent;
      default:
        throw ArgumentError('Statut inconnu: $value');
    }
  }
}

/// Type de groupe pour l'appel
enum TypeGroupe {
  tribu,
  departement,
  eglise;

  String get label {
    switch (this) {
      case TypeGroupe.tribu:
        return 'Tribu';
      case TypeGroupe.departement:
        return 'Département';
      case TypeGroupe.eglise:
        return 'Église entière';
    }
  }
}

/// Période pour les anniversaires
enum PeriodeAnniversaire {
  aujourdhui,
  cetteSemaine,
  ceMois;

  String get label {
    switch (this) {
      case PeriodeAnniversaire.aujourdhui:
        return "Aujourd'hui";
      case PeriodeAnniversaire.cetteSemaine:
        return 'Cette semaine';
      case PeriodeAnniversaire.ceMois:
        return 'Ce mois';
    }
  }
}
