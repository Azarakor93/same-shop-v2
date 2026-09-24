// ===============================================
// 💬 MESSAGES - 4 canaux (PDF SAME Shop)
// ===============================================
// Commande: Client ↔ Vendeur
// Enchère: Client ↔ Entreprise
// Fournisseur: Boutique ↔ Fournisseur
// Livraison: Client ↔ Livreur

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ecran_conversation.dart';
import 'models/conversation.dart';
import 'services/service_messagerie_supabase.dart';

class EcranMessages extends StatefulWidget {
  const EcranMessages({super.key});

  @override
  State<EcranMessages> createState() => _EcranMessagesState();
}

class _EcranMessagesState extends State<EcranMessages> {
  final _service = ServiceMessagerieSupabase();
  final _rechercheController = TextEditingController();

  static const List<String> _canaux = [
    'tous',
    'commande',
    'enchere',
    'fournisseur',
    'livraison',
  ];

  String _canalActif = 'tous';

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

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
                  const Text(
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
        final conversationsFiltrees = _filtrerConversations(conversations);

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _rechercheController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Rechercher une conversation...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _rechercheController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _rechercheController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _canaux.map((canal) {
                  return ChoiceChip(
                    label: Text(_labelCanal(canal)),
                    selected: _canalActif == canal,
                    onSelected: (_) => setState(() => _canalActif = canal),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              if (conversations.isEmpty)
                _EtatVideGlobal()
              else if (conversationsFiltrees.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text('Aucun résultat pour les filtres appliqués.'),
                  ),
                )
              else
                ...List.generate(conversationsFiltrees.length, (index) {
                  final c = conversationsFiltrees[index];
                  return Column(
                    children: [
                      _CarteConversation(conversation: c),
                      if (index < conversationsFiltrees.length - 1)
                        const Divider(height: 1),
                    ],
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  List<Conversation> _filtrerConversations(List<Conversation> conversations) {
    final query = _rechercheController.text.trim().toLowerCase();

    return conversations.where((c) {
      final matchCanal = _canalActif == 'tous' || c.canal == _canalActif;
      if (!matchCanal) return false;

      if (query.isEmpty) return true;

      return c.titreOuRef.toLowerCase().contains(query) ||
          _labelCanal(c.canal).toLowerCase().contains(query);
    }).toList();
  }

  String _labelCanal(String canal) {
    switch (canal) {
      case 'tous':
        return 'Tous';
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

class _EtatVideGlobal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EcranConversation(conversation: conversation),
          ),
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
