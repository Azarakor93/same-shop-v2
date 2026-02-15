-- ===============================================
-- 🔨 SAME SHOP - ENCHÈRES ENTREPRISES
-- ===============================================
-- Abonnement 30 000 FCFA — Enchères illimitées

-- ===============================================
-- 1) ENCHÈRES (créées par entreprises)
-- ===============================================
CREATE TABLE IF NOT EXISTS encheres (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendeur_id UUID NOT NULL REFERENCES vendeurs(id) ON DELETE CASCADE,
  titre TEXT NOT NULL,
  description TEXT,
  lot_texte TEXT NOT NULL,
  quantite INTEGER NOT NULL DEFAULT 1,
  prix_depart INTEGER NOT NULL,
  duree_type TEXT NOT NULL CHECK (duree_type IN ('1h', '6h', '24h', '3j', '7j')),
  date_fin TIMESTAMP WITH TIME ZONE NOT NULL,
  statut TEXT NOT NULL DEFAULT 'en_cours' CHECK (statut IN ('en_cours', 'termine', 'annule')),
  gagnant_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  meilleure_offre_id UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_encheres_vendeur ON encheres(vendeur_id);
CREATE INDEX IF NOT EXISTS idx_encheres_statut ON encheres(statut);
CREATE INDEX IF NOT EXISTS idx_encheres_date_fin ON encheres(date_fin);

-- ===============================================
-- 2) OFFRES (clients qui enchérissent)
-- ===============================================
CREATE TABLE IF NOT EXISTS encheres_offres (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  enchere_id UUID NOT NULL REFERENCES encheres(id) ON DELETE CASCADE,
  acheteur_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  montant INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_encheres_offres_enchere ON encheres_offres(enchere_id);

-- Lier l'offre gagnante à la table des offres (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'encheres_meilleure_offre_id_fkey'
  ) THEN
    ALTER TABLE encheres
    ADD CONSTRAINT encheres_meilleure_offre_id_fkey
    FOREIGN KEY (meilleure_offre_id)
    REFERENCES encheres_offres(id)
    ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_encheres_meilleure_offre_id ON encheres(meilleure_offre_id);


-- ===============================================
-- 3) RLS
-- ===============================================
ALTER TABLE encheres ENABLE ROW LEVEL SECURITY;
ALTER TABLE encheres_offres ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view active encheres" ON encheres;
CREATE POLICY "Anyone can view active encheres" ON encheres
FOR SELECT USING (statut = 'en_cours' OR auth.uid() = vendeur_id);

DROP POLICY IF EXISTS "Vendeur manages own encheres" ON encheres;
CREATE POLICY "Vendeur manages own encheres" ON encheres
FOR ALL USING (auth.uid() = vendeur_id)
WITH CHECK (auth.uid() = vendeur_id);

DROP POLICY IF EXISTS "Anyone can view offres" ON encheres_offres;
CREATE POLICY "Anyone can view offres" ON encheres_offres
FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Users can place offres" ON encheres_offres;
CREATE POLICY "Users can place offres" ON encheres_offres
FOR INSERT WITH CHECK (auth.uid() = acheteur_id);
