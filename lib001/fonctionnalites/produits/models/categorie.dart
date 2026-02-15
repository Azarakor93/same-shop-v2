// ===============================================
// 📂 MODÈLE CATÉGORIE
// ===============================================
// Gestion des catégories hiérarchiques

class Categorie {
  final String id;
  final String code;
  final String nom;
  final String icone;
  final String? parentId;
  final bool actif;
  final DateTime createdAt;

  const Categorie({
    required this.id,
    required this.code,
    required this.nom,
    required this.icone,
    this.parentId,
    this.actif = true,
    required this.createdAt,
  });

  // Désérialisation
  factory Categorie.fromMap(Map<String, dynamic> map) {
    return Categorie(
      id: map['id'] as String,
      code: map['code'] as String,
      nom: map['nom'] as String,
      icone: map['icone'] as String,
      parentId: map['parent_id'] as String?,
      actif: map['actif'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Sérialisation
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'nom': nom,
      'icone': icone,
      'parent_id': parentId,
      'actif': actif,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helpers
  bool get estPrincipale => parentId == null;
  bool get estSousCategorie => parentId != null;
}
