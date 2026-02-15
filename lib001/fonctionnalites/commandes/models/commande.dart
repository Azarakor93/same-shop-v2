class Commande {
  final String id;
  final String clientId;
  final int total;
  final String statut;
  final String? adresseTexte;
  final DateTime createdAt;

  const Commande({
    required this.id,
    required this.clientId,
    required this.total,
    required this.statut,
    required this.adresseTexte,
    required this.createdAt,
  });

  factory Commande.fromMap(Map<String, dynamic> map) {
    return Commande(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      total: (map['total'] as num).toInt(),
      statut: map['statut'] as String,
      adresseTexte: map['adresse_texte'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

