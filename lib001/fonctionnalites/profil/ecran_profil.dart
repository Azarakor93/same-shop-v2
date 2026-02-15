import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../admin/views/ecran_super_admin.dart';
import '../commandes/ecran_commandes.dart';
import '../livraisons/ecran_livraisons.dart';
import '../messagerie/ecran_messages.dart';
import '../panier/ecran_panier.dart';
import '../vendeur/guard_vendeur.dart';

class EcranProfil extends StatelessWidget {
  const EcranProfil({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Connectez-vous pour accéder à votre profil.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _enteteUtilisateur(context, user),
          const SizedBox(height: 16),
          _sectionTitre(context, 'Mes activités'),
          const SizedBox(height: 8),
          _tile(
            context,
            icon: Icons.shopping_cart_outlined,
            title: 'Panier',
            subtitle: 'Voir et valider mes articles',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EcranPanier()),
            ),
          ),
          _tile(
            context,
            icon: Icons.receipt_long_outlined,
            title: 'Commandes',
            subtitle: 'Historique de mes commandes',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EcranCommandes()),
            ),
          ),
          _tile(
            context,
            icon: Icons.chat_bubble_outline,
            title: 'Messages',
            subtitle: 'Conversations commandes / livraisons / fournisseurs',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EcranMessages()),
            ),
          ),
          _tile(
            context,
            icon: Icons.local_shipping_outlined,
            title: 'Livraisons',
            subtitle: 'Demandes et courses en cours',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EcranLivraisons()),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitre(context, 'Espace vendeur / livreur'),
          const SizedBox(height: 8),
          _tile(
            context,
            icon: Icons.storefront_outlined,
            title: 'Ma boutique',
            subtitle: 'Accéder au dashboard vendeur',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GuardVendeur()),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitre(context, 'Administration'),
          const SizedBox(height: 8),
          FutureBuilder<bool>(
            future: _estSuperAdmin(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              final estSuperAdmin = snapshot.data ?? false;
              if (!estSuperAdmin) return const SizedBox.shrink();
              return _tile(
                context,
                icon: Icons.admin_panel_settings_outlined,
                title: 'Dashboard Super Admin',
                subtitle: 'Statistiques globales SAME Shop',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EcranSuperAdmin()),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _enteteUtilisateur(BuildContext context, User user) {
    final theme = Theme.of(context);
    final email = user.email ?? 'Compte téléphone';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(
                (email.isNotEmpty ? email[0] : '?').toUpperCase(),
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${user.id.substring(0, 8)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitre(BuildContext context, String titre) {
    final theme = Theme.of(context);
    return Text(
      titre,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primary.withValues(alpha: 0.10),
          child: Icon(icon, color: cs.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Future<bool> _estSuperAdmin() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final data = await Supabase.instance.client
          .from('super_admins')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      return data != null;
    } catch (_) {
      return false;
    }
  }
}

