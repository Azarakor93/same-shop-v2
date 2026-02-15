-- ===============================================
-- 📦 SQL SUPABASE - SYSTÈME BOOST CUMULATIF
-- ===============================================

-- 1️⃣ Colonnes boost sur la table produits
ALTER TABLE produits
  ADD COLUMN IF NOT EXISTS boost_actif     BOOLEAN     DEFAULT false,
  ADD COLUMN IF NOT EXISTS boost_expire_at TIMESTAMPTZ DEFAULT NULL;

-- 2️⃣ Table historique des boosts (avec base_calcul pour traçabilité)
CREATE TABLE IF NOT EXISTS boost_historique (
  id             UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  produit_id     UUID        REFERENCES produits(id) ON DELETE CASCADE,
  transaction_id TEXT        NOT NULL,
  duree_jours    INT         NOT NULL,
  montant        INT         NOT NULL,
  base_calcul    TIMESTAMPTZ NOT NULL, -- date de départ utilisée pour le calcul
  expire_at      TIMESTAMPTZ NOT NULL, -- nouvelle date d'expiration après ce boost
  created_at     TIMESTAMPTZ DEFAULT now()
);

-- 3️⃣ Index pour requêtes rapides
CREATE INDEX IF NOT EXISTS idx_boost_historique_produit
  ON boost_historique(produit_id);

CREATE INDEX IF NOT EXISTS idx_produits_boost_expire
  ON produits(boost_expire_at)
  WHERE boost_actif = true;

-- 4️⃣ Fonction qui désactive automatiquement les boosts expirés
--    (à appeler via un cron job Supabase pg_cron ou Edge Function)
CREATE OR REPLACE FUNCTION desactiver_boosts_expires()
RETURNS void AS $$
BEGIN
  UPDATE produits
  SET boost_actif = false
  WHERE boost_actif = true
    AND boost_expire_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- 5️⃣ Activer pg_cron pour désactiver automatiquement (toutes les heures)
-- À exécuter UNE SEULE FOIS dans le SQL Editor de Supabase :
-- SELECT cron.schedule('desactiver-boosts', '0 * * * *', 'SELECT desactiver_boosts_expires()');

-- ===============================================
-- 📊 EXEMPLES DE CALCUL CUMULATIF
-- ===============================================
-- Scénario 1 : Pas de boost actif
--   base_calcul = aujourd'hui (10 jan)
--   + 7 jours = expire le 17 jan ✅

-- Scénario 2 : Boost actif jusqu'au 15 jan, on achète 3 jours
--   base_calcul = 15 jan (date fin actuelle)
--   + 3 jours = expire le 18 jan ✅ (cumul)

-- Scénario 3 : Boost expiré depuis le 5 jan, on achète 1 mois
--   base_calcul = aujourd'hui (10 jan) car 5 jan < aujourd'hui
--   + 30 jours = expire le 9 fév ✅ (repart de zéro)