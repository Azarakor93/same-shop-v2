class DemandeFournisseur {
  final String id;
  final String demandeurId;
  final String nomDemandeur;
  final String? transactionId;

  // ✅ SUPPORT MULTI-PRODUITS
  final String titre; // Titre de la demande
  final List<Map<String, dynamic>> produits; // [{nom, quantite, budget_unitaire}]
  final double budgetTotal;

  final String ville;
  final String pays;
  final String? details;

  final bool active;
  final DateTime createdAt;
  final DateTime expireAt;
  final int nombreReponses;

  const DemandeFournisseur({
    required this.id,
    required this.demandeurId,
    required this.nomDemandeur,
    this.transactionId,
    required this.titre,
    required this.produits,
    required this.budgetTotal,
    required this.ville,
    required this.pays,
    this.details,
    this.active = true,
    required this.createdAt,
    required this.expireAt,
    this.nombreReponses = 0,
  });

  // Temps restant avant expiration
  int get joursRestants {
    final maintenant = DateTime.now();
    if (maintenant.isAfter(expireAt)) return 0;
    return expireAt.difference(maintenant).inDays;
  }

  bool get estActive => active && DateTime.now().isBefore(expireAt);

  factory DemandeFournisseur.fromMap(Map<String, dynamic> map) {
    // Support ancien format (produit unique) ET nouveau format (multi-produits)
    List<Map<String, dynamic>> produits = [];
    double budgetTotal = 0;

    if (map['produits'] != null) {
      // Nouveau format multi-produits
      produits = (map['produits'] as List).cast<Map<String, dynamic>>();
      budgetTotal = (map['budget_total'] as num?)?.toDouble() ?? 0;
    } else {
      // Ancien format (migration)
      produits = [
        {
          'nom': map['produit_recherche'] as String,
          'quantite': map['quantite'] as int? ?? 1,
          'budget_unitaire': map['budget'] as int? ?? 0,
        }
      ];
      budgetTotal = (map['budget'] as int? ?? 0).toDouble();
    }

    return DemandeFournisseur(
      id: map['id'] as String,
      demandeurId: map['demandeur_id'] as String,
      nomDemandeur: map['nom_demandeur'] as String? ?? 'Utilisateur',
      transactionId: map['transaction_id'] as String?,
      titre: map['titre'] as String? ?? produits.first['nom'],
      produits: produits,
      budgetTotal: budgetTotal,
      ville: map['ville'] as String? ?? '',
      pays: map['pays'] as String? ?? '',
      details: map['details'] as String?,
      active: map['active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      expireAt: DateTime.parse(map['expire_at'] as String),
      nombreReponses: map['nombre_reponses'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'demandeur_id': demandeurId,
      'nom_demandeur': nomDemandeur,
      'transaction_id': transactionId,
      'titre': titre,
      'produits': produits,
      'budget_total': budgetTotal,
      'ville': ville,
      'pays': pays,
      'details': details,
      'active': active,
      'created_at': createdAt.toIso8601String(),
      'expire_at': expireAt.toIso8601String(),
      'nombre_reponses': nombreReponses,
    };
  }
}

