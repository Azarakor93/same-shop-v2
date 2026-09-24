// ===============================================
// 📦 MODÈLE PRODUIT
// ===============================================
// Représente un produit avec toutes ses propriétés

class Produit {
  final String id;
  final String vendeurId;
  final String categorieId;
  final String nom;
  final String? description;
  final int prix;
  final double note;
  final int? stockGlobal;
  final bool actif;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool estTop;
  final int ordreTop;
  final EtatProduit etatProduit;
  final bool livraisonDisponible;
  final int nombreVues;
  final int nombreVentes;
  final double? poids;
  final String? marque;

  const Produit({
    required this.id,
    required this.vendeurId,
    required this.categorieId,
    required this.nom,
    this.description,
    required this.prix,
    this.note = 0.0,
    this.stockGlobal,
    this.actif = true,
    required this.createdAt,
    this.updatedAt,
    this.estTop = false,
    this.ordreTop = 0,
    this.etatProduit = EtatProduit.neuf,
    this.livraisonDisponible = false,
    this.nombreVues = 0,
    this.nombreVentes = 0,
    this.poids,
    this.marque,
  });

  // ===============================================
  // 📥 DÉSÉRIALISATION (Supabase → Dart)
  // ===============================================
  factory Produit.fromMap(Map<String, dynamic> map) {
    return Produit(
      id: map['id'] as String,
      vendeurId: map['vendeur_id'] as String,
      categorieId: map['categorie_id'] as String,
      nom: map['nom'] as String,
      description: map['description'] as String?,
      prix: map['prix'] as int,
      note: (map['note'] as num?)?.toDouble() ?? 0.0,
      stockGlobal: map['stock_global'] as int?,
      actif: map['actif'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      estTop: map['est_top'] as bool? ?? false,
      ordreTop: map['ordre_top'] as int? ?? 0,
      etatProduit: _parseEtatProduit(map['etat_produit']),
      livraisonDisponible: map['livraison_disponible'] as bool? ?? false,
      nombreVues: map['nombre_vues'] as int? ?? 0,
      nombreVentes: map['nombre_ventes'] as int? ?? 0,
      poids: (map['poids'] as num?)?.toDouble(),
      marque: map['marque'] as String?,
    );
  }

  // ===============================================
  // 📤 SÉRIALISATION (Dart → Supabase)
  // ===============================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vendeur_id': vendeurId,
      'categorie_id': categorieId,
      'nom': nom,
      'description': description,
      'prix': prix,
      'note': note,
      'stock_global': stockGlobal,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'est_top': estTop,
      'ordre_top': ordreTop,
      'etat_produit': etatProduit.value,
      'livraison_disponible': livraisonDisponible,
      'nombre_vues': nombreVues,
      'nombre_ventes': nombreVentes,
      'poids': poids,
      'marque': marque,
    };
  }

  // ===============================================
  // 🔄 COPY WITH (pour modifications)
  // ===============================================
  Produit copyWith({
    String? id,
    String? vendeurId,
    String? categorieId,
    String? nom,
    String? description,
    int? prix,
    double? note,
    int? stockGlobal,
    bool? actif,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? estTop,
    int? ordreTop,
    EtatProduit? etatProduit,
    bool? livraisonDisponible,
    int? nombreVues,
    int? nombreVentes,
    double? poids,
    String? marque,
  }) {
    return Produit(
      id: id ?? this.id,
      vendeurId: vendeurId ?? this.vendeurId,
      categorieId: categorieId ?? this.categorieId,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      prix: prix ?? this.prix,
      note: note ?? this.note,
      stockGlobal: stockGlobal ?? this.stockGlobal,
      actif: actif ?? this.actif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estTop: estTop ?? this.estTop,
      ordreTop: ordreTop ?? this.ordreTop,
      etatProduit: etatProduit ?? this.etatProduit,
      livraisonDisponible: livraisonDisponible ?? this.livraisonDisponible,
      nombreVues: nombreVues ?? this.nombreVues,
      nombreVentes: nombreVentes ?? this.nombreVentes,
      poids: poids ?? this.poids,
      marque: marque ?? this.marque,
    );
  }

  // ===============================================
  // 🔍 HELPER - Parse état produit
  // ===============================================
  static EtatProduit _parseEtatProduit(dynamic value) {
    if (value == null) return EtatProduit.neuf;
    if (value == 'occasion') return EtatProduit.occasion;
    return EtatProduit.neuf;
  }

  // ===============================================
  // ✅ VÉRIFICATIONS UTILES
  // ===============================================
  bool get estDisponible => actif && (stockGlobal == null || stockGlobal! > 0);
  bool get estEnRupture => stockGlobal != null && stockGlobal! <= 0;
  bool get estNeuf => etatProduit == EtatProduit.neuf;
  bool get aDesAvis => note > 0;

  String get prixFormate => '${prix.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      )} FCFA';

  String get poidsFormate {
    if (poids == null) return '';
    if (poids! < 1) return '${(poids! * 1000).toInt()} g';
    return '${poids!.toStringAsFixed(1)} kg';
  }
}

// ===============================================
// 🎯 ENUM ÉTAT PRODUIT
// ===============================================
enum EtatProduit {
  neuf('neuf'),
  occasion('occasion');

  final String value;
  const EtatProduit(this.value);

  String get label {
    switch (this) {
      case EtatProduit.neuf:
        return 'Neuf';
      case EtatProduit.occasion:
        return 'Occasion';
    }
  }
}

// ===============================================
// 📸 MODÈLE IMAGE PRODUIT
// ===============================================
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produit_id': produitId,
      'url': url,
      'ordre': ordre,
    };
  }
}

// ===============================================
// 📏 MODÈLE TAILLE PRODUIT
// ===============================================
class ProduitTaille {
  final String id;
  final String produitId;
  final String valeur;
  final int stock;

  const ProduitTaille({
    required this.id,
    required this.produitId,
    required this.valeur,
    this.stock = 0,
  });

  factory ProduitTaille.fromMap(Map<String, dynamic> map) {
    return ProduitTaille(
      id: map['id'] as String,
      produitId: map['produit_id'] as String,
      valeur: map['valeur'] as String,
      stock: map['stock'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produit_id': produitId,
      'valeur': valeur,
      'stock': stock,
    };
  }

  bool get estDisponible => stock > 0;
}

// ===============================================
// 🎨 MODÈLE COULEUR PRODUIT
// ===============================================
class ProduitCouleur {
  final String id;
  final String produitId;
  final String nom;
  final String? codeHex;
  final int stock;
  final DateTime createdAt;

  const ProduitCouleur({
    required this.id,
    required this.produitId,
    required this.nom,
    this.codeHex,
    this.stock = 0,
    required this.createdAt,
  });

  factory ProduitCouleur.fromMap(Map<String, dynamic> map) {
    return ProduitCouleur(
      id: map['id'] as String,
      produitId: map['produit_id'] as String,
      nom: map['nom'] as String,
      codeHex: map['code_hex'] as String?,
      stock: map['stock'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produit_id': produitId,
      'nom': nom,
      'code_hex': codeHex,
      'stock': stock,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get estDisponible => stock > 0;
}
