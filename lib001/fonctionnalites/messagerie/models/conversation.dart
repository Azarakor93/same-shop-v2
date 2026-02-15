class Conversation {
  final String id;
  final String canal;
  final String refId;
  final String participantA;
  final String participantB;
  final String? titre;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int nonLus;

  const Conversation({
    required this.id,
    required this.canal,
    required this.refId,
    required this.participantA,
    required this.participantB,
    this.titre,
    required this.createdAt,
    required this.updatedAt,
    this.nonLus = 0,
  });

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as String,
      canal: map['canal'] as String,
      refId: map['ref_id'] as String,
      participantA: map['participant_a'] as String,
      participantB: map['participant_b'] as String,
      titre: map['titre'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      nonLus: map['non_lus'] as int? ?? 0,
    );
  }

  String get titreOuRef => titre ?? refId;
}
