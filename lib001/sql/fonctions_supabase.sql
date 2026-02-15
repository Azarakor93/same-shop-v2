-- ===============================================
-- 🧠 SAME SHOP - FONCTIONS UTILITAIRES SUPABASE
-- ===============================================
-- Ce fichier complète les triggers présents dans `mestables_supabase.sql`
-- et les RPC utilisés dans l'app Flutter.

-- ===============================================
-- 0) Updated_at générique
-- ===============================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ===============================================
-- 1) RPC: incrémenter les vues d’un produit
-- ===============================================
CREATE OR REPLACE FUNCTION increment_vues(produit_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE produits
  SET nombre_vues = COALESCE(nombre_vues, 0) + 1
  WHERE id = produit_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===============================================
-- 2) Recalcul du stock global (tailles/couleurs/variantes)
-- ===============================================
-- Hypothèse simple: stock_global = max(
--   somme des tailles, somme des couleurs, somme des variantes, valeur actuelle
-- )
-- (Pour éviter d'écraser des stocks saisis manuellement si vous en avez.)
CREATE OR REPLACE FUNCTION update_stock_global()
RETURNS trigger AS $$
DECLARE
  v_produit_id uuid;
  v_somme_tailles int;
  v_somme_couleurs int;
  v_somme_variantes int;
BEGIN
  v_produit_id := COALESCE(NEW.produit_id, OLD.produit_id);

  SELECT COALESCE(SUM(stock), 0)
  INTO v_somme_tailles
  FROM produit_tailles
  WHERE produit_id = v_produit_id;

  SELECT COALESCE(SUM(stock), 0)
  INTO v_somme_couleurs
  FROM produit_couleurs
  WHERE produit_id = v_produit_id;

  SELECT COALESCE(SUM(stock), 0)
  INTO v_somme_variantes
  FROM produit_variantes
  WHERE produit_id = v_produit_id;

  UPDATE produits
  SET stock_global = GREATEST(
    COALESCE(stock_global, 0),
    v_somme_tailles,
    v_somme_couleurs,
    v_somme_variantes
  )
  WHERE id = v_produit_id;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- ===============================================
-- 3) Recalcul de la note moyenne produit
-- ===============================================
CREATE OR REPLACE FUNCTION update_produit_note()
RETURNS trigger AS $$
DECLARE
  v_produit_id uuid;
  v_moy numeric;
BEGIN
  v_produit_id := COALESCE(NEW.produit_id, OLD.produit_id);

  SELECT COALESCE(AVG(note)::numeric(10,2), 0)
  INTO v_moy
  FROM produit_rates
  WHERE produit_id = v_produit_id;

  UPDATE produits
  SET note = v_moy
  WHERE id = v_produit_id;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- ===============================================
-- 4) Garde-fou: empêcher de désactiver un produit si abonnement invalide
-- ===============================================
-- Interprétation minimale:
-- - Si vendeur premium/entreprise expiré (date_expiration_abonnement < now),
--   on empêche la mise à jour "actif=false" ? (ou on empêche toggle)
-- Comme le besoin exact peut varier, on implémente une règle simple:
-- - Si un vendeur est "premium" et expiré, on refuse toute mise à jour de `actif`
--   (oblige à régulariser).
CREATE OR REPLACE FUNCTION verifier_abonnement_toggle()
RETURNS trigger AS $$
DECLARE
  v_type text;
  v_expire_at timestamptz;
BEGIN
  -- uniquement quand on change `actif`
  IF (NEW.actif IS DISTINCT FROM OLD.actif) THEN
    SELECT type_abonnement, date_expiration_abonnement
    INTO v_type, v_expire_at
    FROM vendeurs
    WHERE id = NEW.vendeur_id;

    IF v_type IN ('premium', 'entreprise') AND v_expire_at IS NOT NULL AND v_expire_at < now() THEN
      RAISE EXCEPTION 'Abonnement expiré: action non autorisée';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

