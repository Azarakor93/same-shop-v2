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
  transaction_id UUID        REFERENCES transactions(id) ON DELETE SET NULL,
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



-- 4️⃣ RPC: appliquer un boost cumulatif à un produit
-- Utilisation: SELECT appliquer_boost_cumulatif('<produit_uuid>', 3, 500, '<transaction_uuid>');
CREATE OR REPLACE FUNCTION appliquer_boost_cumulatif(
  p_produit_id UUID,
  p_duree_jours INT,
  p_montant INT,
  p_transaction_id UUID
)
RETURNS TABLE (base_calcul TIMESTAMPTZ, nouvelle_expiration TIMESTAMPTZ)
AS $$
DECLARE
  v_boost_expire_at TIMESTAMPTZ;
  v_base_calcul TIMESTAMPTZ;
  v_nouvelle_expiration TIMESTAMPTZ;
  v_vendeur_id UUID;
BEGIN
  IF p_duree_jours IS NULL OR p_duree_jours <= 0 THEN
    RAISE EXCEPTION 'Durée de boost invalide';
  END IF;

  IF p_montant IS NULL OR p_montant <= 0 THEN
    RAISE EXCEPTION 'Montant invalide';
  END IF;

  SELECT vendeur_id, boost_expire_at
  INTO v_vendeur_id, v_boost_expire_at
  FROM produits
  WHERE id = p_produit_id
  FOR UPDATE;

  IF v_vendeur_id IS NULL THEN
    RAISE EXCEPTION 'Produit introuvable';
  END IF;

  IF v_vendeur_id <> auth.uid() THEN
    RAISE EXCEPTION 'Action non autorisée: produit hors de votre boutique';
  END IF;

  v_base_calcul := CASE
    WHEN v_boost_expire_at IS NOT NULL AND v_boost_expire_at > NOW() THEN v_boost_expire_at
    ELSE NOW()
  END;

  v_nouvelle_expiration := v_base_calcul + make_interval(days => p_duree_jours);

  UPDATE produits
  SET
    boost_actif = TRUE,
    boost_expire_at = v_nouvelle_expiration,
    est_booste = TRUE,
    date_expiration_boost = v_nouvelle_expiration
  WHERE id = p_produit_id;

  INSERT INTO boost_historique (
    produit_id,
    transaction_id,
    duree_jours,
    montant,
    base_calcul,
    expire_at
  ) VALUES (
    p_produit_id,
    p_transaction_id,
    p_duree_jours,
    p_montant,
    v_base_calcul,
    v_nouvelle_expiration
  );

  RETURN QUERY
  SELECT v_base_calcul, v_nouvelle_expiration;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- 5️⃣ Fonction qui désactive automatiquement les boosts expirés
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

-- 6️⃣ Activer pg_cron pour désactiver automatiquement (toutes les heures)
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