// ===============================================
// 🎯 MODÈLE VARIANTE PRODUIT
// ===============================================
class ProduitVariant {
  final String id;
  final String produitId;
  final String? tailleId;
  final String? couleurId;
  final String? sku;
  final int stock;
  final int? prixAjuste;
  final DateTime createdAt;

  const ProduitVariant({
    required this.id,
    required this.produitId,
    this.tailleId,
    this.couleurId,
    this.sku,
    this.stock = 0,
    this.prixAjuste,
    required this.createdAt,
  });

  // 📥 FROM SUPABASE
  factory ProduitVariant.fromMap(Map<String, dynamic> map) {
    return ProduitVariant(
      id: map['id'] as String,
      produitId: map['produit_id'] as String,
      tailleId: map['taille_id'] as String?,
      couleurId: map['couleur_id'] as String?,
      sku: map['sku'] as String?,
      stock: map['stock'] as int? ?? 0,
      prixAjuste: map['prix_ajuste'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // 📤 TO SUPABASE
  Map<String, dynamic> toMap() {
    return {
      'produit_id': produitId,
      'taille_id': tailleId,
      'couleur_id': couleurId,
      'sku': sku,
      'stock': stock,
      'prix_ajuste': prixAjuste,
    };
  }

  // CopyWith pour modifications
  ProduitVariant copyWith({
    String? id,
    String? produitId,
    String? tailleId,
    String? couleurId,
    String? sku,
    int? stock,
    int? prixAjuste,
    DateTime? createdAt,
  }) {
    return ProduitVariant(
      id: id ?? this.id,
      produitId: produitId ?? this.produitId,
      tailleId: tailleId ?? this.tailleId,
      couleurId: couleurId ?? this.couleurId,
      sku: sku ?? this.sku,
      stock: stock ?? this.stock,
      prixAjuste: prixAjuste ?? this.prixAjuste,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helpers
  bool get estDisponible => stock > 0;
  bool get aTaille => tailleId != null;
  bool get aCouleur => couleurId != null;
  bool get estComplet => (tailleId != null || couleurId != null) && stock > 0;
}
