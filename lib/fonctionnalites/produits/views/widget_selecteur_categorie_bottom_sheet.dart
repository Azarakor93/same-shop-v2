// ===============================================
// 🎯 WIDGET SÉLECTEUR CATÉGORIE - BOTTOM SHEET
// ===============================================
// Widget indépendant pour sélectionner une catégorie
// S'ouvre en bottom sheet avec navigation hiérarchique

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SelecteurCategorieBottomSheet extends StatefulWidget {
  final String? categorieActuelleId;
  final Function(String categorieId, String nomComplet) onCategorieSelectionnee;

  const SelecteurCategorieBottomSheet({
    super.key,
    this.categorieActuelleId,
    required this.onCategorieSelectionnee,
  });

  @override
  State<SelecteurCategorieBottomSheet> createState() =>
      _SelecteurCategorieBottomSheetState();
}

class _SelecteurCategorieBottomSheetState
    extends State<SelecteurCategorieBottomSheet> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _categoriesActuelles = [];
  final List<Map<String, dynamic>> _historique = [];
  String _titre = 'Choisir une catégorie';
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerCategoriesPrincipales();
  }

  Future<void> _chargerCategoriesPrincipales() async {
    setState(() => _chargement = true);
    try {
      final data = await _supabase
          .from('categories')
          .select('id, code, nom, icone, parent_id')
          .isFilter('parent_id', null)
          .eq('actif', true)
          .order('nom');

      setState(() {
        _categoriesActuelles = List<Map<String, dynamic>>.from(data);
        _titre = 'Choisir une catégorie';
        _chargement = false;
      });
    } catch (e) {
      setState(() => _chargement = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _chargerSousCategories(Map<String, dynamic> categorie) async {
    try {
      final data = await _supabase
          .from('categories')
          .select('id, code, nom, icone, parent_id')
          .eq('parent_id', categorie['id'])
          .eq('actif', true)
          .order('nom');

      final sousCategories = List<Map<String, dynamic>>.from(data);

      // Si pas de sous-catégories, sélectionner directement
      if (sousCategories.isEmpty) {
        _selectionnerCategorie(categorie);
        return;
      }

      // Sinon, naviguer vers les sous-catégories
      setState(() {
        _historique.add({
          'categories': List<Map<String, dynamic>>.from(_categoriesActuelles),
          'titre': _titre,
        });
        _categoriesActuelles = sousCategories;
        _titre = categorie['nom'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  void _retourArriere() {
    if (_historique.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final precedent = _historique.removeLast();
    setState(() {
      _categoriesActuelles = precedent['categories'];
      _titre = precedent['titre'];
    });
  }

  Future<String> _recupererCheminComplet(String categorieId) async {
    try {
      final categorie = await _supabase
          .from('categories')
          .select('id, nom, parent_id')
          .eq('id', categorieId)
          .single();

      String chemin = categorie['nom'];

      if (categorie['parent_id'] != null) {
        final parent = await _supabase
            .from('categories')
            .select('id, nom, parent_id')
            .eq('id', categorie['parent_id'])
            .single();

        chemin = '${parent['nom']} > $chemin';

        if (parent['parent_id'] != null) {
          final grandParent = await _supabase
              .from('categories')
              .select('nom')
              .eq('id', parent['parent_id'])
              .single();

          chemin = '${grandParent['nom']} > $chemin';
        }
      }

      return chemin;
    } catch (e) {
      return '';
    }
  }

  void _selectionnerCategorie(Map<String, dynamic> categorie) async {
    final cheminComplet = await _recupererCheminComplet(categorie['id']);
    widget.onCategorieSelectionnee(categorie['id'], cheminComplet);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
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

          // Header avec bouton retour
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (_historique.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _retourArriere,
                  ),
                Expanded(
                  child: Text(
                    _titre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign:
                        _historique.isEmpty ? TextAlign.center : TextAlign.left,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(),

          // Liste des catégories
          Expanded(
            child: _chargement
                ? const Center(child: CircularProgressIndicator())
                : _categoriesActuelles.isEmpty
                    ? const Center(
                        child: Text('Aucune catégorie disponible'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _categoriesActuelles.length,
                        itemBuilder: (context, index) {
                          final categorie = _categoriesActuelles[index];
                          return _buildCategorieItem(categorie);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorieItem(Map<String, dynamic> categorie) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => _chargerSousCategories(categorie),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              _getIconeEmoji(categorie['icone'] ?? ''),
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(
          categorie['nom'] ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  // Mapping icônes Material Design vers Emoji
  String _getIconeEmoji(String iconeCode) {
    final Map<String, String> mapping = {
      // Électronique
      'smartphone': '📱',
      'laptop': '💻',
      'computer': '🖥️',
      'tablet': '📱',
      'watch': '⌚',
      'headphones': '🎧',
      'camera': '📷',
      'photo_camera': '📷',
      'videocam': '📹',
      'tv': '📺',
      'radio': '📻',
      'speaker': '🔊',
      'mic': '🎤',
      'cable': '🔌',
      'battery_charging_full': '🔋',
      'power': '⚡',
      'solar_power': '☀️',
      'gps_fixed': '📍',
      'wifi': '📶',

      // Mode & Vêtements
      'checkroom': '👔',
      'woman': '👗',
      'man': '🧔',
      'child_care': '👶',
      'hiking': '👟',
      'diamond': '💎',
      'watch_later': '⌚',

      // Maison
      'home': '🏠',
      'bed': '🛏️',
      'bathtub': '🛁',
      'crib': '🍼',
      'chair': '🪑',
      'table_restaurant': '🪑',
      'kitchen': '🍽️',
      'restaurant': '🍽️',
      'countertops': '🏠',
      'light': '💡',
      'lightbulb': '💡',

      // Beauté & Santé
      'face': '💄',
      'brush': '🖌️',
      'content_cut': '✂️',
      'spa': '💆',
      'self_improvement': '🧘',
      'local_florist': '🌸',
      'health_and_safety': '🏥',
      'medical_services': '⚕️',
      'local_pharmacy': '💊',
      'medication': '💊',
      'clean_hands': '🧼',

      // Sport
      'sports_soccer': '⚽',
      'sports_basketball': '🏀',
      'sports_tennis': '🎾',
      'sports_volleyball': '🏐',
      'fitness_center': '💪',
      'pool': '🏊',
      'directions_bike': '🚴',
      'directions_run': '🏃',
      // ignore: equal_keys_in_map
      'hiking': '🥾',
      'terrain': '⛰️',
      'surfing': '🏄',

      // Animaux
      'pets': '🐕',
      'flutter_dash': '🐦',
      'emoji_nature': '🦎',

      // Alimentation
      // ignore: equal_keys_in_map
      'restaurant': '🍽️',
      'local_dining': '🍴',
      'fastfood': '🍔',
      'local_pizza': '🍕',
      'takeout_dining': '🥡',
      'lunch_dining': '🍱',
      'local_drink': '🥤',
      'coffee': '☕',
      'local_cafe': '☕',
      'rice_bowl': '🍚',
      'soup_kitchen': '🍲',
      'bakery_dining': '🍰',
      'icecream': '🍦',
      'cake': '🎂',
      'egg': '🥚',
      'oil_barrel': '🛢️',

      // Jardin
      'grass': '🌱',
      'yard': '🌳',
      'agriculture': '🌾',
      'eco': '♻️',
      'park': '🌳',
      'nature': '🌿',
      'forest': '🌲',
      'water': '💧',
      'water_drop': '💧',

      // Auto & Moto
      'directions_car': '🚗',
      'two_wheeler': '🏍️',
      'electric_car': '⚡',
      'local_gas_station': '⛽',
      'tire_repair': '🛞',
      'build': '🔧',
      'settings': '⚙️',
      // ignore: equal_keys_in_map
      'oil_barrel': '🛢️',
      'car_repair': '🔧',

      // Services
      'handyman': '🛠️',
      'construction': '🏗️',
      'home_repair_service': '🔨',
      'plumbing': '🚰',
      'cleaning_services': '🧹',
      'local_laundry_service': '👕',
      'local_shipping': '🚚',
      'delivery_dining': '🛵',
      'school': '🎓',
      // ignore: equal_keys_in_map
      'fitness_center': '🏋️',

      // Culture
      'palette': '🎨',
      'music_note': '🎵',
      'menu_book': '📚',
      'collections_bookmark': '📖',
      'auto_stories': '📕',
      'library_books': '📚',
      'piano': '🎹',
      'guitar': '🎸',
      'drum': '🥁',

      // Gaming
      'sports_esports': '🎮',
      'stadia_controller': '🎮',
      'gamepad': '🎮',
      'videogame_asset': '🕹️',

      // Général
      'shopping_cart': '🛒',
      'store': '🏪',
      'local_mall': '🛍️',
      'shopping_bag': '🛍️',
      'card_giftcard': '🎁',
      'loyalty': '🎫',
      'star': '⭐',
      'favorite': '❤️',
      'thumb_up': '👍',
      'verified': '✅',
      'new_releases': '🆕',
      'local_offer': '🏷️',
      'sell': '💰',
      'attach_money': '💵',
      'euro': '💶',
      'currency_exchange': '💱',
      'credit_card': '💳',
      'account_balance': '🏦',
      'savings': '🐖',
      'more_horiz': '⋯',
      'apps': '📱',
      'widgets': '🧩',
      'extension': '🧩',
      'code': '💻',
      'data_object': '📊',
      'storage': '💾',
      'cloud': '☁️',
      'print': '🖨️',
      'folder': '📁',
      'description': '📄',
      'article': '📃',
      'note': '📝',
      'edit': '✏️',
      'create': '✍️',
      'draw': '🖌️',
      'colorize': '🎨',
      'format_paint': '🖌️',
      'image': '🖼️',
      'photo': '📸',
      'collections': '🖼️',
      'photo_library': '📷',
      'movie': '🎬',
      'video_library': '📹',
      'theaters': '🎭',
      'celebration': '🎉',
      'party_mode': '🎊',
      // ignore: equal_keys_in_map
      'cake': '🎂',
      // ignore: equal_keys_in_map
      'card_giftcard': '🎁',
      'redeem': '🎁',
    };

    return mapping[iconeCode] ?? '📦';
  }
}

// ===============================================
// 📱 FONCTION HELPER POUR AFFICHER LE BOTTOM SHEET
// ===============================================

Future<Map<String, String>?> afficherSelecteurCategorie(
  BuildContext context, {
  String? categorieActuelleId,
}) async {
  Map<String, String>? result;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SelecteurCategorieBottomSheet(
      categorieActuelleId: categorieActuelleId,
      onCategorieSelectionnee: (id, nomComplet) {
        result = {'id': id, 'nomComplet': nomComplet};
      },
    ),
  );

  return result;
}
