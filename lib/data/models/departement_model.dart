import 'package:equatable/equatable.dart';

/// Modèle pour un département
class DepartementModel extends Equatable {
  final String id;
  final String nom;
  final String? description;
  final String egliseId; // ID de l'église
  final String? responsableId; // ID du fidèle responsable
  final bool actif;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Relations (chargées séparément)
  final String? responsableNom;
  final int? nombreMembres;
  final int? nombreMembresActifs;

  const DepartementModel({
    required this.id,
    required this.nom,
    this.description,
    required this.egliseId,
    this.responsableId,
    this.actif = true,
    required this.createdAt,
    this.updatedAt,
    this.responsableNom,
    this.nombreMembres,
    this.nombreMembresActifs,
  });

  /// Taux de membres actifs
  double get tauxActifs {
    if (nombreMembres == null || nombreMembres == 0) return 0;
    return ((nombreMembresActifs ?? 0) / nombreMembres!) * 100;
  }

  /// Création depuis JSON (Supabase)
  factory DepartementModel.fromJson(Map<String, dynamic> json) {
    return DepartementModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      description: json['description'] as String?,
      egliseId: json['eglise_id'] as String,
      responsableId: json['responsable_id'] as String?,
      actif: json['actif'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      responsableNom: json['responsable'] != null
          ? '${json['responsable']['prenom']} ${json['responsable']['nom']}'
          : null,
      nombreMembres: json['nombre_membres'] as int?,
      nombreMembresActifs: json['nombre_membres_actifs'] as int?,
    );
  }

  /// Conversion en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'eglise_id': egliseId,
      'responsable_id': responsableId,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// JSON pour insertion (sans id ni timestamps)
  Map<String, dynamic> toInsertJson() {
    return {
      'nom': nom,
      'description': description,
      'eglise_id': egliseId,
      'responsable_id': responsableId,
      'actif': actif,
    };
  }

  /// Copie avec modifications
  DepartementModel copyWith({
    String? id,
    String? nom,
    String? description,
    String? egliseId,
    String? responsableId,
    bool? actif,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? responsableNom,
    int? nombreMembres,
    int? nombreMembresActifs,
  }) {
    return DepartementModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      egliseId: egliseId ?? this.egliseId,
      responsableId: responsableId ?? this.responsableId,
      actif: actif ?? this.actif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      responsableNom: responsableNom ?? this.responsableNom,
      nombreMembres: nombreMembres ?? this.nombreMembres,
      nombreMembresActifs: nombreMembresActifs ?? this.nombreMembresActifs,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nom,
        description,
        egliseId,
        responsableId,
        actif,
        createdAt,
        updatedAt,
      ];
}

/// Modèle pour l'association fidèle-département (table de liaison)
class FideleDepartementModel extends Equatable {
  final String id;
  final String fideleId;
  final String departementId;
  final DateTime createdAt;

  const FideleDepartementModel({
    required this.id,
    required this.fideleId,
    required this.departementId,
    required this.createdAt,
  });

  factory FideleDepartementModel.fromJson(Map<String, dynamic> json) {
    return FideleDepartementModel(
      id: json['id'] as String,
      fideleId: json['fidele_id'] as String,
      departementId: json['departement_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fidele_id': fideleId,
      'departement_id': departementId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'fidele_id': fideleId,
      'departement_id': departementId,
    };
  }

  @override
  List<Object?> get props => [id, fideleId, departementId, createdAt];
}
