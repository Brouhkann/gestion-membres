import 'package:equatable/equatable.dart';
import 'enums.dart';

/// Modèle utilisateur pour l'authentification et les rôles
class UserModel extends Equatable {
  final String id;
  final String telephone;
  final String nom;
  final String prenom;
  final UserRole role;
  final String? egliseId; // L'église à laquelle appartient l'utilisateur
  final String? tribuId; // Pour les patriarches
  final String? departementId; // Pour les responsables de département
  final String? photoUrl;
  final bool actif;
  final bool premiereConnexion; // Pour savoir si le pasteur doit configurer son église
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.telephone,
    required this.nom,
    required this.prenom,
    required this.role,
    this.egliseId,
    this.tribuId,
    this.departementId,
    this.photoUrl,
    this.actif = true,
    this.premiereConnexion = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Nom complet
  String get nomComplet => '$prenom $nom';

  /// Initiales
  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    return '$p$n'.toUpperCase();
  }

  /// Vérifie si c'est un super admin
  bool get isSuperAdmin => role == UserRole.superAdmin;

  /// Vérifie si c'est un pasteur
  bool get isPasteur => role == UserRole.pasteur;

  /// Vérifie si c'est un patriarche
  bool get isPatriarche => role == UserRole.patriarche;

  /// Vérifie si c'est un responsable de département
  bool get isResponsable => role == UserRole.responsable;

  /// Vérifie si le pasteur doit configurer son église
  bool get doitConfigurerEglise => isPasteur && premiereConnexion;

  /// Création depuis JSON (Supabase)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      telephone: json['telephone'] as String,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      role: UserRole.fromString(json['role'] as String),
      egliseId: json['eglise_id'] as String?,
      tribuId: json['tribu_id'] as String?,
      departementId: json['departement_id'] as String?,
      photoUrl: json['photo_url'] as String?,
      actif: json['actif'] as bool? ?? true,
      premiereConnexion: json['premiere_connexion'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Conversion en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'telephone': telephone,
      'nom': nom,
      'prenom': prenom,
      'role': role.dbValue,
      'eglise_id': egliseId,
      'tribu_id': tribuId,
      'departement_id': departementId,
      'photo_url': photoUrl,
      'actif': actif,
      'premiere_connexion': premiereConnexion,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Copie avec modifications
  UserModel copyWith({
    String? id,
    String? telephone,
    String? nom,
    String? prenom,
    UserRole? role,
    String? egliseId,
    String? tribuId,
    String? departementId,
    String? photoUrl,
    bool? actif,
    bool? premiereConnexion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      telephone: telephone ?? this.telephone,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      role: role ?? this.role,
      egliseId: egliseId ?? this.egliseId,
      tribuId: tribuId ?? this.tribuId,
      departementId: departementId ?? this.departementId,
      photoUrl: photoUrl ?? this.photoUrl,
      actif: actif ?? this.actif,
      premiereConnexion: premiereConnexion ?? this.premiereConnexion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        telephone,
        nom,
        prenom,
        role,
        egliseId,
        tribuId,
        departementId,
        photoUrl,
        actif,
        premiereConnexion,
        createdAt,
        updatedAt,
      ];
}
