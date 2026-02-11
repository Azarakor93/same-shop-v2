// 📸 MODÈLE IMAGE PRODUIT
class ProduitImage {
  final String id;
  final String produitId;
  final String url;
  final int ordre;

  const ProduitImage({
    required this.id,
    required this.produitId,
    required this.url,
    this.ordre = 0,
  });

  factory ProduitImage.fromMap(Map<String, dynamic> map) {
    return ProduitImage(
      id: map['id'] as String,
      produitId: map['produit_id'] as String,
      url: map['url'] as String,
      ordre: map['ordre'] as int? ?? 0,
    );
  }
}
