# Plan : finir SAME Shop en local

Objectif : une appli complète qui tourne sur un Supabase **local**, avant tout déploiement.
Estimation : **environ 16 à 25 jours de dev**, selon le périmètre retenu en phase 5 (ordre de grandeur).

## État des lieux (septembre 2026)

- **Analyse statique** : `flutter analyze` (Flutter 3.38.10) remontait 2 erreurs, toutes deux dues à la casse du dossier `lib/Partage`. Corrigé en phase 0 ; il reste 2 infos de dépréciation (`Radio.groupValue` / `onChanged` dans `filtres_facebook_style.dart`).
- **Avancé** : marketplace et filtres, fiche et CRUD produits, boutiques et dashboard vendeur, messagerie temps réel, fournisseurs, suivi des livraisons, authentification par email et téléphone.
- **Base de données** : pas de migration rejouable. `lib/sql/mestables_supabase.sql` n'est qu'un export du visualiseur. Détail des scripts dans [`lib/sql/README.md`](../lib/sql/README.md).
- **Écarts entre le code et le schéma**, qui causent des bugs à l'exécution :
  - `favoris` (code) contre `produit_favoris` (schéma) ;
  - `enchere_offres` / `utilisateur_id` (code) contre `encheres_offres` / `encherisseur_id` (SQL), avec deux définitions contradictoires de `encheres` ;
  - `placerEnchere()` passe un `rpc()` non attendu comme valeur dans un `update` ;
  - `increment_vues` et `increment_encherisseurs` sont appelées par l'app mais définies nulle part.
- **Manquant** :
  - panier et commandes client : écrans vides ;
  - onglet commandes de la boutique : TODO ;
  - admin : fichier vide ;
  - paiements et abonnement vendeur : simulés, avec `VOTRE_API_KEY` en dur dans l'app.
- **Divers** : `applicationId` encore en `com.example.same_shop`, aucun test, Riverpod installé mais pas utilisé.

## Phase 0 : remettre le dépôt d'aplomb (½ j)

- [ ] Réunir le code dans `main`, puis faire de `main` la branche par défaut et supprimer `master` et la branche codex (après fusion de la PR)
- [x] Renommer `lib/Partage` en `lib/partage` : `flutter analyze` ne remonte plus d'erreur
- [x] Supprimer `desktop.ini` et les gitlinks `.claude/worktrees/`, déplacer les `.psd` (~29 Mo) dans `design/`
- [x] Récupérer les scripts SQL de la branche codex (RLS, RPC métier)
- [x] Sortir l'URL et la clé Supabase du code (`--dart-define-from-file=config/cloud.json`)
- [x] Documenter la version de Flutter et le lancement dans le README

## Phase 1 : Supabase en local (1 à 2 j)

Outils : Docker Desktop (WSL2) et la CLI Supabase (Scoop ou `npx supabase`).

- [ ] `supabase init`, `supabase link`, puis `supabase db pull` : migration générée depuis le projet cloud (tables, RLS, fonctions, triggers)
- [ ] `supabase start` : Postgres, Auth, Storage, Realtime et Studio en local
- [ ] Migrations de réconciliation :
  - [ ] aligner `favoris` et les enchères sur le code (garder le schéma de `encheres.sql`, le plus proche du modèle Dart)
  - [ ] ajouter les RPC manquantes et celles de `workflows_metier.sql`
  - [ ] créer les buckets Storage `produits` et `boutiques`
  - [ ] boutiques multiples : `vendeurs.id` sert à la fois de clé primaire et d'identifiant du compte, donc une seule boutique par compte. Pourtant l'app propose « Nouvelle boutique » et un abonnement pour en ouvrir d'autres. **Décision à prendre** :
    - garder le multi-boutique : migration avec un `id` généré et une colonne `user_id` propriétaire, puis adapter les requêtes `eq('id', _userId)` et la RLS ;
    - ou s'en tenir à une boutique par compte : retirer ce bouton et ce parcours d'abonnement.
- [ ] Activer la RLS sur **toutes** les tables : la clé anon est publique, c'est la RLS qui protège les données
- [ ] `supabase/seed.sql` : catégories, 3 comptes (client, vendeur, livreur), boutiques, produits, une enchère. `supabase db reset` recrée tout.
- [ ] Auth locale : les emails OTP arrivent dans la boîte locale (http://localhost:54324) ; pour les SMS, numéros de test à code fixe via `[auth.sms.test_otp]` dans `supabase/config.toml`
- [ ] Code de confirmation par email : le modèle « Confirm signup » doit contenir `{{ .Token }}` (en local comme sur le cloud). Si la confirmation est désactivée (réglage par défaut en local), `signUp` ouvre directement une session et l'écran OTP doit être sauté.
- [ ] Créer `config/local.json` : `http://10.0.2.2:54321` depuis l'émulateur Android, l'IP du PC depuis un vrai téléphone

## Phase 2 : stabiliser l'existant (2 à 3 j)

- [ ] `placerEnchere()` : passer par une seule RPC serveur. Adapter `placer_offre_enchere` (écrite pour l'ancien schéma) au schéma de `encheres.sql`.
- [ ] Brancher les TODO :
  - [ ] carte produit → détail (`ecran_produit_card.dart`)
  - [ ] favori → détail
  - [ ] appliquer vraiment les filtres (`ecran_principal.dart`)
  - [ ] charger les catégories des filtres depuis Supabase
  - [ ] actions du dashboard vendeur
- [x] Inscription par téléphone, vérification réelle de l'OTP email, retour à l'accueil après confirmation (relevés par la revue Codex)
- [ ] Écran OTP email : ajouter un bouton « Renvoyer le code » (`renvoyerOtpEmail` existe déjà) et retirer le blocage à 60 s côté app. C'est Supabase qui gère l'expiration.
- [ ] Supprimer les fichiers vides ou morts : `ecran_livreur`, `ecran_vendeur`, `ecran_choix_abonnement`, `ecran_super_admin`, `service_partage`, `ecran_favoris`
- [ ] Tester chaque écran sur la base seedée ; chaque erreur Postgrest signale un écart de schéma à corriger

## Phase 3 : parcours d'achat, le cœur du MVP (4 à 6 j)

- [ ] Panier géré avec Riverpod, sauvegardé en local
- [ ] Commande via `creer_commande_avec_lignes` (transactionnelle), écran « Mes commandes », vrai onglet commandes côté boutique
- [ ] Cycle de vie de la commande (accepter, expédier, livrer, confirmer ou annuler) puis de la livraison (le livreur prend, démarre, termine), avec les RPC de `workflows_metier.sql`

## Phase 4 : paiements en mode test (3 à 5 j)

```text
App ─► Edge Function "initier-paiement" (clé secrète) ─► CinetPay ou PayGate Global
Agrégateur ─► Edge Function "webhook-paiement" ─► vérification + UPDATE transactions ─► Realtime ─► App
```

- [ ] Plus aucune clé API dans l'app
- [ ] En local : `supabase functions serve` et un tunnel (cloudflared ou ngrok) pour recevoir les webhooks
- [ ] Mode simulation côté serveur, activable seulement en local
- [ ] Retirer la policy « Users can create transactions » : seul le webhook écrit dans `transactions`
- [ ] Brancher : boost produit, abonnement vendeur (5 000 FCFA), demandes fournisseurs, commandes

## Phase 5 : modules secondaires, selon les priorités du client (3 à 5 j)

- [ ] Clôture automatique des enchères avec pg_cron
- [ ] TODO fournisseurs, statistiques vendeur, partage (share_plus), notifications in-app
- [ ] Admin : Supabase Studio suffit pour le MVP. OTP vocal hors périmètre.

## Phase 6 : tests et recette locale (2 à 3 j)

- [ ] Tests unitaires (modèles `fromJson`, services), quelques tests widget, tests RLS en SQL (`supabase test db`)
- [ ] Parcours complet sur la base seedée : inscription → boutique → produit → panier → commande → paiement test → livraison → confirmation
- [ ] **Fini en local** quand :
  - `supabase db reset` puis `flutter run` donnent une appli complète ;
  - l'analyse ne remonte aucune erreur et les tests passent ;
  - le parcours complet est validé sur émulateur et sur un vrai téléphone Android.

## Après le local

`supabase db push` vers le cloud, secrets des Edge Functions, `applicationId` définitif (le Play Store refuse `com.example`), signature, icônes, fiche store.
