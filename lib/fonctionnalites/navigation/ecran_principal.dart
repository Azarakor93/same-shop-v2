// ===============================================
// 🏠 ECRAN PRINCIPAL - FILTRES GLOBAUX ✅
// ===============================================
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../produits/views/marketplace/ecran_filtres.dart';
import '../produits/views/marketplace/filtres_facebook_style.dart';
import '../produits/views/marketplace/ecran_marketplace.dart';
import '../livraisons/ecran_livraisons.dart';
import '../messagerie/ecran_messages.dart';
import '../profil/ecran_profil.dart';
import '../home/views/widgets/menu_flottant.dart';
import '../../coeur/languages/gestion_langage.dart';
import '../vendeur/views/page_ma_boutique.dart';

class EcranPrincipal extends StatefulWidget {
  // 🔥 FILTRES GLOBAUX → DANS LA CLASSE StatefulWidget
  static FiltresResult? filtresActuels;

  const EcranPrincipal({super.key});

  @override
  State<EcranPrincipal> createState() => _EcranPrincipalState();
}

class _EcranPrincipalState extends State<EcranPrincipal> {
  int _indexActuel = 0;

  /// 📄 Pages principales
  final List<Widget> _pages = [
    const EcranMarketplace(),
    const PageMaBoutique(),
    //const CreateBoutiqueScreen(),
    const EcranLivraisons(),
    const EcranMessages(),
    const EcranProfil(),
  ];

  final List<String> _labels = const [
    'Marketplace',
    'Boutiques',
    'Livreurs',
    'Messagerie',
    'Profil',
  ];

  final List<IconData> _icones = [
    Icons.storefront_outlined,
    Icons.store_outlined,
    Icons.local_shipping_outlined,
    Icons.chat_bubble_outline,
    Icons.person_outline,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        centerTitle: false,
        title: Image.asset(
          theme.brightness == Brightness.dark ? 'assets/icons/Same shop fond noir.png' : 'assets/icons/Same shop fond blanc.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        actions: [
          // 🔥 FILTRE UNIQUEMENT SUR MARKETPLACE
          if (_indexActuel == 0)
            IconButton(
              tooltip: 'Filtres Marketplace',
              icon: Stack(
                children: [
                  Icon(Icons.filter_list, size: 28),
                  if (EcranPrincipal.filtresActuels != null) // ✅ OK MAINTENANT
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: const Text(
                          '●',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: _ouvrirFiltres,
            )
          else
            IconButton(
              tooltip: Langage.t(context, 'logout'),
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
              },
            ),
        ],
      ),
      body: _pages[_indexActuel],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CurvedNavigationBar(
            index: _indexActuel,
            height: 50,
            backgroundColor: Colors.transparent,
            color: theme.brightness == Brightness.light ? const Color(0xFF00BFA5) : const Color(0xFF1A1F26),
            buttonBackgroundColor: theme.brightness == Brightness.light ? const Color(0xFF00BFA5) : const Color(0xFF1A1F26),
            animationDuration: const Duration(milliseconds: 300),
            onTap: (index) => setState(() => _indexActuel = index),
            items: List.generate(_icones.length, (index) {
              final bool actif = index == _indexActuel;
              return Icon(
                _icones[index],
                size: 26,
                color: actif ? Colors.yellow : Colors.white.withValues(alpha: 0.8),
              );
            }),
          ),
          Container(
            color: theme.brightness == Brightness.light ? const Color(0xFF00BFA5) : const Color(0xFF1A1F26),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
            height: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_labels.length, (index) {
                final bool actif = index == _indexActuel;
                return SizedBox(
                  width: 66,
                  child: Text(
                    _labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: actif ? Colors.yellow : Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: (_indexActuel == 1) ? const MenuFlottant() : null,
    );
  }

  // 🔥 FILTRES STYLE FACEBOOK - MODERNE ✨
  void _ouvrirFiltres() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FiltresFacebookStyle(
        onFiltresApplies: (filtres) {
          // TODO: Appliquer les filtres à la liste de produits

          int nombreFiltres = 0;
          if (filtres['categorie'] != null) nombreFiltres++;
          if (filtres['localisation'] != null) nombreFiltres++;
          if (filtres['etat'] != null) nombreFiltres++;
          if (filtres['prix_min'] > 0 || filtres['prix_max'] < 1000000) nombreFiltres++;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(nombreFiltres > 0
                  ? '✅ $nombreFiltres filtre(s) appliqué(s)'
                  : '📁 Tous les produits'),
              backgroundColor: Colors.green.withValues(alpha: 0.9),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}
