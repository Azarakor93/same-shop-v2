# Scripts SQL Supabase

> ⚠️ **Aucun de ces fichiers n'est une migration rejouable.** Ne les exécute pas tels quels sur la base de production.
> En phase 1 (voir [`docs/PLAN.md`](../../docs/PLAN.md)), on récupère le schéma réel avec `supabase db pull` dans `supabase/migrations/`. Ces scripts servent alors de référence pour écrire les migrations de correction.

| Fichier | Origine | Contenu | À savoir |
|---|---|---|---|
| `mestables_supabase.sql` | master | Export du visualiseur Supabase (toutes les tables) | Marqué *« not meant to be run »*. Ni RLS ni fonctions. |
| `encheres.sql` | master | Enchères liées à un produit (`produit_id`, `prix_actuel`…), RLS, triggers, fonctions | Version la plus proche du modèle Dart. Commence par des `DROP TABLE`. Le code Dart utilise `enchere_offres` / `utilisateur_id`, ce script `encheres_offres` / `encherisseur_id`. |
| `boost_produit.sql` | codex | `boost_historique`, RPC `appliquer_boost_cumulatif`, `desactiver_boosts_expires` | À comparer avec la base cloud. |
| `commandes_livraisons.sql` | codex | `commandes`, `commande_lignes`, `livraison_packs`, `livraisons` + RLS | À comparer avec la base cloud. |
| `fournisseurs.sql` | codex | `demandes_fournisseurs`, `reponses_fournisseurs` + RLS | À comparer avec la base cloud. |
| `messagerie.sql` | codex | `conversations`, `messages` + RLS | À comparer avec la base cloud. |
| `schema_supabase.sql` | codex | `transactions`, statistiques, `notifications`, `super_admins` + RLS | La policy « Users can create transactions » laisse un client créer ses propres transactions. À retirer en phase 4, quand seul le webhook de paiement écrira dans `transactions`. |
| `workflows_metier.sql` | codex | RPC métier : commandes, livraisons, fournisseurs, messagerie, enchères | `envoyer_message_conversation` est déjà appelée par l'app. Les RPC d'enchères (`placer_offre_enchere`, `cloturer_enchere`…) visent l'**ancien** schéma (`vendeur_id`, `acheteur_id`, `meilleure_offre_id`) : à adapter à `encheres.sql`. |

Les fichiers « codex » viennent de la branche `codex/review-same-shop-v8.0-features-and-database-design` (février 2026). Ils avaient été supprimés de `master`, ou n'y avaient jamais été ramenés. L'`encheres.sql` de cette branche décrivait l'ancien schéma : c'est la version de `master` qui est gardée ici.
