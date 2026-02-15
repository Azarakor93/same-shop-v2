class Enchere {
  final String id;
  final String vendeurId;
  final String titre;
  final String? description;
  final String lotTexte;
  final int quantite;
  final int prixDepart;
  final String dureeType; // '1h','6h','24h','3j','7j'
  final DateTime dateFin;
  final String statut; // 'en_cours','termine','annule'
  final String? gagnantId;
  final String? meilleureOffreId;
  final DateTime createdAt;

  const Enchere({
    required this.id,
    required this.vendeurId,
    required this.titre,
    required this.description,
    required this.lotTexte,
    required this.quantite,
    required this.prixDepart,
    required this.dureeType,
    required this.dateFin,
    required this.statut,
    required this.gagnantId,
    required this.meilleureOffreId,
    required this.createdAt,
  });

  factory Enchere.fromMap(Map<String, dynamic> map) {
    return Enchere(
      id: map['id'] as String,
      vendeurId: map['vendeur_id'] as String,
      titre: map['titre'] as String,
      description: map['description'] as String?,
      lotTexte: map['lot_texte'] as String,
      quantite: (map['quantite'] as num?)?.toInt() ?? 1,
      prixDepart: (map['prix_depart'] as num).toInt(),
      dureeType: map['duree_type'] as String,
      dateFin: DateTime.parse(map['date_fin'] as String),
      statut: map['statut'] as String,
      gagnantId: map['gagnant_id'] as String?,
      meilleureOffreId: map['meilleure_offre_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

