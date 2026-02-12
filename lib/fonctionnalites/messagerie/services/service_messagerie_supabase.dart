import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversation.dart';
import '../models/message_conversation.dart';

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

      final nonLusParConversation = await Future.wait(
        list.map((c) => _compterNonLus(c.id, userId)),
      );

      return List.generate(list.length, (index) {
        final c = list[index];
        return Conversation(
          id: c.id,
          canal: c.canal,
          refId: c.refId,
          participantA: c.participantA,
          participantB: c.participantB,
          titre: c.titre,
          createdAt: c.createdAt,
          updatedAt: c.updatedAt,
          nonLus: nonLusParConversation[index],
        );
      });
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



  Stream<List<MessageConversation>> streamMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map(
          (rows) => rows
              .map((row) => MessageConversation.fromMap(row))
              .toList(growable: false),
        );
  }

  Future<List<MessageConversation>> listerMessages(String conversationId) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((e) => MessageConversation.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> envoyerMessage({
    required String conversationId,
    required String contenu,
  }) async {
    try {
      await _client.rpc('envoyer_message_conversation', params: {
        'p_conversation_id': conversationId,
        'p_contenu': contenu,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> marquerConversationCommeLue({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _client
          .from('messages')
          .update({'lu': true})
          .eq('conversation_id', conversationId)
          .neq('expediteur_id', userId)
          .eq('lu', false);
    } catch (_) {
      // no-op
    }
  }
}
