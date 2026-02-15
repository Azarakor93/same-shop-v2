class MessageConversation {
  final String id;
  final String conversationId;
  final String expediteurId;
  final String contenu;
  final bool lu;
  final DateTime createdAt;

  const MessageConversation({
    required this.id,
    required this.conversationId,
    required this.expediteurId,
    required this.contenu,
    required this.lu,
    required this.createdAt,
  });

  factory MessageConversation.fromMap(Map<String, dynamic> map) {
    return MessageConversation(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      expediteurId: map['expediteur_id'] as String,
      contenu: map['contenu'] as String,
      lu: map['lu'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
