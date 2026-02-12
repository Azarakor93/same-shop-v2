# SAME Shop v8.0

Marketplace mobile africaine 100% open source, conçue avec **Flutter/Dart** et **Supabase**.

## Vision produit

SAME Shop permet de réunir dans une seule application :

- un catalogue marketplace complet,
- la gestion de boutiques (particulier / entreprise),
- des enchères B2C/B2B,
- un module de recherche de fournisseurs,
- une messagerie multi-canaux,
- un système de livraisons géolocalisées.

## Rôles gérés

- **Client acheteur**
- **Vendeur particulier**
- **Vendeur entreprise**
- **Livreur**
- **Administrateur**

## Stack technique

- **Frontend** : Flutter + Material 3
- **Backend** : Supabase (Auth, Postgres, Realtime, Storage)
- **State management** : Riverpod
- **Notifications** : Firebase Cloud Messaging
- **Cartographie/GPS** : Google Maps Flutter

## Structure SQL du projet

Les scripts SQL Supabase sont centralisés dans `lib/sql/` :

- `mestables_supabase.sql` : socle principal des tables métier
- `boost_produit.sql` : système de boost cumulatif
- `fournisseurs.sql` : demandes/réponses fournisseurs
- `encheres.sql` : module enchères entreprises
- `messagerie.sql` : conversations/messages
- `commandes_livraisons.sql` : commandes client + module livraisons MVP
- `schema_supabase.sql` : schéma consolidé (stats, notifications, transactions, super admins)
- `workflows_metier.sql` : RPC métier prêtes à consommer (commande, livraison, enchère, conversations)
- `bootstrap_same_shop.sql` : plan d'exécution recommandé de tous les scripts SQL

## Démarrage rapide

```bash
flutter pub get
flutter run
```

## Notes

- Le projet est bilingue (FR/EN) et pensé pour thème clair/sombre.
- Les règles de monétisation (boost, abonnement, packs livraison, frais) sont implémentées côté données dans les scripts SQL.

## Évolution livrée dans ce sprint

- Ajout d'un script SQL dédié `commandes_livraisons.sql` pour le MVP commandes/livraisons.
- Renforcement du module boost avec la RPC `appliquer_boost_cumulatif(...)` (cumul automatique, historique, sécurité `SECURITY DEFINER` + `search_path`, cohérence `transaction_id` en UUID).
- Durcissement des scripts RLS commandes/livraisons avec `DROP POLICY IF EXISTS` pour permettre des ré-exécutions sans erreur.
- Ajout des RPC métier critiques (`accepter_commande_vendeur`, `prendre_livraison`, `placer_offre_enchere`, `cloturer_enchere`, `cloturer_encheres_expirees_vendeur`) avec création automatique des conversations liées.
- Fiabilisation du module enchères: policy de lecture corrigée (suppression du `OR TRUE`) et policies rendues idempotentes.
- Sécurisation des RPC via `REVOKE/GRANT EXECUTE` (exécution réservée au rôle `authenticated`).
- Ajout d'une RPC `creer_commande_avec_lignes(...)` pour créer une commande complète (en-tête + lignes) en une seule transaction SQL.
- Ajout d'un fichier `bootstrap_same_shop.sql` pour standardiser l'ordre d'exécution des scripts en déploiement.
- Ajout des RPC `annuler_commande_client(...)` et `terminer_livraison_livreur(...)` pour couvrir la fin de cycle commande/livraison.
- Ajout de contraintes SQL idempotentes sur commandes/lignes/livraisons (totaux, quantités, prix, notes, crédits packs).
- Durcissement du module fournisseurs : policies RLS rendues idempotentes (`DROP POLICY IF EXISTS`) et contraintes SQL sur `quantite`/`budget` positifs.
- Ajout des RPC fournisseurs `creer_demande_fournisseur(...)` et `repondre_demande_fournisseur(...)` avec validations métier et ouverture de conversation automatique.
- Ajout de la RPC `cloturer_demande_fournisseur(...)` pour permettre au demandeur de fermer explicitement une demande fournisseur active.
- Ajout de la RPC `desactiver_demandes_fournisseur_expirees()` pour désactiver en lot les demandes expirées du vendeur connecté.
- Ajout de la RPC `demarrer_livraison_livreur(...)` pour verrouiller la transition `acceptee -> en_cours` côté livreur assigné.
- Ajout de la RPC `annuler_livraison_client(...)` pour autoriser une annulation client uniquement dans les statuts compatibles (`en_attente`, `acceptee`).
- Ajout de la RPC `expedier_commande_vendeur(...)` pour encadrer la transition de commande `en_preparation -> expediee` côté vendeur concerné.
- Ajout de la RPC `confirmer_livraison_commande_client(...)` pour permettre au client de confirmer la réception (`expediee -> livree`).
- Ajout de la RPC `envoyer_message_conversation(...)` pour envoyer un message de manière sécurisée (participant requis) et rafraîchir `conversations.updated_at`.
- Frontend messagerie amélioré: recherche locale + filtres par canal (Tous/Commande/Enchère/Fournisseur/Livraison) dans la liste des conversations.
- Écran conversation amélioré en temps réel (stream Supabase), auto-scroll sur nouveaux messages et marquage automatique des messages lus.
- Navigation principale alignée sur la vision produit: `Marketplace / Boutiques / Livreurs / Messagerie / Profil` avec les écrans correspondants.
- Écran Profil enrichi: préférences langue/thème (local + Supabase), informations compte, sections sécurité/notifications/paiements et action de déconnexion.
- Onglet Livraisons transformé en tableau de suivi: récupération Supabase, filtres par statut, badges visuels et détails départ/arrivée/prix/commission.

- Menu flottant: implémentation réelle de l'action `Nouvelle annonce` avec un écran de création (`EcranCreerAnnonce`) et insertion Supabase via `SupabaseAnnonceService.creerAnnonce(...)`.

- Annonces: filtrage côté service sur fenêtre de validité (`date_debut`/`date_fin`) et création enrichie (type de lien guidé, validation conditionnelle de la valeur de lien, aperçu image URL et durée en jours optionnelle).
