-- ===============================================
-- 🧾 SAME SHOP - COMMANDES + LIVRAISONS (MVP)
-- ===============================================

-- ===============================================
-- 0) Utilitaire updated_at (réutilisable)
-- ===============================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ===============================================
-- 1) COMMANDES (en-tête)
-- ===============================================
CREATE TABLE IF NOT EXISTS commandes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  total INTEGER NOT NULL,
  statut TEXT NOT NULL DEFAULT 'en_attente' CHECK (
    statut IN ('en_attente', 'en_preparation', 'expediee', 'livree', 'annulee')
  ),
  adresse_texte TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_commandes_client ON commandes(client_id);
CREATE INDEX IF NOT EXISTS idx_commandes_statut ON commandes(statut);
CREATE INDEX IF NOT EXISTS idx_commandes_created ON commandes(created_at DESC);

-- ===============================================
-- 2) LIGNES DE COMMANDE
-- ===============================================
CREATE TABLE IF NOT EXISTS commande_lignes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  commande_id UUID NOT NULL REFERENCES commandes(id) ON DELETE CASCADE,
  produit_id UUID NOT NULL REFERENCES produits(id) ON DELETE RESTRICT,
  vendeur_id UUID NOT NULL REFERENCES vendeurs(id) ON DELETE RESTRICT,
  nom TEXT NOT NULL,
  prix_unitaire INTEGER NOT NULL,
  quantite INTEGER NOT NULL DEFAULT 1,
  taille TEXT,
  couleur TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_commande_lignes_commande ON commande_lignes(commande_id);
CREATE INDEX IF NOT EXISTS idx_commande_lignes_vendeur ON commande_lignes(vendeur_id);

-- ===============================================
-- 3) LIVRAISONS (packs + demandes)
-- ===============================================
CREATE TABLE IF NOT EXISTS livraison_packs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  livreur_id UUID NOT NULL REFERENCES livreurs(id) ON DELETE CASCADE,
  transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
  total INTEGER NOT NULL,
  restant INTEGER NOT NULL,
  type_pack TEXT NOT NULL CHECK (type_pack IN ('gratuit', 'pack10')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_livraison_packs_livreur ON livraison_packs(livreur_id);

CREATE TABLE IF NOT EXISTS livraisons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vendeur_id UUID REFERENCES vendeurs(id) ON DELETE SET NULL,
  livreur_id UUID REFERENCES livreurs(id) ON DELETE SET NULL,

  statut TEXT NOT NULL DEFAULT 'en_attente' CHECK (
    statut IN ('en_attente', 'acceptee', 'en_cours', 'livree', 'annulee')
  ),

  prix_livraison INTEGER,
  commission INTEGER NOT NULL DEFAULT 100,
  demande_speciale BOOLEAN NOT NULL DEFAULT FALSE,
  frais_demande_speciale INTEGER NOT NULL DEFAULT 25,

  depart_texte TEXT,
  arrivee_texte TEXT,
  depart_latitude NUMERIC,
  depart_longitude NUMERIC,
  arrivee_latitude NUMERIC,
  arrivee_longitude NUMERIC,

  note_client INTEGER,
  commentaire_client TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_livraisons_client ON livraisons(client_id);
CREATE INDEX IF NOT EXISTS idx_livraisons_livreur ON livraisons(livreur_id);
CREATE INDEX IF NOT EXISTS idx_livraisons_statut ON livraisons(statut);


-- ===============================================
-- 3.bis) Contraintes d'intégrité supplémentaires (idempotent)
-- ===============================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'commandes_total_non_negatif'
  ) THEN
    ALTER TABLE commandes
    ADD CONSTRAINT commandes_total_non_negatif CHECK (total >= 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'commande_lignes_prix_positif'
  ) THEN
    ALTER TABLE commande_lignes
    ADD CONSTRAINT commande_lignes_prix_positif CHECK (prix_unitaire > 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'commande_lignes_quantite_positive'
  ) THEN
    ALTER TABLE commande_lignes
    ADD CONSTRAINT commande_lignes_quantite_positive CHECK (quantite > 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'livraison_packs_totaux_valides'
  ) THEN
    ALTER TABLE livraison_packs
    ADD CONSTRAINT livraison_packs_totaux_valides CHECK (total > 0 AND restant >= 0 AND restant <= total);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'livraisons_note_client_valide'
  ) THEN
    ALTER TABLE livraisons
    ADD CONSTRAINT livraisons_note_client_valide CHECK (note_client IS NULL OR (note_client >= 1 AND note_client <= 5));
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_livraisons_updated_at'
  ) THEN
    CREATE TRIGGER trigger_livraisons_updated_at
    BEFORE UPDATE ON livraisons
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
  END IF;
END $$;

-- ===============================================
-- 4) RLS
-- ===============================================
ALTER TABLE commandes ENABLE ROW LEVEL SECURITY;
ALTER TABLE commande_lignes ENABLE ROW LEVEL SECURITY;
ALTER TABLE livraison_packs ENABLE ROW LEVEL SECURITY;
ALTER TABLE livraisons ENABLE ROW LEVEL SECURITY;

-- Commandes: le client voit/insère ses commandes
DROP POLICY IF EXISTS "Client voit ses commandes" ON commandes;
CREATE POLICY "Client voit ses commandes" ON commandes
FOR SELECT USING (auth.uid() = client_id);

DROP POLICY IF EXISTS "Client crée ses commandes" ON commandes;
CREATE POLICY "Client crée ses commandes" ON commandes
FOR INSERT WITH CHECK (auth.uid() = client_id);

-- Lignes de commande: visibles par client ou vendeur concerné
DROP POLICY IF EXISTS "Client voit lignes commande" ON commande_lignes;
CREATE POLICY "Client voit lignes commande" ON commande_lignes
FOR SELECT USING (
  EXISTS (
    SELECT 1
    FROM commandes c
    WHERE c.id = commande_id
      AND c.client_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Vendeur voit lignes liées" ON commande_lignes;
CREATE POLICY "Vendeur voit lignes liées" ON commande_lignes
FOR SELECT USING (auth.uid() = vendeur_id);

DROP POLICY IF EXISTS "Client crée lignes commande" ON commande_lignes;
CREATE POLICY "Client crée lignes commande" ON commande_lignes
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1
    FROM commandes c
    WHERE c.id = commande_id
      AND c.client_id = auth.uid()
  )
);

-- Packs: seul le livreur voit ses packs
DROP POLICY IF EXISTS "Livreur voit ses packs" ON livraison_packs;
CREATE POLICY "Livreur voit ses packs" ON livraison_packs
FOR SELECT USING (auth.uid() = livreur_id);

-- Livraisons: participants visibles + modifiables
DROP POLICY IF EXISTS "Participants voient la livraison" ON livraisons;
CREATE POLICY "Participants voient la livraison" ON livraisons
FOR SELECT USING (
  auth.uid() = client_id
  OR auth.uid() = vendeur_id
  OR auth.uid() = livreur_id
);

DROP POLICY IF EXISTS "Client crée livraison" ON livraisons;
CREATE POLICY "Client crée livraison" ON livraisons
FOR INSERT WITH CHECK (auth.uid() = client_id);

DROP POLICY IF EXISTS "Participants modifient livraison" ON livraisons;
CREATE POLICY "Participants modifient livraison" ON livraisons
FOR UPDATE USING (
  auth.uid() = client_id
  OR auth.uid() = vendeur_id
  OR auth.uid() = livreur_id
);
