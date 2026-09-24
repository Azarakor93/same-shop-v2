import 'package:flutter/material.dart';
import 'package:same_shop/fonctionnalites/vendeur/views/ecran_creation_boutique.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../coeur/languages/gestion_langage.dart';
import '../../../authentification/views/ecran_connexion.dart';
import '../ecran_creer_annonce.dart';

enum RoleUtilisateur { visiteur, acheteur, vendeur, livreur }

class MenuFlottant extends StatefulWidget {
  const MenuFlottant({super.key});

  @override
  State<MenuFlottant> createState() => _MenuFlottantState();
}

class _MenuFlottantState extends State<MenuFlottant> with SingleTickerProviderStateMixin {
  bool _ouvert = false;

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  static const double _largeurBouton = 180;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final user = Supabase.instance.client.auth.currentUser;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        /// 🎛️ MENU ACTIONS
        if (_ouvert)
          FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: _contenuMenu(context, cs, user),
            ),
          ),

        /// ➕ / ✖️ BOUTON PRINCIPAL
        Container(
          //padding: EdgeInsets.only(top: 16),
          margin: EdgeInsets.only(top: 16),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light ? Color(0xFF00BFA5) : Color.fromARGB(255, 118, 59, 0).withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() => _ouvert = !_ouvert);
                _ouvert ? _controller.forward() : _controller.reverse();
              },
              borderRadius: BorderRadius.circular(28),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _ouvert ? Icons.close : Icons.add,
                  key: ValueKey(_ouvert),
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),

        ///
      ],
    );
  }

  /// ==========================
  /// 🧠 CONTENU SELON RÔLE
  /// ==========================
  Widget _contenuMenu(
    BuildContext context,
    ColorScheme cs,
    User? user,
  ) {
    if (user == null) {
      return _menuVisiteur(context, cs);
    }
    return _menuAcheteur(context, cs);
  }

  /// 👤 VISITEUR (NON CONNECTÉ)
  Widget _menuVisiteur(BuildContext context, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _action(
          icon: Icons.login,
          label: Langage.t(context, 'sign_in'),
          cs: cs,
          onTap: () => _allerConnexion(context),
        ),
      ],
    );
  }

  /// 🛒 ACHETEUR CONNECTÉ
  Widget _menuAcheteur(BuildContext context, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _action(
          icon: Icons.storefront,
          label: Langage.t(context, 'create_shop'),
          cs: cs,
          onTap: () => _allerCreerBoutiqueVendeur(context),
        ),
        const SizedBox(height: 8),
        _action(
          icon: Icons.add_business,
          label: Langage.t(context, 'nouvelle_annonce'),
          cs: cs,
          onTap: () => _allerCreerAnnonce(context),
        ),
      ],
    );
  }

  /// ==========================
  /// 🔘 ACTION BOUTON
  /// ==========================
  Widget _action({
    required IconData icon,
    required String label,
    required ColorScheme cs,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: _largeurBouton,
      child: FloatingActionButton.extended(
        heroTag: label,
        elevation: 6,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        icon: Icon(icon),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onPressed: () {
          onTap();
          setState(() => _ouvert = false);
          _controller.reverse();
        },
      ),
    );
  }

  /// ==========================
  /// 🚦 NAVIGATIONS
  /// ==========================
  void _allerConnexion(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EcranConnexion(),
      ),
    );
  }

  void _allerCreerBoutiqueVendeur(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EcranCreationBoutique(),
      ),
    );
  }

  void _allerCreerAnnonce(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EcranCreerAnnonce(),
      ),
    );
  }
}
