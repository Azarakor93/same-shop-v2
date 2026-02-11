// ===============================================
// 💬 MESSAGES - 4 canaux (PDF SAME Shop)
// ===============================================
// Commande: Client ↔ Vendeur
// Enchère: Client ↔ Entreprise
// Fournisseur: Boutique ↔ Fournisseur
// Livraison: Client ↔ Livreur

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/service_messagerie_supabase.dart';
import 'models/conversation.dart';

class EcranMessages extends StatefulWidget {
  const EcranMessages({super.key});

  @override
  State<EcranMessages> createState() => _EcranMessagesState();
}

class _EcranMessagesState extends State<EcranMessages> {
  final _service = ServiceMessagerieSupabase();

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return const Center(child: Text('Connectez-vous pour voir vos messages.'));
    }

    return FutureBuilder<List<Conversation>>(
      future: _service.listerConversations(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Impossible de charger les conversations.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final conversations = snapshot.data ?? [];

        if (conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucune conversation',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vos échanges commandes, fournisseurs,\nlivraisons et enchères apparaîtront ici.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = conversations[index];
              return _CarteConversation(conversation: c);
            },
          ),
        );
      },
    );
  }
}

class _CarteConversation extends StatelessWidget {
  final Conversation conversation;

  const _CarteConversation({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canalLabel = _labelCanal(conversation.canal);
    final canalIcon = _iconCanal(conversation.canal);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(canalIcon, color: theme.colorScheme.primary, size: 22),
      ),
      title: Text(
        conversation.titreOuRef,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        canalLabel,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: conversation.nonLus > 0
          ? CircleAvatar(
              radius: 12,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                '${conversation.nonLus}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : const Icon(Icons.chevron_right, size: 20),
      onTap: () {
        // TODO: ouvrir écran conversation / chat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conversation: ${conversation.id}')),
        );
      },
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

  IconData _iconCanal(String canal) {
    switch (canal) {
      case 'commande':
        return Icons.shopping_bag_outlined;
      case 'enchere':
        return Icons.gavel;
      case 'fournisseur':
        return Icons.search;
      case 'livraison':
        return Icons.local_shipping_outlined;
      default:
        return Icons.chat;
    }
  }
}
