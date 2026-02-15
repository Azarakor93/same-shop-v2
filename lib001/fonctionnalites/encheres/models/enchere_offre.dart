class EnchereOffre {
  final String id;
  final String enchereId;
  final String acheteurId;
  final int montant;
  final DateTime createdAt;

  const EnchereOffre({
    required this.id,
    required this.enchereId,
    required this.acheteurId,
    required this.montant,
    required this.createdAt,
  });

  factory EnchereOffre.fromMap(Map<String, dynamic> map) {
    return EnchereOffre(
      id: map['id'] as String,
      enchereId: map['enchere_id'] as String,
      acheteurId: map['acheteur_id'] as String,
      montant: (map['montant'] as num).toInt(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

