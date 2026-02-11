class Annonce {
  final String id;
  final String imageUrl;
  final String? titre;
  final String? lienType;
  final String? lienValeur;

  Annonce({
    required this.id,
    required this.imageUrl,
    this.titre,
    this.lienType,
    this.lienValeur,
  });

  factory Annonce.fromMap(Map<String, dynamic> map) {
    return Annonce(
      id: map['id'],
      imageUrl: map['image_url'],
      titre: map['titre'],
      lienType: map['lien_type'],
      lienValeur: map['lien_valeur'],
    );
  }
}
