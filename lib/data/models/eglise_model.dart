/// Modèle représentant une église
class EgliseModel {
  final String id;
  final String nom;
  final String? logoUrl;
  final String? adresse;
  final String? ville;
  final String? pays;
  final String? telephone;
  final String? email;
  final String? description;
  final String? pasteurId;
  final bool configurationComplete;
  final bool actif;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EgliseModel({
    required this.id,
    required this.nom,
    this.logoUrl,
    this.adresse,
    this.ville,
    this.pays,
    this.telephone,
    this.email,
    this.description,
    this.pasteurId,
    this.configurationComplete = false,
    this.actif = true,
    this.createdAt,
    this.updatedAt,
  });

  factory EgliseModel.fromJson(Map<String, dynamic> json) {
    return EgliseModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      logoUrl: json['logo_url'] as String?,
      adresse: json['adresse'] as String?,
      ville: json['ville'] as String?,
      pays: json['pays'] as String?,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
      description: json['description'] as String?,
      pasteurId: json['pasteur_id'] as String?,
      configurationComplete: json['configuration_complete'] as bool? ?? false,
      actif: json['actif'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'logo_url': logoUrl,
      'adresse': adresse,
      'ville': ville,
      'pays': pays,
      'telephone': telephone,
      'email': email,
      'description': description,
      'pasteur_id': pasteurId,
      'configuration_complete': configurationComplete,
      'actif': actif,
    };
  }

  /// Pour créer une nouvelle église (sans ID)
  Map<String, dynamic> toInsertJson() {
    return {
      'nom': nom,
      'logo_url': logoUrl,
      'adresse': adresse,
      'ville': ville,
      'pays': pays,
      'telephone': telephone,
      'email': email,
      'description': description,
      'pasteur_id': pasteurId,
      'configuration_complete': configurationComplete,
      'actif': actif,
    };
  }

  EgliseModel copyWith({
    String? id,
    String? nom,
    String? logoUrl,
    String? adresse,
    String? ville,
    String? pays,
    String? telephone,
    String? email,
    String? description,
    String? pasteurId,
    bool? configurationComplete,
    bool? actif,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EgliseModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      logoUrl: logoUrl ?? this.logoUrl,
      adresse: adresse ?? this.adresse,
      ville: ville ?? this.ville,
      pays: pays ?? this.pays,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      description: description ?? this.description,
      pasteurId: pasteurId ?? this.pasteurId,
      configurationComplete: configurationComplete ?? this.configurationComplete,
      actif: actif ?? this.actif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'EgliseModel(id: $id, nom: $nom)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EgliseModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
