-- ===============================================
-- 🚚 SAME SHOP - LIVRAISONS (MVP)
-- ===============================================
-- PDF:
-- - 5 premières livraisons gratuites (livreur)
-- - Pack 1 000 FCFA / 10 livraisons
-- - Demande spéciale: 25 FCFA
-- - Commission: 100 FCFA (à l'étape validation)

-- 1) Packs livreur (crédits de livraisons)
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

-- 2) Demandes de livraison
CREATE TABLE IF NOT EXISTS livraisons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vendeur_id UUID REFERENCES vendeurs(id) ON DELETE SET NULL,
  livreur_id UUID REFERENCES livreurs(id) ON DELETE SET NULL,

  statut TEXT NOT NULL DEFAULT 'en_attente' CHECK (statut IN (
    'en_attente', 'acceptee', 'en_cours', 'livree', 'annulee'
  )),

  -- Tarification
  prix_livraison INTEGER,
  commission INTEGER NOT NULL DEFAULT 100,
  demande_speciale BOOLEAN NOT NULL DEFAULT FALSE,
  frais_demande_speciale INTEGER NOT NULL DEFAULT 25,

  -- Adresses / GPS
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

-- Updated_at
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

-- 3) RLS
ALTER TABLE livraison_packs ENABLE ROW LEVEL SECURITY;
ALTER TABLE livraisons ENABLE ROW LEVEL SECURITY;

-- Packs: seul le livreur voit ses packs
CREATE POLICY "Livreur voit ses packs" ON livraison_packs
FOR SELECT USING (auth.uid() = livreur_id);

-- Livraisons: client, vendeur, livreur peuvent voir
CREATE POLICY "Participants voient la livraison" ON livraisons
FOR SELECT USING (
  auth.uid() = client_id
  OR auth.uid() = vendeur_id
  OR auth.uid() = livreur_id
);

-- Création: client crée sa demande
CREATE POLICY "Client crée livraison" ON livraisons
FOR INSERT WITH CHECK (auth.uid() = client_id);

-- Update: uniquement livreur assigné ou client (annulation) ou vendeur
CREATE POLICY "Participants modifient livraison" ON livraisons
FOR UPDATE USING (
  auth.uid() = client_id
  OR auth.uid() = vendeur_id
  OR auth.uid() = livreur_id
);

