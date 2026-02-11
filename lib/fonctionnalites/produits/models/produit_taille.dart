// 📏 MODÈLE TAILLE PRODUIT
class ProduitTaille {
  final String id;
  final String produitId;
  final String valeur;
  final int stock;
  final DateTime createdAt;

  const ProduitTaille({
    required this.id,
    required this.produitId,
    required this.valeur,
    this.stock = 0,
    required this.createdAt,
  });

  factory ProduitTaille.fromMap(Map<String, dynamic> map) {
    return ProduitTaille(
      id: map['id'] as String,
      produitId: map['produit_id'] as String,
      valeur: map['valeur'] as String,
      stock: map['stock'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'produit_id': produitId,
        'valeur': valeur,
        'stock': stock,
      };

  bool get estDisponible => stock > 0;
}
