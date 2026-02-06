class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'EgliseApp';
  static const String appTagline = 'Gérez votre église efficacement';

  // Auth
  static const String login = 'Connexion';
  static const String logout = 'Déconnexion';
  static const String phone = 'Numéro de téléphone';
  static const String password = 'Mot de passe';
  static const String forgotPassword = 'Mot de passe oublié ?';
  static const String loginButton = 'Se connecter';

  // Rôles
  static const String pasteur = 'Pasteur';
  static const String patriarche = 'Patriarche';
  static const String responsable = 'Responsable';

  // Navigation
  static const String dashboard = 'Tableau de bord';
  static const String fideles = 'Fidèles';
  static const String tribus = 'Tribus';
  static const String departements = 'Départements';
  static const String presences = 'Présences';
  static const String anniversaires = 'Anniversaires';
  static const String parametres = 'Paramètres';

  // Fidèles
  static const String nouveauFidele = 'Nouveau fidèle';
  static const String modifierFidele = 'Modifier le fidèle';
  static const String nom = 'Nom';
  static const String prenom = 'Prénom';
  static const String sexe = 'Sexe';
  static const String homme = 'Homme';
  static const String femme = 'Femme';
  static const String dateNaissance = 'Date de naissance';
  static const String telephone = 'Téléphone WhatsApp';
  static const String adresse = 'Adresse';
  static const String profession = 'Profession';
  static const String invitePar = 'Invité par';
  static const String tribu = 'Tribu';
  static const String actif = 'Actif';
  static const String inactif = 'Inactif';

  // Tribus
  static const String nouvelleTribu = 'Nouvelle tribu';
  static const String modifierTribu = 'Modifier la tribu';
  static const String nomTribu = 'Nom de la tribu';
  static const String selectPatriarche = 'Sélectionner un patriarche';

  // Départements
  static const String nouveauDepartement = 'Nouveau département';
  static const String modifierDepartement = 'Modifier le département';
  static const String nomDepartement = 'Nom du département';
  static const String selectResponsable = 'Sélectionner un responsable';

  // Présences / Appel
  static const String appel = 'Appel';
  static const String faireAppel = 'Faire l\'appel';
  static const String historiqueAppels = 'Historique des appels';
  static const String present = 'Présent';
  static const String absent = 'Absent';
  static const String enregistrerAppel = 'Enregistrer l\'appel';

  // Statistiques
  static const String totalFideles = 'Total fidèles';
  static const String membresActifs = 'Membres actifs';
  static const String tauxPresence = 'Taux de présence';

  // Actions
  static const String ajouter = 'Ajouter';
  static const String modifier = 'Modifier';
  static const String supprimer = 'Supprimer';
  static const String enregistrer = 'Enregistrer';
  static const String annuler = 'Annuler';
  static const String confirmer = 'Confirmer';
  static const String rechercher = 'Rechercher';
  static const String filtrer = 'Filtrer';
  static const String voirTout = 'Voir tout';
  static const String voirDetails = 'Voir détails';

  // Messages
  static const String chargement = 'Chargement...';
  static const String aucunResultat = 'Aucun résultat';
  static const String erreur = 'Une erreur est survenue';
  static const String succes = 'Opération réussie';
  static const String confirmationSuppression = 'Êtes-vous sûr de vouloir supprimer ?';

  // Anniversaires
  static const String anniversairesAujourdhui = 'Aujourd\'hui';
  static const String anniversairesCetteSemaine = 'Cette semaine';
  static const String anniversairesCeMois = 'Ce mois';

  // Validation
  static const String champObligatoire = 'Ce champ est obligatoire';
  static const String telephoneInvalide = 'Numéro de téléphone invalide';
  static const String motDePasseMinimum = 'Minimum 6 caractères';
}
