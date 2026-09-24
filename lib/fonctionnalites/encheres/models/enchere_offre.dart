class EnchereOffre {
  final String id;
  final String enchereId;
  final String utilisateurId;
  final String nomUtilisateur;
  final double montant;
  final DateTime dateOffre;
  final String statut; // 'active', 'depasse', 'gagnante'

  EnchereOffre({
    required this.id,
    required this.enchereId,
    required this.utilisateurId,
    required this.nomUtilisateur,
    required this.montant,
    required this.dateOffre,
    this.statut = 'active',
  });

  factory EnchereOffre.fromJson(Map<String, dynamic> json) {
    return EnchereOffre(
      id: json['id'] as String,
      enchereId: json['enchere_id'] as String,
      utilisateurId: json['utilisateur_id'] as String,
      nomUtilisateur: json['nom_utilisateur'] as String,
      montant: (json['montant'] as num).toDouble(),
      dateOffre: DateTime.parse(json['date_offre'] as String),
      statut: json['statut'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'enchere_id': enchereId,
      'utilisateur_id': utilisateurId,
      'nom_utilisateur': nomUtilisateur,
      'montant': montant,
      'date_offre': dateOffre.toIso8601String(),
      'statut': statut,
    };
  }
}
