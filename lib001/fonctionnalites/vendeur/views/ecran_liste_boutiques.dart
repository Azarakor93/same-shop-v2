// ===============================================
// 📋 ÉCRAN LISTE DES BOUTIQUES - AVEC LOCALISATION
// ===============================================
// Affiche toutes les boutiques du vendeur
// avec bouton de localisation Google Maps

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/boutique.dart';
import '../services/service_vendeur_supabase.dart';
import 'ecran_dashboard_vendeur.dart';
import 'ecran_modifier_boutique.dart';
import 'ecran_paiement_abonnement.dart';

class EcranListeBoutiques extends StatefulWidget {
  const EcranListeBoutiques({super.key});

  @override
  State<EcranListeBoutiques> createState() => _EcranListeBoutiquesState();
}

class _EcranListeBoutiquesState extends State<EcranListeBoutiques> {
  final _service = ServiceVendeurSupabase();

  // ===============================================
  // 🔄 RAFRAÎCHIR
  // ===============================================
  Future<void> _rafraichir() async {
    setState(() {});
  }

  // ===============================================
  // ➕ CRÉER UNE NOUVELLE BOUTIQUE
  // ===============================================
  void _creerNouvelleBoutique() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EcranAbonnementPremium(),
      ),
    );
  }

  // ===============================================
  // 🗺️ OUVRIR GOOGLE MAPS
  // ===============================================
  Future<void> _ouvrirGoogleMaps(Boutique boutique) async {
    final lat = boutique.latitude;
    final lon = boutique.longitude;
    final label = Uri.encodeComponent(boutique.nomBoutique);

    // URL Google Maps avec marker
    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lon&query_place_id=$label';

    // URL alternative pour ouvrir l'app Google Maps si installée
    final mapsAppUrl = 'geo:$lat,$lon?q=$lat,$lon($label)';

    try {
      // Essayer d'ouvrir l'app Google Maps en premier
      if (await canLaunchUrl(Uri.parse(mapsAppUrl))) {
        await launchUrl(
          Uri.parse(mapsAppUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Sinon ouvrir dans le navigateur
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'ouvrir la carte: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ===============================================
  // ✏️ MODIFIER UNE BOUTIQUE
  // ===============================================
  Future<void> _modifierBoutique(Boutique boutique) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EcranModifierBoutique(boutique: boutique),
      ),
    );

    // Si la modification a réussi, rafraîchir la liste
    if (result == true) {
      _rafraichir();
    }
  }

  // ===============================================
  // 🗑️ SUPPRIMER UNE BOUTIQUE
  // ===============================================
  Future<void> _supprimerBoutique(Boutique boutique) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la boutique ?'),
        content: Text(
          'Voulez-vous vraiment supprimer "${boutique.nomBoutique}" ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirme == true) {
      try {
        await _service.supprimerBoutique(boutique.id);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Boutique supprimée'),
            backgroundColor: Colors.green,
          ),
        );

        _rafraichir();
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ===============================================
  // ⚙️ AFFICHER MENU OPTIONS
  // ===============================================
  void _afficherMenuOptions(Boutique boutique) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Titre
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  boutique.nomBoutique,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 24),

              // Voir le dashboard
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Voir le dashboard'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EcranDashboardVendeur(boutique: boutique),
                    ),
                  );
                },
              ),

              // 🗺️ Voir sur la carte
              ListTile(
                leading: const Icon(Icons.map, color: Colors.blue),
                title: const Text('Voir sur la carte'),
                onTap: () {
                  Navigator.pop(context);
                  _ouvrirGoogleMaps(boutique);
                },
              ),

              // Modifier
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Modifier les informations'),
                onTap: () {
                  Navigator.pop(context);
                  _modifierBoutique(boutique);
                },
              ),

              // Partager
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Partager'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implémenter le partage
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fonctionnalité bientôt disponible'),
                    ),
                  );
                },
              ),

              // Passer au premium (si gratuit)
              if (!boutique.estPremium)
                ListTile(
                  leading: const Icon(
                    Icons.workspace_premium,
                    color: Colors.amber,
                  ),
                  title: const Text('Passer au Premium'),
                  onTap: () {
                    Navigator.pop(context);
                    _creerNouvelleBoutique();
                  },
                ),

              const Divider(),

              // Supprimer
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _supprimerBoutique(boutique);
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ===============================================
  // 🎨 BUILD UI
  // ===============================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // ===============================================
      // 📱 APP BAR
      // ===============================================
      appBar: AppBar(
        title: const Text('Mes Boutiques'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _rafraichir,
            tooltip: 'Actualiser',
          ),
        ],
      ),

      // ===============================================
      // 📄 BODY
      // ===============================================
      body: FutureBuilder<List<Boutique>>(
        future: _service.listerBoutiques(),
        builder: (context, snapshot) {
          // ⏳ Chargement
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ❌ Erreur
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          // 📋 Liste des boutiques
          final boutiques = snapshot.data ?? [];

          if (boutiques.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _rafraichir,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: boutiques.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final boutique = boutiques[index];
                return _buildBoutiqueCard(boutique, colorScheme);
              },
            ),
          );
        },
      ),

      // ===============================================
      // ➕ BOUTON FLOTTANT - CRÉER BOUTIQUE
      // ===============================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creerNouvelleBoutique,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle boutique'),
      ),
    );
  }

  // ===============================================
  // 🏪 WIDGET - CARTE BOUTIQUE AVEC LOCALISATION
  // ===============================================
  Widget _buildBoutiqueCard(Boutique boutique, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EcranDashboardVendeur(boutique: boutique),
            ),
          );
        },
        onLongPress: () => _afficherMenuOptions(boutique),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Première ligne : Logo + Infos + Menu
              Row(
                children: [
                  // ===============================================
                  // 🖼️ LOGO
                  // ===============================================
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: ClipRRect(
                      // ← Ajouté pour borderRadius
                      borderRadius: BorderRadius.circular(12),
                      child: boutique.logoUrl == null
                          ? Icon(
                              Icons.store,
                              size: 32,
                              color: colorScheme.primary,
                            )
                          : CachedNetworkImage(
                              imageUrl: boutique.logoUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 70, // ← Optimisé 70px
                              memCacheHeight: 70, // ← Optimisé 70px
                              placeholder: (context, url) => Container(
                                color: colorScheme.surface,
                                child: Icon(
                                  Icons.store_outlined,
                                  size: 28,
                                  color: colorScheme.primary.withValues(alpha: 0.5),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: colorScheme.surface,
                                child: Icon(
                                  Icons.store,
                                  size: 32,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // ===============================================
                  // 📝 INFORMATIONS
                  // ===============================================
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom + Badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                boutique.nomBoutique,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (boutique.estPremium)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '👑 PREMIUM',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'GRATUIT',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Adresse
                        if (boutique.adresseComplete.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  boutique.adresseComplete,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 4),

                        // Téléphone
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              boutique.telephone,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ===============================================
                  // ⚙️ BOUTON MENU
                  // ===============================================
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: colorScheme.primary,
                    ),
                    onPressed: () => _afficherMenuOptions(boutique),
                    tooltip: 'Options',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ===============================================
              // 🗺️ BOUTON LOCALISATION (NOUVELLE LIGNE)
              // ===============================================
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue[200]!,
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: () => _ouvrirGoogleMaps(boutique),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '📍 Voir la position sur la carte',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================
  // 📭 WIDGET - ÉTAT VIDE
  // ===============================================
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune boutique',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre première boutique gratuitement',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================
  // ❌ WIDGET - ÉTAT ERREUR
  // ===============================================
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _rafraichir,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
