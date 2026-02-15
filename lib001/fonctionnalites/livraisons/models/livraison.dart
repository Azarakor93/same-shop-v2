class Livraison {
  final String id;
  final String clientId;
  final String? vendeurId;
  final String? livreurId;
  final String statut; // en_attente, acceptee, en_cours, livree, annulee

  final int? prixLivraison;
  final int commission;
  final bool demandeSpeciale;
  final int fraisDemandeSpeciale;

  final String? departTexte;
  final String? arriveeTexte;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Livraison({
    required this.id,
    required this.clientId,
    required this.vendeurId,
    required this.livreurId,
    required this.statut,
    required this.prixLivraison,
    required this.commission,
    required this.demandeSpeciale,
    required this.fraisDemandeSpeciale,
    required this.departTexte,
    required this.arriveeTexte,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Livraison.fromMap(Map<String, dynamic> map) {
    return Livraison(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      vendeurId: map['vendeur_id'] as String?,
      livreurId: map['livreur_id'] as String?,
      statut: map['statut'] as String,
      prixLivraison: (map['prix_livraison'] as num?)?.toInt(),
      commission: (map['commission'] as num?)?.toInt() ?? 100,
      demandeSpeciale: map['demande_speciale'] as bool? ?? false,
      fraisDemandeSpeciale:
          (map['frais_demande_speciale'] as num?)?.toInt() ?? 25,
      departTexte: map['depart_texte'] as String?,
      arriveeTexte: map['arrivee_texte'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

