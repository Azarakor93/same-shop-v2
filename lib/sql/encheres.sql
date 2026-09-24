-- ===============================================
-- 🏆 TABLE ENCHÈRES
-- ===============================================
-- Gestion des enchères en temps réel pour les produits

-- Suppression si existe
DROP TABLE IF EXISTS public.encheres_offres CASCADE;
DROP TABLE IF EXISTS public.encheres CASCADE;

-- Table principale des enchères
CREATE TABLE public.encheres (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Relation avec le produit
  produit_id UUID NOT NULL REFERENCES public.produits(id) ON DELETE CASCADE,

  -- Informations enchère
  prix_depart INTEGER NOT NULL CHECK (prix_depart > 0),
  prix_actuel INTEGER NOT NULL CHECK (prix_actuel >= prix_depart),
  prix_reserve INTEGER, -- Prix minimum accepté par le vendeur

  -- Dates
  date_debut TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  date_fin TIMESTAMP WITH TIME ZONE NOT NULL,

  -- Statistiques
  nombre_encherisseurs INTEGER NOT NULL DEFAULT 0,
  nombre_offres INTEGER NOT NULL DEFAULT 0,

  -- État
  statut TEXT NOT NULL DEFAULT 'active' CHECK (statut IN ('active', 'terminee', 'annulee')),
  gagnant_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,

  -- Métadonnées
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Contraintes
  CONSTRAINT date_fin_apres_debut CHECK (date_fin > date_debut)
);

-- Table des offres d'enchères
CREATE TABLE public.encheres_offres (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Relations
  enchere_id UUID NOT NULL REFERENCES public.encheres(id) ON DELETE CASCADE,
  encherisseur_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Montant
  montant INTEGER NOT NULL CHECK (montant > 0),

  -- Métadonnées
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Contraintes
  UNIQUE(enchere_id, encherisseur_id, montant)
);

-- ===============================================
-- 📊 INDEX POUR PERFORMANCE
-- ===============================================

-- Index pour requêtes fréquentes
CREATE INDEX idx_encheres_produit ON public.encheres(produit_id);
CREATE INDEX idx_encheres_statut ON public.encheres(statut);
CREATE INDEX idx_encheres_date_fin ON public.encheres(date_fin);
CREATE INDEX idx_encheres_actives ON public.encheres(statut, date_fin) WHERE statut = 'active';

CREATE INDEX idx_encheres_offres_enchere ON public.encheres_offres(enchere_id);
CREATE INDEX idx_encheres_offres_encherisseur ON public.encheres_offres(encherisseur_id);
CREATE INDEX idx_encheres_offres_created ON public.encheres_offres(created_at DESC);

-- ===============================================
-- 🔒 ROW LEVEL SECURITY (RLS)
-- ===============================================

ALTER TABLE public.encheres ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.encheres_offres ENABLE ROW LEVEL SECURITY;

-- Politique: Tout le monde peut voir les enchères actives
CREATE POLICY "Enchères visibles par tous"
  ON public.encheres
  FOR SELECT
  USING (true);

-- Politique: Seul le vendeur peut créer une enchère
CREATE POLICY "Vendeur peut créer enchère"
  ON public.encheres
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.produits p
      WHERE p.id = produit_id
      AND p.vendeur_id = auth.uid()
    )
  );

-- Politique: Seul le vendeur peut modifier son enchère
CREATE POLICY "Vendeur peut modifier enchère"
  ON public.encheres
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.produits p
      WHERE p.id = produit_id
      AND p.vendeur_id = auth.uid()
    )
  );

-- Politique: Tout le monde peut voir les offres
CREATE POLICY "Offres visibles par tous"
  ON public.encheres_offres
  FOR SELECT
  USING (true);

-- Politique: Utilisateurs authentifiés peuvent créer des offres
CREATE POLICY "Utilisateurs peuvent enchérir"
  ON public.encheres_offres
  FOR INSERT
  WITH CHECK (auth.uid() = encherisseur_id);

-- ===============================================
-- 🔄 TRIGGERS
-- ===============================================

-- Fonction: Mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_encheres_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER encheres_updated_at
  BEFORE UPDATE ON public.encheres
  FOR EACH ROW
  EXECUTE FUNCTION update_encheres_updated_at();

-- Fonction: Mettre à jour prix_actuel et stats après nouvelle offre
CREATE OR REPLACE FUNCTION update_enchere_after_offre()
RETURNS TRIGGER AS $$
BEGIN
  -- Mettre à jour le prix actuel et les statistiques
  UPDATE public.encheres
  SET
    prix_actuel = GREATEST(prix_actuel, NEW.montant),
    nombre_offres = nombre_offres + 1,
    nombre_encherisseurs = (
      SELECT COUNT(DISTINCT encherisseur_id)
      FROM public.encheres_offres
      WHERE enchere_id = NEW.enchere_id
    )
  WHERE id = NEW.enchere_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_enchere_stats
  AFTER INSERT ON public.encheres_offres
  FOR EACH ROW
  EXECUTE FUNCTION update_enchere_after_offre();

-- Fonction: Clôturer automatiquement les enchères expirées
CREATE OR REPLACE FUNCTION cloturer_encheres_expirees()
RETURNS void AS $$
BEGIN
  -- Marquer comme terminées les enchères expirées
  UPDATE public.encheres
  SET statut = 'terminee',
      gagnant_id = (
        SELECT encherisseur_id
        FROM public.encheres_offres
        WHERE enchere_id = encheres.id
        ORDER BY montant DESC, created_at ASC
        LIMIT 1
      )
  WHERE statut = 'active'
  AND date_fin < NOW();
END;
$$ LANGUAGE plpgsql;

-- ===============================================
-- 📝 FONCTIONS UTILES
-- ===============================================

-- Fonction: Récupérer les enchères actives
CREATE OR REPLACE FUNCTION get_encheres_actives()
RETURNS TABLE (
  id UUID,
  produit_id UUID,
  nom_produit TEXT,
  prix_depart INTEGER,
  prix_actuel INTEGER,
  date_debut TIMESTAMP WITH TIME ZONE,
  date_fin TIMESTAMP WITH TIME ZONE,
  nombre_encherisseurs INTEGER,
  nombre_offres INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    e.id,
    e.produit_id,
    p.nom as nom_produit,
    e.prix_depart,
    e.prix_actuel,
    e.date_debut,
    e.date_fin,
    e.nombre_encherisseurs,
    e.nombre_offres
  FROM public.encheres e
  JOIN public.produits p ON p.id = e.produit_id
  WHERE e.statut = 'active'
  AND e.date_fin > NOW()
  ORDER BY e.date_fin ASC;
END;
$$ LANGUAGE plpgsql;

-- Fonction: Vérifier si un utilisateur peut enchérir
CREATE OR REPLACE FUNCTION peut_encherir(
  p_enchere_id UUID,
  p_montant INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
  v_prix_actuel INTEGER;
  v_date_fin TIMESTAMP WITH TIME ZONE;
  v_statut TEXT;
  v_vendeur_id UUID;
BEGIN
  -- Récupérer infos enchère
  SELECT e.prix_actuel, e.date_fin, e.statut, p.vendeur_id
  INTO v_prix_actuel, v_date_fin, v_statut, v_vendeur_id
  FROM public.encheres e
  JOIN public.produits p ON p.id = e.produit_id
  WHERE e.id = p_enchere_id;

  -- Vérifications
  IF v_statut != 'active' THEN
    RETURN FALSE;
  END IF;

  IF v_date_fin < NOW() THEN
    RETURN FALSE;
  END IF;

  IF p_montant <= v_prix_actuel THEN
    RETURN FALSE;
  END IF;

  IF v_vendeur_id = auth.uid() THEN
    RETURN FALSE;
  END IF;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===============================================
-- 🎯 DONNÉES DE TEST
-- ===============================================

-- Insérer quelques enchères de test (à adapter selon vos produits)
-- INSERT INTO public.encheres (produit_id, prix_depart, prix_actuel, date_fin)
-- SELECT
--   id,
--   FLOOR(RANDOM() * 50000 + 10000)::INTEGER,
--   FLOOR(RANDOM() * 50000 + 10000)::INTEGER,
--   NOW() + (RANDOM() * INTERVAL '7 days')
-- FROM public.produits
-- WHERE actif = true
-- LIMIT 10;

-- ===============================================
-- 📋 COMMENTAIRES
-- ===============================================

COMMENT ON TABLE public.encheres IS 'Enchères en temps réel pour les produits';
COMMENT ON TABLE public.encheres_offres IS 'Offres des enchérisseurs';
COMMENT ON COLUMN public.encheres.prix_reserve IS 'Prix minimum accepté (invisible)';
COMMENT ON COLUMN public.encheres.statut IS 'active, terminee, annulee';
COMMENT ON FUNCTION get_encheres_actives() IS 'Récupère toutes les enchères actives avec détails produit';
COMMENT ON FUNCTION peut_encherir(UUID, INTEGER) IS 'Vérifie si un utilisateur peut placer une enchère';
