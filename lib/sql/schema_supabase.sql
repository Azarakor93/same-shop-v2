-- ===============================================
-- 📊 SAMESHOP - SCHÉMA COMPLET (Vendeurs/Produits)
-- ===============================================

-- ===============================================
-- 💳 TABLE TRANSACTIONS
-- ===============================================
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vendeur_id UUID REFERENCES vendeurs(id) ON DELETE SET NULL,  -- ✅ Vendeurs
  produit_id UUID REFERENCES produits(id) ON DELETE SET NULL,  -- ✅ Produits
  
  methode_paiement TEXT NOT NULL CHECK (methode_paiement IN ('tmoney', 'flooz')),
  numero_telephone TEXT NOT NULL,
  montant INTEGER NOT NULL CHECK (montant > 0),
  
  type_transaction TEXT NOT NULL CHECK (type_transaction IN ('abonnement', 'boost', 'fournisseur')),
  type_abonnement TEXT CHECK (type_abonnement IN ('gratuit', 'premium', 'entreprise')),
  duree_jours INTEGER, -- ✅ boost: durée sélectionnée (1/3/10/30 etc.)
  
  statut TEXT NOT NULL DEFAULT 'en_attente' CHECK (statut IN ('en_attente', 'en_cours', 'valide', 'echoue', 'annule')),
  reference_externe TEXT,
  
  date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  date_validation TIMESTAMP WITH TIME ZONE
);

-- Index transactions
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_vendeur_id ON transactions(vendeur_id);
CREATE INDEX IF NOT EXISTS idx_transactions_statut ON transactions(statut);
CREATE INDEX IF NOT EXISTS idx_transactions_date_creation ON transactions(date_creation DESC);

-- ===============================================
-- 📦 AJOUTER COLONNES PRODUITS (si pas déjà fait)
-- ===============================================
ALTER TABLE produits 
  ADD COLUMN IF NOT EXISTS est_booste BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS date_expiration_boost TIMESTAMP WITH TIME ZONE,
  -- ✅ Nouveau système (recommandé) : boost cumulatif
  ADD COLUMN IF NOT EXISTS boost_actif BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS boost_expire_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS nombre_partages INTEGER DEFAULT 0;

-- Index boost produits
CREATE INDEX IF NOT EXISTS idx_produits_booste ON produits(est_booste, date_expiration_boost) 
WHERE est_booste = TRUE;

-- ✅ Historique boosts (recommandé pour traçabilité)
CREATE TABLE IF NOT EXISTS boost_historique (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  produit_id UUID REFERENCES produits(id) ON DELETE CASCADE,
  transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,
  duree_jours INTEGER NOT NULL,
  montant INTEGER NOT NULL,
  base_calcul TIMESTAMP WITH TIME ZONE NOT NULL,
  expire_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_boost_historique_produit_id ON boost_historique(produit_id);
CREATE INDEX IF NOT EXISTS idx_produits_boost_expire_at ON produits(boost_expire_at) WHERE boost_actif = TRUE;

-- ===============================================
-- 📊 STATISTIQUES PRODUITS
-- ===============================================
CREATE TABLE IF NOT EXISTS statistiques_produits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  produit_id UUID NOT NULL REFERENCES produits(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  nombre_vues INTEGER DEFAULT 0,
  nombre_clics INTEGER DEFAULT 0,
  nombre_partages INTEGER DEFAULT 0,
  nombre_favoris INTEGER DEFAULT 0,
  CONSTRAINT statistiques_produits_unique UNIQUE (produit_id, date)
);

CREATE INDEX IF NOT EXISTS idx_statistiques_produits_produit_id ON statistiques_produits(produit_id);
CREATE INDEX IF NOT EXISTS idx_statistiques_produits_date ON statistiques_produits(date DESC);

-- ===============================================
-- 📊 STATISTIQUES VENDEURS
-- ===============================================
CREATE TABLE IF NOT EXISTS statistiques_vendeurs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendeur_id UUID NOT NULL REFERENCES vendeurs(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  nombre_visites INTEGER DEFAULT 0,
  nombre_vues_produits INTEGER DEFAULT 0,
  nombre_commandes INTEGER DEFAULT 0,
  chiffre_affaires INTEGER DEFAULT 0,
  CONSTRAINT statistiques_vendeurs_unique UNIQUE (vendeur_id, date)
);

CREATE INDEX IF NOT EXISTS idx_statistiques_vendeurs_vendeur_id ON statistiques_vendeurs(vendeur_id);
CREATE INDEX IF NOT EXISTS idx_statistiques_vendeurs_date ON statistiques_vendeurs(date DESC);

-- ===============================================
-- 🔔 NOTIFICATIONS
-- ===============================================
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  titre TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('info', 'succes', 'avertissement', 'erreur', 'paiement', 'boost', 'abonnement')),
  lien_type TEXT CHECK (lien_type IN ('vendeur', 'produit', 'transaction')),
  lien_id UUID,
  est_lu BOOLEAN DEFAULT FALSE,
  date_creation TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_non_lues ON notifications(est_lu) WHERE est_lu = FALSE;

-- ===============================================
-- 👑 SUPER ADMINS
-- ===============================================
CREATE TABLE IF NOT EXISTS super_admins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  peut_tout_voir BOOLEAN DEFAULT TRUE,
  peut_modifier BOOLEAN DEFAULT TRUE,
  peut_supprimer BOOLEAN DEFAULT FALSE,
  date_ajout TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===============================================
-- 🔒 RLS (SECURITÉ)
-- ===============================================
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE statistiques_produits ENABLE ROW LEVEL SECURITY;
ALTER TABLE statistiques_vendeurs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE super_admins ENABLE ROW LEVEL SECURITY;

-- RLS Transactions
CREATE POLICY "Users can view own transactions" ON transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create transactions" ON transactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Super admins view all transactions" ON transactions FOR SELECT USING (
  EXISTS (SELECT 1 FROM super_admins WHERE user_id = auth.uid())
);

-- RLS Stats Produits (propriétaire)
CREATE POLICY "Owners view product stats" ON statistiques_produits FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM produits p 
    WHERE p.id = produit_id AND p.vendeur_id = auth.uid()
  )
);

-- RLS Stats Vendeurs (propriétaire)
CREATE POLICY "Owners view vendor stats" ON statistiques_vendeurs FOR SELECT USING (
  EXISTS (SELECT 1 FROM vendeurs WHERE id = vendeur_id AND id = auth.uid())
);

-- RLS Notifications
CREATE POLICY "Users view own notifications" ON notifications FOR ALL USING (auth.uid() = user_id);

-- ===============================================
-- ✅ TERMINÉ - Exécutez ce script COMPLET
-- ===============================================
