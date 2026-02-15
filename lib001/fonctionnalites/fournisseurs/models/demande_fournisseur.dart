class DemandeFournisseur {
  final String id;
  final String demandeurId;
  final String? transactionId;

  final String produitRecherche;
  final int? quantite;
  final int? budget;
  final String? ville;
  final String? pays;
  final String? livraisonVille;
  final String? details;

  final bool active;
  final DateTime createdAt;
  final DateTime expireAt;

  const DemandeFournisseur({
    required this.id,
    required this.demandeurId,
    required this.transactionId,
    required this.produitRecherche,
    required this.quantite,
    required this.budget,
    required this.ville,
    required this.pays,
    required this.livraisonVille,
    required this.details,
    required this.active,
    required this.createdAt,
    required this.expireAt,
  });

  factory DemandeFournisseur.fromMap(Map<String, dynamic> map) {
    return DemandeFournisseur(
      id: map['id'] as String,
      demandeurId: map['demandeur_id'] as String,
      transactionId: map['transaction_id'] as String?,
      produitRecherche: map['produit_recherche'] as String,
      quantite: map['quantite'] as int?,
      budget: map['budget'] as int?,
      ville: map['ville'] as String?,
      pays: map['pays'] as String?,
      livraisonVille: map['livraison_ville'] as String?,
      details: map['details'] as String?,
      active: map['active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      expireAt: DateTime.parse(map['expire_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'demandeur_id': demandeurId,
      'transaction_id': transactionId,
      'produit_recherche': produitRecherche,
      'quantite': quantite,
      'budget': budget,
      'ville': ville,
      'pays': pays,
      'livraison_ville': livraisonVille,
      'details': details,
      'active': active,
      'created_at': createdAt.toIso8601String(),
      'expire_at': expireAt.toIso8601String(),
    };
  }
}

