class Message {
  final String id;
  final String conversationId;
  final String expediteurId;
  final String contenu;
  final bool lu;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.expediteurId,
    required this.contenu,
    required this.lu,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      expediteurId: map['expediteur_id'] as String,
      contenu: map['contenu'] as String,
      lu: map['lu'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

