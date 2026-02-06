import 'package:equatable/equatable.dart';
import 'enums.dart';

/// Modèle pour une session d'appel (une date + un groupe)
class SessionAppelModel extends Equatable {
  final String id;
  final DateTime date;
  final TypeGroupe typeGroupe;
  final String groupeId; // ID de la tribu ou du département
  final String createdBy; // ID de l'utilisateur qui a fait l'appel
  final DateTime createdAt;

  // Relations
  final String? groupeNom;
  final int? nombrePresents;
  final int? nombreAbsents;
  final int? totalMembres;

  const SessionAppelModel({
    required this.id,
    required this.date,
    required this.typeGroupe,
    required this.groupeId,
    required this.createdBy,
    required this.createdAt,
    this.groupeNom,
    this.nombrePresents,
    this.nombreAbsents,
    this.totalMembres,
  });

  /// Taux de présence
  double get tauxPresence {
    if (totalMembres == null || totalMembres == 0) return 0;
    return ((nombrePresents ?? 0) / totalMembres!) * 100;
  }

  /// Date formatée
  String get dateFormatee {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  factory SessionAppelModel.fromJson(Map<String, dynamic> json) {
    return SessionAppelModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      typeGroupe: TypeGroupe.values.firstWhere(
        (e) => e.name == json['type_groupe'],
        orElse: () => TypeGroupe.tribu,
      ),
      groupeId: json['groupe_id'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      groupeNom: json['groupe_nom'] as String?,
      nombrePresents: json['nombre_presents'] as int?,
      nombreAbsents: json['nombre_absents'] as int?,
      totalMembres: json['total_membres'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0], // Date seulement
      'type_groupe': typeGroupe.name,
      'groupe_id': groupeId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'type_groupe': typeGroupe.name,
      'groupe_id': groupeId,
      'created_by': createdBy,
    };
  }

  @override
  List<Object?> get props => [
        id,
        date,
        typeGroupe,
        groupeId,
        createdBy,
        createdAt,
      ];
}

/// Modèle pour une présence individuelle
class PresenceModel extends Equatable {
  final String id;
  final String sessionId;
  final String fideleId;
  final StatutPresence statut;
  final DateTime createdAt;

  // Relations
  final String? fideleNom;
  final String? fidelePrenom;
  final String? fidelePhotoUrl;

  const PresenceModel({
    required this.id,
    required this.sessionId,
    required this.fideleId,
    required this.statut,
    required this.createdAt,
    this.fideleNom,
    this.fidelePrenom,
    this.fidelePhotoUrl,
  });

  /// Nom complet du fidèle
  String get fideleNomComplet {
    if (fidelePrenom == null || fideleNom == null) return '';
    return '$fidelePrenom $fideleNom';
  }

  /// Est présent
  bool get estPresent => statut == StatutPresence.present;

  factory PresenceModel.fromJson(Map<String, dynamic> json) {
    return PresenceModel(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      fideleId: json['fidele_id'] as String,
      statut: StatutPresence.fromString(json['statut'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      fideleNom: json['fidele']?['nom'] as String?,
      fidelePrenom: json['fidele']?['prenom'] as String?,
      fidelePhotoUrl: json['fidele']?['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'fidele_id': fideleId,
      'statut': statut.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'session_id': sessionId,
      'fidele_id': fideleId,
      'statut': statut.name,
    };
  }

  PresenceModel copyWith({
    String? id,
    String? sessionId,
    String? fideleId,
    StatutPresence? statut,
    DateTime? createdAt,
    String? fideleNom,
    String? fidelePrenom,
    String? fidelePhotoUrl,
  }) {
    return PresenceModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      fideleId: fideleId ?? this.fideleId,
      statut: statut ?? this.statut,
      createdAt: createdAt ?? this.createdAt,
      fideleNom: fideleNom ?? this.fideleNom,
      fidelePrenom: fidelePrenom ?? this.fidelePrenom,
      fidelePhotoUrl: fidelePhotoUrl ?? this.fidelePhotoUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
        fideleId,
        statut,
        createdAt,
      ];
}

/// Modèle pour l'appel en cours (état temporaire)
class AppelEnCoursModel {
  final DateTime date;
  final TypeGroupe typeGroupe;
  final String groupeId;
  final String groupeNom;
  final List<FideleAppelItem> fideles;
  final List<FideleAppelItem> fidelesAppeles;

  AppelEnCoursModel({
    required this.date,
    required this.typeGroupe,
    required this.groupeId,
    required this.groupeNom,
    required this.fideles,
    List<FideleAppelItem>? fidelesAppeles,
  }) : fidelesAppeles = fidelesAppeles ?? [];

  /// Fidèles non encore appelés
  List<FideleAppelItem> get fidelesNonAppeles {
    final appelesIds = fidelesAppeles.map((f) => f.fideleId).toSet();
    return fideles.where((f) => !appelesIds.contains(f.fideleId)).toList();
  }

  /// Nombre de présents
  int get nombrePresents =>
      fidelesAppeles.where((f) => f.statut == StatutPresence.present).length;

  /// Nombre d'absents
  int get nombreAbsents =>
      fidelesAppeles.where((f) => f.statut == StatutPresence.absent).length;

  /// L'appel est-il terminé ?
  bool get estTermine => fidelesNonAppeles.isEmpty;

  /// Copie avec modifications
  AppelEnCoursModel copyWith({
    DateTime? date,
    TypeGroupe? typeGroupe,
    String? groupeId,
    String? groupeNom,
    List<FideleAppelItem>? fideles,
    List<FideleAppelItem>? fidelesAppeles,
  }) {
    return AppelEnCoursModel(
      date: date ?? this.date,
      typeGroupe: typeGroupe ?? this.typeGroupe,
      groupeId: groupeId ?? this.groupeId,
      groupeNom: groupeNom ?? this.groupeNom,
      fideles: fideles ?? this.fideles,
      fidelesAppeles: fidelesAppeles ?? this.fidelesAppeles,
    );
  }
}

/// Item d'un fidèle dans l'appel
class FideleAppelItem {
  final String fideleId;
  final String nom;
  final String prenom;
  final String? photoUrl;
  final StatutPresence? statut;

  FideleAppelItem({
    required this.fideleId,
    required this.nom,
    required this.prenom,
    this.photoUrl,
    this.statut,
  });

  String get nomComplet => '$prenom $nom';

  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    return '$p$n'.toUpperCase();
  }

  FideleAppelItem copyWith({StatutPresence? statut}) {
    return FideleAppelItem(
      fideleId: fideleId,
      nom: nom,
      prenom: prenom,
      photoUrl: photoUrl,
      statut: statut ?? this.statut,
    );
  }
}
