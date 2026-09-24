class Favori {
  final String id;
  final String produitId;
  final String nomProduit;
  final String? imageProduit;
  final double prix;
  final String? nomBoutique;
  final DateTime dateAjout;

  Favori({
    required this.id,
    required this.produitId,
    required this.nomProduit,
    this.imageProduit,
    required this.prix,
    this.nomBoutique,
    required this.dateAjout,
  });

  factory Favori.fromJson(Map<String, dynamic> json) {
    return Favori(
      id: json['id'] as String,
      produitId: json['produit_id'] as String,
      nomProduit: json['nom_produit'] as String,
      imageProduit: json['image_produit'] as String?,
      prix: (json['prix'] as num).toDouble(),
      nomBoutique: json['nom_boutique'] as String?,
      dateAjout: DateTime.parse(json['date_ajout'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produit_id': produitId,
      'nom_produit': nomProduit,
      'image_produit': imageProduit,
      'prix': prix,
      'nom_boutique': nomBoutique,
      'date_ajout': dateAjout.toIso8601String(),
    };
  }
}
