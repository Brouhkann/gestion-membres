import 'package:equatable/equatable.dart';

/// Modèle pour une tribu
class TribuModel extends Equatable {
  final String id;
  final String nom;
  final String? description;
  final String egliseId; // ID de l'église
  final String? patriarcheId; // ID du fidèle patriarche
  final bool actif;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Relations (chargées séparément)
  final String? patriarcheNom;
  final int? nombreMembres;
  final int? nombreMembresActifs;

  const TribuModel({
    required this.id,
    required this.nom,
    this.description,
    required this.egliseId,
    this.patriarcheId,
    this.actif = true,
    required this.createdAt,
    this.updatedAt,
    this.patriarcheNom,
    this.nombreMembres,
    this.nombreMembresActifs,
  });

  /// Taux de membres actifs
  double get tauxActifs {
    if (nombreMembres == null || nombreMembres == 0) return 0;
    return ((nombreMembresActifs ?? 0) / nombreMembres!) * 100;
  }

  /// Création depuis JSON (Supabase)
  factory TribuModel.fromJson(Map<String, dynamic> json) {
    return TribuModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      description: json['description'] as String?,
      egliseId: json['eglise_id'] as String,
      patriarcheId: json['patriarche_id'] as String?,
      actif: json['actif'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      patriarcheNom: json['patriarche'] != null
          ? '${json['patriarche']['prenom']} ${json['patriarche']['nom']}'
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
      'patriarche_id': patriarcheId,
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
      'patriarche_id': patriarcheId,
      'actif': actif,
    };
  }

  /// Copie avec modifications
  TribuModel copyWith({
    String? id,
    String? nom,
    String? description,
    String? egliseId,
    String? patriarcheId,
    bool? actif,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? patriarcheNom,
    int? nombreMembres,
    int? nombreMembresActifs,
  }) {
    return TribuModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      egliseId: egliseId ?? this.egliseId,
      patriarcheId: patriarcheId ?? this.patriarcheId,
      actif: actif ?? this.actif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      patriarcheNom: patriarcheNom ?? this.patriarcheNom,
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
        patriarcheId,
        actif,
        createdAt,
        updatedAt,
      ];
}
