// ===============================================
// 📦 TAB PRODUITS BOUTIQUE
// ===============================================
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/boutique.dart';
import '../../../produits/models/produit.dart';
import '../../../produits/services/service_produit_supabase.dart';
import '../../../produits/views/ecran_ajouter_produit.dart';
import '../../../produits/views/ecran_modifier_produit.dart';
import '../../../produits/views/ecran_details_produit.dart';

class TabProduitsBoutique extends StatefulWidget {
  final Boutique boutique;

  const TabProduitsBoutique({
    super.key,
    required this.boutique,
  });

  @override
  State<TabProduitsBoutique> createState() => _TabProduitsBoutiqueState();
}

class _TabProduitsBoutiqueState extends State<TabProduitsBoutique> {
  final ServiceProduitSupabase _service = ServiceProduitSupabase();
  List<Produit> _produits = [];
  bool _chargement = true;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _chargerProduits();
  }

  Future<void> _chargerProduits() async {
    setState(() => _chargement = true);
    final produits = await _service.recupererProduitsBoutique(widget.boutique.id);
    setState(() {
      _produits = produits;
      _chargement = false;
    });
  }

  List<Produit> get _produitsFiltres {
    if (_recherche.isEmpty) return _produits;
    return _produits
        .where((p) => p.nom.toLowerCase().contains(_recherche.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final produitsFiltres = _produitsFiltres;

    return Column(
      children: [
        // BARRE RECHERCHE + INFOS
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.cardColor,
          child: Column(
            children: [
              // RECHERCHE
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _recherche = value);
                },
              ),
              const SizedBox(height: 12),

              // INFOS QUOTA
              _buildQuotaInfo(theme),
            ],
          ),
        ),

        // LISTE PRODUITS
        Expanded(
          child: _chargement
              ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
              : produitsFiltres.isEmpty
                  ? _buildVide(theme)
                  : RefreshIndicator(
                      onRefresh: _chargerProduits,
                      color: theme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: produitsFiltres.length,
                        itemBuilder: (context, index) {
                          return _CarteProduit(
                            produit: produitsFiltres[index],
                            onTap: () => _ouvrirDetails(produitsFiltres[index]),
                            onModifier: () => _modifierProduit(produitsFiltres[index]),
                            onSupprimer: () => _supprimerProduit(produitsFiltres[index]),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildQuotaInfo(ThemeData theme) {
    // Limites selon type boutique
    int limite = 3; // Gratuit
    if (widget.boutique.typeBoutique == 'payant') {
      limite = 100; // Exemple
    } else if (widget.boutique.typeBoutique == 'entreprise') {
      limite = 9999; // Illimité
    }

    final utilises = _produits.length;
    final pourcentage = limite > 1000 ? 1.0 : utilises / limite;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inventory_2,
            color: theme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  limite > 1000
                      ? 'Produits illimités'
                      : '$utilises / $limite produits',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (limite <= 1000) ...[
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: pourcentage,
                    backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
                    color: theme.primaryColor,
                    minHeight: 4,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVide(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            _recherche.isEmpty ? 'Aucun produit' : 'Aucun résultat',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _recherche.isEmpty
                ? 'Ajoutez votre premier produit'
                : 'Essayez une autre recherche',
            style: theme.textTheme.bodyMedium,
          ),
          if (_recherche.isEmpty) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _ajouterProduit,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un produit'),
            ),
          ],
        ],
      ),
    );
  }

  void _ajouterProduit() async {
    final resultat = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EcranAjouterProduit(
          boutiqueId: widget.boutique.id,
        ),
      ),
    );

    if (resultat == true) {
      _chargerProduits();
    }
  }

  void _ouvrirDetails(Produit produit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EcranDetailsProduit(produitId: produit.id),
      ),
    );
  }

  void _modifierProduit(Produit produit) async {
    final resultat = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EcranModifierProduit(produit: produit),
      ),
    );

    if (resultat == true) {
      _chargerProduits();
    }
  }

  Future<void> _supprimerProduit(Produit produit) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text('Supprimer "${produit.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    final succes = await _service.supprimerProduit(produit.id);

    if (!mounted) return;

    if (succes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Produit supprimé'),
          backgroundColor: Colors.green,
        ),
      );
      _chargerProduits();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erreur lors de la suppression'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ===============================================
// 🎴 CARTE PRODUIT
// ===============================================
class _CarteProduit extends StatelessWidget {
  final Produit produit;
  final VoidCallback onTap;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  const _CarteProduit({
    required this.produit,
    required this.onTap,
    required this.onModifier,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: produit.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: produit.images.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.disabledColor.withValues(alpha: 0.1),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.disabledColor.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.image_not_supported,
                              color: theme.disabledColor,
                            ),
                          ),
                        )
                      : Container(
                          color: theme.disabledColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.image,
                            color: theme.disabledColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // INFOS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produit.nom,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${produit.prix.toStringAsFixed(0)} FCFA',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory,
                          size: 14,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Stock: ${produit.stock}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ACTIONS
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'modifier':
                      onModifier();
                      break;
                    case 'supprimer':
                      onSupprimer();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'modifier',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'supprimer',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
