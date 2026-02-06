import 'package:equatable/equatable.dart';
import 'enums.dart';

/// Modèle pour un fidèle (membre de l'église)
class FideleModel extends Equatable {
  final String id;
  final String nom;
  final String prenom;
  final Sexe sexe;
  final int? jourNaissance; // Jour (1-31)
  final int? moisNaissance; // Mois (1-12)
  final int? anneeNaissance; // Année (optionnelle et cachée)
  final String? telephone;
  final String? adresse;
  final String? profession;
  final String? invitePar; // ID du fidèle qui l'a invité
  final String tribuId;
  final String? photoUrl;
  final bool actif;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Relations (chargées séparément)
  final String? tribuNom;
  final String? inviteParNom;
  final List<String>? departementsIds;

  const FideleModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.sexe,
    this.jourNaissance,
    this.moisNaissance,
    this.anneeNaissance,
    this.telephone,
    this.adresse,
    this.profession,
    this.invitePar,
    required this.tribuId,
    this.photoUrl,
    this.actif = true,
    required this.createdAt,
    this.updatedAt,
    this.tribuNom,
    this.inviteParNom,
    this.departementsIds,
  });

  /// Nom complet
  String get nomComplet => '$prenom $nom';

  /// Initiales
  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    return '$p$n'.toUpperCase();
  }

  /// Date de naissance formatée (jour/mois seulement)
  String get dateNaissanceFormatee {
    if (jourNaissance == null || moisNaissance == null) return '';
    final jour = jourNaissance.toString().padLeft(2, '0');
    final mois = moisNaissance.toString().padLeft(2, '0');
    return '$jour/$mois';
  }

  /// Vérifie si l'anniversaire est aujourd'hui
  bool get isAnniversaireAujourdhui {
    if (jourNaissance == null || moisNaissance == null) return false;
    final now = DateTime.now();
    return jourNaissance == now.day && moisNaissance == now.month;
  }

  /// Vérifie si l'anniversaire est cette semaine
  bool get isAnniversaireCetteSemaine {
    if (jourNaissance == null || moisNaissance == null) return false;
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final checkDate = now.add(Duration(days: i));
      if (jourNaissance == checkDate.day && moisNaissance == checkDate.month) {
        return true;
      }
    }
    return false;
  }

  /// Vérifie si l'anniversaire est ce mois
  bool get isAnniversaireCeMois {
    if (moisNaissance == null) return false;
    return moisNaissance == DateTime.now().month;
  }

  /// Jours jusqu'au prochain anniversaire
  int? get joursJusquAnniversaire {
    if (jourNaissance == null || moisNaissance == null) return null;
    final now = DateTime.now();
    var nextBirthday = DateTime(now.year, moisNaissance!, jourNaissance!);
    if (nextBirthday.isBefore(now) || nextBirthday.isAtSameMomentAs(now)) {
      nextBirthday = DateTime(now.year + 1, moisNaissance!, jourNaissance!);
    }
    return nextBirthday.difference(now).inDays;
  }

  /// Création depuis JSON (Supabase)
  factory FideleModel.fromJson(Map<String, dynamic> json) {
    return FideleModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      sexe: Sexe.fromString(json['sexe'] as String),
      jourNaissance: json['jour_naissance'] as int?,
      moisNaissance: json['mois_naissance'] as int?,
      anneeNaissance: json['annee_naissance'] as int?,
      telephone: json['telephone'] as String?,
      adresse: json['adresse'] as String?,
      profession: json['profession'] as String?,
      invitePar: json['invite_par'] as String?,
      tribuId: json['tribu_id'] as String,
      photoUrl: json['photo_url'] as String?,
      actif: json['actif'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      tribuNom: json['tribu']?['nom'] as String?,
      inviteParNom: json['invite_par_fidele'] != null
          ? '${json['invite_par_fidele']['prenom']} ${json['invite_par_fidele']['nom']}'
          : null,
    );
  }

  /// Conversion en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'sexe': sexe.code,
      'jour_naissance': jourNaissance,
      'mois_naissance': moisNaissance,
      'annee_naissance': anneeNaissance,
      'telephone': telephone,
      'adresse': adresse,
      'profession': profession,
      'invite_par': invitePar,
      'tribu_id': tribuId,
      'photo_url': photoUrl,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// JSON pour insertion (sans id ni timestamps)
  Map<String, dynamic> toInsertJson() {
    return {
      'nom': nom,
      'prenom': prenom,
      'sexe': sexe.code,
      'jour_naissance': jourNaissance,
      'mois_naissance': moisNaissance,
      'annee_naissance': anneeNaissance,
      'telephone': telephone,
      'adresse': adresse,
      'profession': profession,
      'invite_par': invitePar,
      'tribu_id': tribuId,
      'photo_url': photoUrl,
      'actif': actif,
    };
  }

  /// Copie avec modifications
  FideleModel copyWith({
    String? id,
    String? nom,
    String? prenom,
    Sexe? sexe,
    int? jourNaissance,
    int? moisNaissance,
    int? anneeNaissance,
    String? telephone,
    String? adresse,
    String? profession,
    String? invitePar,
    String? tribuId,
    String? photoUrl,
    bool? actif,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? tribuNom,
    String? inviteParNom,
    List<String>? departementsIds,
  }) {
    return FideleModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      sexe: sexe ?? this.sexe,
      jourNaissance: jourNaissance ?? this.jourNaissance,
      moisNaissance: moisNaissance ?? this.moisNaissance,
      anneeNaissance: anneeNaissance ?? this.anneeNaissance,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      profession: profession ?? this.profession,
      invitePar: invitePar ?? this.invitePar,
      tribuId: tribuId ?? this.tribuId,
      photoUrl: photoUrl ?? this.photoUrl,
      actif: actif ?? this.actif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tribuNom: tribuNom ?? this.tribuNom,
      inviteParNom: inviteParNom ?? this.inviteParNom,
      departementsIds: departementsIds ?? this.departementsIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nom,
        prenom,
        sexe,
        jourNaissance,
        moisNaissance,
        anneeNaissance,
        telephone,
        adresse,
        profession,
        invitePar,
        tribuId,
        photoUrl,
        actif,
        createdAt,
        updatedAt,
      ];
}
