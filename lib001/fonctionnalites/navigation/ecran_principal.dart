import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import '../favoris/ecran_favoris.dart';
import 'package:same_shop/fonctionnalites/home/views/page_accueil.dart';
import '../messagerie/ecran_messages.dart';
import '../vendeur/views/page_ma_boutique.dart';
import '../encheres/ecran_encheres.dart';
import '../home/views/widgets/menu_flottant.dart';
import '../../coeur/languages/gestion_langage.dart';

class EcranPrincipal extends StatefulWidget {
  const EcranPrincipal({super.key});

  @override
  State<EcranPrincipal> createState() => _EcranPrincipalState();
}

class _EcranPrincipalState extends State<EcranPrincipal> {
  int _indexActuel = 0;

  /// 📄 Pages principales — 5 onglets (PDF SAME Shop)
  final List<Widget> _pages = [
    const PageAccueil(),
    const EcranFavoris(),
    const EcranMessages(),
    const PageMaBoutique(),
    const EcranEncheres(),
  ];

  /// 🔤 Labels navigation
  final List<String> _labels = const [
    'Accueil',
    'Favoris',
    'Messages',
    'Ma Boutique',
    'Enchères',
  ];

  /// 🎯 Icônes navigation
  final List<IconData> _icones = [
    Icons.home_outlined,
    Icons.favorite_border,
    Icons.chat_bubble_outline,
    Icons.store_outlined,
    Icons.gavel,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,

      // ================= APPBAR =================
      appBar: AppBar(
        centerTitle: false,
        title: Image.asset(
          theme.brightness == Brightness.dark ? 'assets/icons/Same shop fond noir.png' : 'assets/icons/Same shop fond blanc.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            tooltip: Langage.t(context, 'logout'),
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),

      // ================= CONTENU =================
      body: _pages[_indexActuel],

      // ================= NAVIGATION COURBE =================
      // ================= NAVIGATION COURBE =================
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// 🔼 BARRE COURBE (ICÔNES SEULEMENT)
          CurvedNavigationBar(
            index: _indexActuel,
            height: 50,
            backgroundColor: Colors.transparent,
            color: theme.colorScheme.primary,
            buttonBackgroundColor: theme.colorScheme.primary,
            animationDuration: const Duration(milliseconds: 300),
            onTap: (index) {
              setState(() => _indexActuel = index);
            },
            items: List.generate(_icones.length, (index) {
              final bool actif = index == _indexActuel;

              return Icon(
                _icones[index],
                color: actif
                    ? theme.colorScheme.onSecondary // ✅ même couleur que le texte
                    : Colors.white,
              );
            }),
          ),

          /// 🔽 TEXTES FIXES (NE BOUGENT PAS)
          Container(
            color: theme.colorScheme.primary,
            padding: const EdgeInsets.only(bottom: 5, top: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_labels.length, (index) {
                final bool actif = index == _indexActuel;

                return Text(
                  _labels[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: actif
                        ? theme.colorScheme.onSecondary // ✅ actif
                        : Colors.white,
                  ),
                );
              }),
            ),
          ),
        ],
      ),

      // ================= FAB =================
      // On n'affiche le menu flottant que sur Accueil / Favoris
      floatingActionButton:
          (_indexActuel == 0 || _indexActuel == 1) ? const MenuFlottant() : null,
    );
  }
}
