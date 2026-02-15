class Enchere {
  final String id;
  final String produitId;
  final String nomProduit;
  final String? imageProduit;
  final String boutiqueId;
  final String nomBoutique;
  final double prixDepart;
  final double prixActuel;
  final DateTime dateDebut;
  final DateTime dateFin;
  final int nombreEncherisseurs;
  final String? dernierEncherisseurId;
  final String? dernierEncherisseurNom;
  final String statut; // 'en_cours', 'termine', 'annule'
  final String? description;
  final Map<String, dynamic>? metadata;

  Enchere({
    required this.id,
    required this.produitId,
    required this.nomProduit,
    this.imageProduit,
    required this.boutiqueId,
    required this.nomBoutique,
    required this.prixDepart,
    required this.prixActuel,
    required this.dateDebut,
    required this.dateFin,
    this.nombreEncherisseurs = 0,
    this.dernierEncherisseurId,
    this.dernierEncherisseurNom,
    this.statut = 'en_cours',
    this.description,
    this.metadata,
  });

  // Temps restant
  Duration get tempsRestant {
    final maintenant = DateTime.now();
    if (maintenant.isAfter(dateFin)) {
      return Duration.zero;
    }
    return dateFin.difference(maintenant);
  }

  // Est terminée ?
  bool get estTerminee => DateTime.now().isAfter(dateFin) || statut == 'termine';

  // Est active ?
  bool get estActive => statut == 'en_cours' && !estTerminee;

  // Formatage du temps restant
  String get tempsRestantFormate {
    final duree = tempsRestant;
    if (duree.inDays > 0) {
      return '${duree.inDays}j ${duree.inHours % 24}h';
    } else if (duree.inHours > 0) {
      return '${duree.inHours}h ${duree.inMinutes % 60}m';
    } else if (duree.inMinutes > 0) {
      return '${duree.inMinutes}m ${duree.inSeconds % 60}s';
    } else if (duree.inSeconds > 0) {
      return '${duree.inSeconds}s';
    }
    return 'Terminée';
  }

  factory Enchere.fromJson(Map<String, dynamic> json) {
    return Enchere(
      id: json['id'] as String,
      produitId: json['produit_id'] as String,
      nomProduit: json['nom_produit'] as String,
      imageProduit: json['image_produit'] as String?,
      boutiqueId: json['boutique_id'] as String,
      nomBoutique: json['nom_boutique'] as String,
      prixDepart: (json['prix_depart'] as num).toDouble(),
      prixActuel: (json['prix_actuel'] as num).toDouble(),
      dateDebut: DateTime.parse(json['date_debut'] as String),
      dateFin: DateTime.parse(json['date_fin'] as String),
      nombreEncherisseurs: json['nombre_encherisseurs'] as int? ?? 0,
      dernierEncherisseurId: json['dernier_encherisseur_id'] as String?,
      dernierEncherisseurNom: json['dernier_encherisseur_nom'] as String?,
      statut: json['statut'] as String? ?? 'en_cours',
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produit_id': produitId,
      'nom_produit': nomProduit,
      'image_produit': imageProduit,
      'boutique_id': boutiqueId,
      'nom_boutique': nomBoutique,
      'prix_depart': prixDepart,
      'prix_actuel': prixActuel,
      'date_debut': dateDebut.toIso8601String(),
      'date_fin': dateFin.toIso8601String(),
      'nombre_encherisseurs': nombreEncherisseurs,
      'dernier_encherisseur_id': dernierEncherisseurId,
      'dernier_encherisseur_nom': dernierEncherisseurNom,
      'statut': statut,
      'description': description,
      'metadata': metadata,
    };
  }

  Enchere copyWith({
    String? id,
    String? produitId,
    String? nomProduit,
    String? imageProduit,
    String? boutiqueId,
    String? nomBoutique,
    double? prixDepart,
    double? prixActuel,
    DateTime? dateDebut,
    DateTime? dateFin,
    int? nombreEncherisseurs,
    String? dernierEncherisseurId,
    String? dernierEncherisseurNom,
    String? statut,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return Enchere(
      id: id ?? this.id,
      produitId: produitId ?? this.produitId,
      nomProduit: nomProduit ?? this.nomProduit,
      imageProduit: imageProduit ?? this.imageProduit,
      boutiqueId: boutiqueId ?? this.boutiqueId,
      nomBoutique: nomBoutique ?? this.nomBoutique,
      prixDepart: prixDepart ?? this.prixDepart,
      prixActuel: prixActuel ?? this.prixActuel,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      nombreEncherisseurs: nombreEncherisseurs ?? this.nombreEncherisseurs,
      dernierEncherisseurId: dernierEncherisseurId ?? this.dernierEncherisseurId,
      dernierEncherisseurNom: dernierEncherisseurNom ?? this.dernierEncherisseurNom,
      statut: statut ?? this.statut,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
    );
  }
}
