-- ===============================================
-- 🧾 SAME SHOP - COMMANDES
-- ===============================================
-- Commandes client + lignes de commande liées aux produits/vendeurs

-- 1) TABLE COMMANDES (EN-TÊTE)
CREATE TABLE IF NOT EXISTS commandes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Montant total en FCFA (sans frais livraison pour MVP)
  total INTEGER NOT NULL,

  statut TEXT NOT NULL DEFAULT 'en_attente' CHECK (
    statut IN ('en_attente', 'en_preparation', 'expediee', 'livree', 'annulee')
  ),

  -- Adresse / infos libres pour MVP (texte)
  adresse_texte TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_commandes_client ON commandes(client_id);
CREATE INDEX IF NOT EXISTS idx_commandes_statut ON commandes(statut);
CREATE INDEX IF NOT EXISTS idx_commandes_created ON commandes(created_at DESC);

-- 2) TABLE LIGNES DE COMMANDE
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

-- 3) RLS
ALTER TABLE commandes ENABLE ROW LEVEL SECURITY;
ALTER TABLE commande_lignes ENABLE ROW LEVEL SECURITY;

-- Le client voit / gère uniquement ses propres commandes
CREATE POLICY "Client voit ses commandes" ON commandes
FOR SELECT USING (auth.uid() = client_id);

CREATE POLICY "Client crée ses commandes" ON commandes
FOR INSERT WITH CHECK (auth.uid() = client_id);

-- Lignes: visibles par le client de la commande
CREATE POLICY "Client voit lignes commande" ON commande_lignes
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM commandes c
    WHERE c.id = commande_id AND c.client_id = auth.uid()
  )
);

-- Lignes: insertion uniquement par le client (via l'app)
CREATE POLICY "Client crée lignes commande" ON commande_lignes
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM commandes c
    WHERE c.id = commande_id AND c.client_id = auth.uid()
  )
);

-- Vendeur voit les lignes qui concernent ses produits
CREATE POLICY "Vendeur voit lignes liées" ON commande_lignes
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM vendeurs v
    WHERE v.id = vendeur_id AND v.id = auth.uid()
  )
);

