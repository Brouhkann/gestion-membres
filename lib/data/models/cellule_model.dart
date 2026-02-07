import 'package:equatable/equatable.dart';

/// Modèle pour une cellule
class CelluleModel extends Equatable {
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

  const CelluleModel({
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
  factory CelluleModel.fromJson(Map<String, dynamic> json) {
    return CelluleModel(
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
  CelluleModel copyWith({
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
    return CelluleModel(
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
