// ===============================================
// 🆕 VARIANTE TEMPORAIRE (pour formulaire)
// ===============================================
class VarianteTemp {
  final String id;
  String taille;
  String couleur;
  int stock;
  int? prixAjuste;
  bool estValide;

  VarianteTemp({
    required this.id,
    this.taille = '',
    this.couleur = '',
    this.stock = 0,
    this.prixAjuste,
    this.estValide = false,
  });

  VarianteTemp copyWith({
    String? taille,
    String? couleur,
    int? stock,
    int? prixAjuste,
    bool? estValide,
  }) {
    return VarianteTemp(
      id: id,
      taille: taille ?? this.taille,
      couleur: couleur ?? this.couleur,
      stock: stock ?? this.stock,
      prixAjuste: prixAjuste ?? this.prixAjuste,
      estValide: estValide ?? this.estValide,
    );
  }

  bool get estComplet => taille.isNotEmpty && couleur.isNotEmpty && stock > 0;
}
