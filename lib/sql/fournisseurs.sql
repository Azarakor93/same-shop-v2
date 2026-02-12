-- ===============================================
-- 📦 SAME SHOP - MODULE FOURNISSEURS (2 000 FCFA / 7j)
-- ===============================================
-- Objectif:
-- - Une boutique crée une "demande fournisseur" après paiement
-- - Toutes les boutiques peuvent voir les demandes actives
-- - Les fournisseurs répondent via "réponses" (messagerie viendra ensuite)

-- ===============================================
-- 1) TABLE DEMANDES FOURNISSEURS
-- ===============================================
CREATE TABLE IF NOT EXISTS demandes_fournisseurs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  demandeur_id UUID NOT NULL REFERENCES vendeurs(id) ON DELETE CASCADE,
  transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,

  produit_recherche TEXT NOT NULL,
  quantite INTEGER,
  budget INTEGER,
  ville TEXT,
  pays TEXT,
  livraison_ville TEXT,
  details TEXT,

  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expire_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_demandes_fournisseurs_demandeur ON demandes_fournisseurs(demandeur_id);
CREATE INDEX IF NOT EXISTS idx_demandes_fournisseurs_expire ON demandes_fournisseurs(expire_at DESC);
CREATE INDEX IF NOT EXISTS idx_demandes_fournisseurs_active ON demandes_fournisseurs(active) WHERE active = TRUE;

-- Contraintes d'intégrité (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'demandes_fournisseurs_quantite_positive'
  ) THEN
    ALTER TABLE demandes_fournisseurs
    ADD CONSTRAINT demandes_fournisseurs_quantite_positive
    CHECK (quantite IS NULL OR quantite > 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'demandes_fournisseurs_budget_positif'
  ) THEN
    ALTER TABLE demandes_fournisseurs
    ADD CONSTRAINT demandes_fournisseurs_budget_positif
    CHECK (budget IS NULL OR budget > 0);
  END IF;
END $$;

-- ===============================================
-- 2) TABLE RÉPONSES FOURNISSEURS
-- ===============================================
CREATE TABLE IF NOT EXISTS reponses_fournisseurs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  demande_id UUID NOT NULL REFERENCES demandes_fournisseurs(id) ON DELETE CASCADE,
  fournisseur_id UUID NOT NULL REFERENCES vendeurs(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  prix_propose INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT unique_reponse_par_fournisseur UNIQUE (demande_id, fournisseur_id)
);

CREATE INDEX IF NOT EXISTS idx_reponses_fournisseurs_demande ON reponses_fournisseurs(demande_id);
CREATE INDEX IF NOT EXISTS idx_reponses_fournisseurs_fournisseur ON reponses_fournisseurs(fournisseur_id);

-- ===============================================
-- 3) RLS
-- ===============================================
ALTER TABLE demandes_fournisseurs ENABLE ROW LEVEL SECURITY;
ALTER TABLE reponses_fournisseurs ENABLE ROW LEVEL SECURITY;

-- Demandes: tout le monde peut voir les demandes actives non expirées
DROP POLICY IF EXISTS "Select active supplier requests" ON demandes_fournisseurs;
CREATE POLICY "Select active supplier requests" ON demandes_fournisseurs
FOR SELECT
USING (active = TRUE AND expire_at > NOW());

-- Demandes: le demandeur peut tout faire sur ses demandes
DROP POLICY IF EXISTS "Owner manages own supplier requests" ON demandes_fournisseurs;
CREATE POLICY "Owner manages own supplier requests" ON demandes_fournisseurs
FOR ALL
USING (auth.uid() = demandeur_id)
WITH CHECK (auth.uid() = demandeur_id);

-- Réponses: un fournisseur peut créer une réponse
DROP POLICY IF EXISTS "Supplier can create response" ON reponses_fournisseurs;
CREATE POLICY "Supplier can create response" ON reponses_fournisseurs
FOR INSERT
WITH CHECK (auth.uid() = fournisseur_id);

-- Réponses: visibles par le fournisseur OU le demandeur
DROP POLICY IF EXISTS "Supplier or requester can view responses" ON reponses_fournisseurs;
CREATE POLICY "Supplier or requester can view responses" ON reponses_fournisseurs
FOR SELECT
USING (
  auth.uid() = fournisseur_id
  OR EXISTS (
    SELECT 1
    FROM demandes_fournisseurs d
    WHERE d.id = demande_id
      AND d.demandeur_id = auth.uid()
  )
);

-- Réponses: le fournisseur peut modifier/supprimer sa réponse
DROP POLICY IF EXISTS "Supplier manages own response" ON reponses_fournisseurs;
CREATE POLICY "Supplier manages own response" ON reponses_fournisseurs
FOR UPDATE
USING (auth.uid() = fournisseur_id)
WITH CHECK (auth.uid() = fournisseur_id);

DROP POLICY IF EXISTS "Supplier deletes own response" ON reponses_fournisseurs;
CREATE POLICY "Supplier deletes own response" ON reponses_fournisseurs
FOR DELETE
USING (auth.uid() = fournisseur_id);
