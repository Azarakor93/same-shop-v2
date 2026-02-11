class ReponseFournisseur {
  final String id;
  final String demandeId;
  final String fournisseurId;
  final String message;
  final int? prixPropose;
  final DateTime createdAt;

  const ReponseFournisseur({
    required this.id,
    required this.demandeId,
    required this.fournisseurId,
    required this.message,
    required this.prixPropose,
    required this.createdAt,
  });

  factory ReponseFournisseur.fromMap(Map<String, dynamic> map) {
    return ReponseFournisseur(
      id: map['id'] as String,
      demandeId: map['demande_id'] as String,
      fournisseurId: map['fournisseur_id'] as String,
      message: map['message'] as String,
      prixPropose: map['prix_propose'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

