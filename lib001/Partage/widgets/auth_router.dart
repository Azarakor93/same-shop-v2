import 'package:flutter/material.dart';
import 'package:same_shop/fonctionnalites/navigation/ecran_principal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../fonctionnalites/authentification/views/ecran_connexion.dart';

class AuthRouter extends StatelessWidget {
  const AuthRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;

        // ⏳ En attente de l'état auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 🔐 Utilisateur NON connecté
        if (session == null) {
          return const EcranConnexion();
        }

        // ✅ Utilisateur connecté
        return const EcranPrincipal();
      },
    );
  }
}
