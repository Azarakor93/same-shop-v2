import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation.dart';

class ServiceMessagerieSupabase {
  final _client = Supabase.instance.client;

  /// Liste les conversations où l'utilisateur est participant.
  Future<List<Conversation>> listerConversations(String userId) async {
    try {
      final response = await _client
          .from('conversations')
          .select()
          .or('participant_a.eq.$userId,participant_b.eq.$userId')
          .order('updated_at', ascending: false);

      final list = (response as List).map((e) => Conversation.fromMap(e)).toList();

      for (var i = 0; i < list.length; i++) {
        final c = list[i];
        final nonLus = await _compterNonLus(c.id, userId);
        list[i] = Conversation(
          id: c.id,
          canal: c.canal,
          refId: c.refId,
          participantA: c.participantA,
          participantB: c.participantB,
          titre: c.titre,
          createdAt: c.createdAt,
          updatedAt: c.updatedAt,
          nonLus: nonLus,
        );
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  Future<int> _compterNonLus(String conversationId, String userId) async {
    try {
      final res = await _client
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .eq('lu', false)
          .neq('expediteur_id', userId);
      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }
}
