-- ===============================================
-- 🚀 SAME SHOP - BOOTSTRAP SQL (ordre recommandé)
-- ===============================================
-- NOTE:
-- Le SQL Editor Supabase n'exécute pas les commandes meta psql (`\i`).
-- Ce fichier sert de plan d'exécution: lancez les scripts suivants dans cet ordre.

-- 1) Socle tables principales
--    lib/sql/mestables_supabase.sql

-- 2) Modules métier
--    lib/sql/boost_produit.sql
--    lib/sql/commandes_livraisons.sql
--    lib/sql/fournisseurs.sql
--    lib/sql/encheres.sql
--    lib/sql/messagerie.sql

-- 3) Workflows RPC
--    lib/sql/workflows_metier.sql

-- 4) Schéma consolidé / compléments
--    lib/sql/schema_supabase.sql

-- Conseils de déploiement:
-- - exécuter en environnement de staging d'abord.
-- - vérifier RLS/policies après exécution.
-- - versionner chaque passage avec un tag git/release.
