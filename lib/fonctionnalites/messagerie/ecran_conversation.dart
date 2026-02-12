import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/conversation.dart';
import 'models/message_conversation.dart';
import 'services/service_messagerie_supabase.dart';

class EcranConversation extends StatefulWidget {
  final Conversation conversation;

  const EcranConversation({super.key, required this.conversation});

  @override
  State<EcranConversation> createState() => _EcranConversationState();
}

class _EcranConversationState extends State<EcranConversation> {
  final _service = ServiceMessagerieSupabase();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool _envoiEnCours = false;
  int _dernierNombreMessages = 0;

  @override
  void initState() {
    super.initState();
    _marquerLus();
  }

  Future<void> _marquerLus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await _service.marquerConversationCommeLue(
      conversationId: widget.conversation.id,
      userId: userId,
    );
  }

  Future<void> _envoyer() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _envoiEnCours) return;

    setState(() => _envoiEnCours = true);

    final ok = await _service.envoyerMessage(
      conversationId: widget.conversation.id,
      contenu: text,
    );

    if (!mounted) return;

    if (ok) {
      _controller.clear();
      _defilerEnBas(animation: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'envoyer le message.')),
      );
    }

    if (mounted) {
      setState(() => _envoiEnCours = false);
    }
  }

  void _defilerEnBas({required bool animation}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final position = _scrollController.position.maxScrollExtent;
      if (animation) {
        _scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
        return;
      }

      _scrollController.jumpTo(position);
    });
  }

  void _syncEtatMessages(List<MessageConversation> messages, String? userId) {
    if (messages.length > _dernierNombreMessages) {
      _defilerEnBas(animation: _dernierNombreMessages != 0);
    }

    _dernierNombreMessages = messages.length;

    if (userId != null && messages.any((m) => !m.lu && m.expediteurId != userId)) {
      _marquerLus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.conversation.titreOuRef),
            Text(
              _labelCanal(widget.conversation.canal),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageConversation>>(
              stream: _service.streamMessages(widget.conversation.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Impossible de charger les messages.'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                _syncEtatMessages(messages, userId);

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Aucun message pour le moment.'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _marquerLus(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final m = messages[index];
                      final estMoi = m.expediteurId == userId;
                      return _BulleMessage(message: m, estMoi: estMoi);
                    },
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Écrire un message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _envoiEnCours ? null : _envoyer,
                    icon: _envoiEnCours
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _labelCanal(String canal) {
    switch (canal) {
      case 'commande':
        return 'Commande';
      case 'enchere':
        return 'Enchère';
      case 'fournisseur':
        return 'Fournisseur';
      case 'livraison':
        return 'Livraison';
      default:
        return canal;
    }
  }
}

class _BulleMessage extends StatelessWidget {
  final MessageConversation message;
  final bool estMoi;

  const _BulleMessage({required this.message, required this.estMoi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: estMoi ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: estMoi
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              estMoi ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.contenu,
              style: TextStyle(
                color: estMoi
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _hhmm(message.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: estMoi
                    ? theme.colorScheme.onPrimary.withOpacity(0.8)
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hhmm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
