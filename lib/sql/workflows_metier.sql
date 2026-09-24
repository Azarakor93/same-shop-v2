-- ===============================================
-- ⚙️ SAME SHOP - WORKFLOWS MÉTIER (RPC)
-- ===============================================
-- Fonctions RPC prêtes à appeler depuis Flutter/Supabase.

-- ===============================================
-- 1) Utilitaire conversation: créer ou récupérer
-- ===============================================
CREATE OR REPLACE FUNCTION get_or_create_conversation(
  p_canal TEXT,
  p_ref_id TEXT,
  p_participant_a UUID,
  p_participant_b UUID,
  p_titre TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;
  v_a UUID;
  v_b UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifié';
  END IF;

  IF p_participant_a = p_participant_b THEN
    RAISE EXCEPTION 'Les participants doivent être différents';
  END IF;

  -- normaliser l'ordre des participants pour éviter des doublons logiques
  IF p_participant_a::TEXT < p_participant_b::TEXT THEN
    v_a := p_participant_a;
    v_b := p_participant_b;
  ELSE
    v_a := p_participant_b;
    v_b := p_participant_a;
  END IF;

  SELECT id
  INTO v_id
  FROM conversations
  WHERE canal = p_canal
    AND ref_id = p_ref_id
  LIMIT 1;

  IF v_id IS NOT NULL THEN
    RETURN v_id;
  END IF;

  INSERT INTO conversations (canal, ref_id, participant_a, participant_b, titre)
  VALUES (p_canal, p_ref_id, v_a, v_b, p_titre)
  ON CONFLICT (canal, ref_id) DO UPDATE
    SET updated_at = NOW()
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

-- ===============================================
-- 2) Workflow commande: acceptation côté vendeur
-- ===============================================
CREATE OR REPLACE FUNCTION accepter_commande_vendeur(
  p_commande_id UUID
)
RETURNS TABLE (commande_id UUID, conversation_id UUID)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_client_id UUID;
  v_vendeur_id UUID;
  v_conversation_id UUID;
  v_rows_updated INT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifié';
  END IF;

  -- vérifier qu'une ligne de la commande appartient au vendeur connecté
  SELECT cl.vendeur_id, c.client_id
  INTO v_vendeur_id, v_client_id
  FROM commande_lignes cl
  JOIN commandes c ON c.id = cl.commande_id
  WHERE cl.commande_id = p_commande_id
    AND cl.vendeur_id = auth.uid()
  LIMIT 1;

  IF v_vendeur_id IS NULL THEN
    RAISE EXCEPTION 'Action non autorisée: cette commande ne vous appartient pas';
  END IF;

  UPDATE commandes
  SET statut = 'en_preparation'
  WHERE id = p_commande_id
    AND statut = 'en_attente';

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
  IF v_rows_updated = 0 THEN
    RAISE EXCEPTION 'Commande non modifiée: statut actuel incompatible';
  END IF;

  v_conversation_id := get_or_create_conversation(
    'commande',
    p_commande_id::TEXT,
    v_client_id,
    v_vendeur_id,
    'Commande #' || p_commande_id::TEXT
  );

  RETURN QUERY SELECT p_commande_id, v_conversation_id;
END;
$$;

-- ===============================================
-- 2.bis) Workflow commande: expédition côté vendeur
-- ===============================================
CREATE OR REPLACE FUNCTION expedier_commande_vendeur(
  p_commande_id UUID
)
RETURNS TABLE (commande_id UUID, statut TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rows_updated INT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifié';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM commande_lignes cl
    WHERE cl.commande_id = p_commande_id
      AND cl.vendeur_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Action non autorisée: cette commande ne vous appartient pas';
  END IF;

  UPDATE commandes
  SET statut = 'expediee'
  WHERE id = p_commande_id
    AND statut = 'en_preparation';

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
  IF v_rows_updated = 0 THEN
    RAISE EXCEPTION 'Expédition impossible: statut incompatible';
  END IF;

  RETURN QUERY SELECT p_commande_id, 'expediee'::TEXT;
END;
$$;

-- ===============================================
-- 2.ter) Workflow commande: confirmation de livraison côté client
-- ===============================================
CREATE OR REPLACE FUNCTION confirmer_livraison_commande_client(
  p_commande_id UUID
)
RETURNS TABLE (commande_id UUID, statut TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rows_updated INT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifié';
  END IF;

  UPDATE commandes
  SET statut = 'livree'
  WHERE id = p_commande_id
    AND client_id = auth.uid()
    AND statut = 'expediee';

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
  IF v_rows_updated = 0 THEN
    RAISE EXCEPTION 'Confirmation impossible: commande introuvable ou statut incompatible';
  END IF;

  RETURN QUERY SELECT p_commande_id, 'livree'::TEXT;
END;
$$;

-- ===============================================
-- 3) Workflow livraison: prise de mission côté livreur
-- ===============================================
CREATE OR REPLACE FUNCTION prendre_livraison(
  p_livraison_id UUID,
  p_prix_livraison INTEGER
)
RETURNS TABLE (livraison_id UUID, conversation_id UUID, pack_id UUID, credits_restants INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_client_id UUID;
  v_livreur_existant UUID;
  v_statut TEXT;
  v_conversation_id UUID;
  v_pack_id UUID;
  v_pack_restant INTEGER;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifié';
  END IF;

  IF p_prix_livraison IS NULL OR p_prix_livraison <= 0 THEN
    RAISE EXCEPTION 'Prix de livraison invalide';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM livreurs l
    WHERE l.id = auth.uid()
      AND l.est_suspendu = FALSE
      AND l.est_disponible = TRUE
  ) THEN
    RAISE EXCEPTION 'Profil livreur indisponible ou suspendu';
  END IF;

  SELECT client_id, livreur_id, statut
  INTO v_client_id, v_livreur_existant, v_statut
  FROM livraisons
  WHERE id = p_livraison_id
  FOR UPDATE;

  IF v_client_id IS NULL THEN
    RAISE EXCEPTION 'Livraison introuvable';
  END IF;

  IF v_statut <> 'en_attente' THEN
    RAISE EXCEPTION 'Livraison non disponible (statut=%)', v_statut;
  END IF;

  IF v_livreur_existant IS NOT NULL AND v_livreur_existant <> auth.uid() THEN
    RAISE EXCEPTION 'Livraison déjà prise par un autre livreur';
  END IF;

  -- initialiser un pack gratuit si aucun pack n'existe
  IF NOT EXISTS (SELECT 1 FROM livraison_packs WHERE livreur_id = auth.uid()) THEN
    INSERT INTO livraison_packs (livreur_id, total, restant, type_pack)
    VALUES (auth.uid(), 5, 5, 'gratuit');
  END IF;

  -- sélectionner un pack avec crédit disponible (priorité au gratuit)
  SELECT id, restant
  INTO v_pack_id, v_pack_restant
  FROM livraison_packs
  WHERE livreur_id = auth.uid()
    AND restant > 0
  ORDER BY CASE WHEN type_pack = 'gratuit' THEN 0 ELSE 1 END, created_at ASC
  LIMIT 1
  FOR UPDATE;

  IF v_pack_id IS NULL THEN
    RAISE EXCEPTION 'Crédits de livraison insuffisants: achetez un pack';
  END IF;

  UPDATE livraison_packs
  SET restant = restant - 1
  WHERE id = v_pack_id;

  UPDATE livraisons
  SET
    livreur_id = auth.uid(),
    statut = 'acceptee',
    prix_livraison = p_prix_livraison,
    updated_at = NOW()
  WHERE id = p_livraison_id;

  v_conversation_id := get_or_create_conversation(
    'livraison',
    p_livraison_id::TEXT,
    v_client_id,
    auth.uid(),
    'Livraison #' || p_livraison_id::TEXT
  );

  RETURN QUERY
  SELECT p_livraison_id, v_conversation_id, v_pack_id, GREATEST(v_pack_restant - 1, 0);
END;
$$;

-- ===============================================
-- 4) Workflow enchère: placer une offre
-- ===============================================
CREATE OR REPLACE FUNCTION placer_offre_enchere(
  p_enchere_id UUID,
  p_montant INTEGER
)
RETURNS TABLE (offre_id UUID, montant INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_vendeur_id UUID;
  v_statut TEXT;
  v_date_fin TIMESTAMPTZ;
  v_prix_depart INTEGER;
  v_meilleure_offre INTEGER;
  v_offre_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifié';
  END IF;

  IF p_montant IS NULL OR p_montant <= 0 THEN
    RAISE EXCEPTION 'Montant invalide';
  END IF;

  SELECT vendeur_id, statut, date_fin, prix_depart
  INTO v_vendeur_id, v_statut, v_date_fin, v_prix_depart
  FROM encheres
  WHERE id = p_enchere_id
  FOR UPDATE;

  IF v_vendeur_id IS NULL THEN
    RAISE EXCEPTION 'Enchère introuvable';
  END IF;

  IF auth.uid() = v_vendeur_id THEN
    RAISE EXCEPTION 'Le vendeur ne peut pas enchérir sur sa propre enchère';
  END IF;

  IF v_statut <> 'en_cours' OR v_date_fin <= NOW() THEN
    RAISE EXCEPTION 'Enchère non active';
  END IF;

  SELECT COALESCE(MAX(montant), v_prix_depart)
  INTO v_meilleure_offre
  FROM encheres_offres
  WHERE enchere_id = p_enchere_id;

  IF p_montant <= v_meilleure_offre THEN
    RAISE EXCEPTION 'Montant insuffisant: offre actuelle=%', v_meilleure_offre;
  END IF;

  INSERT INTO encheres_offres (enchere_id, acheteur_id, montant)
  VALUES (p_enchere_id, auth.uid(), p_montant)
  RETURNING id INTO v_offre_id;

  RETURN QUERY SELECT v_offre_id, p_montant;
END;
$$;

-- ===============================================
-- 5) Workflow enchère: clôture automatique/manuelle
-- ===============================================
CREATE OR REPLACE FUNCTION cloturer_enchere(
  p_enchere_id UUID
)
RETURNS TABLE (enchere_id UUID, gagnant_id UUID, montant_gagnant INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_vendeur_id UUID;
  v_statut TEXT;
  v_date_fin TIMESTAMPTZ;
  v_meilleure_offre_id UUID;
  v_gagnant UUID;
  v_montant INTEGER;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifié';
  END IF;

  SELECT vendeur_id, statut, date_fin
  INTO v_vendeur_id, v_statut, v_date_fin
  FROM encheres
  WHERE id = p_enchere_id
  FOR UPDATE;

  IF v_vendeur_id IS NULL THEN
    RAISE EXCEPTION 'Enchère introuvable';
  END IF;

  IF auth.uid() <> v_vendeur_id THEN
    RAISE EXCEPTION 'Action non autorisée: seule la boutique propriétaire peut clôturer';
  END IF;

  IF v_statut <> 'en_cours' THEN
    RAISE EXCEPTION 'Enchère déjà clôturée ou annulée';
  END IF;

  IF v_date_fin > NOW() THEN
    RAISE EXCEPTION 'Impossible de clôturer avant la date de fin';
  END IF;

  SELECT o.id, o.acheteur_id, o.montant
  INTO v_meilleure_offre_id, v_gagnant, v_montant
  FROM encheres_offres o
  WHERE o.enchere_id = p_enchere_id
  ORDER BY o.montant DESC, o.created_at ASC
  LIMIT 1;

  UPDATE encheres
  SET
    statut = 'termine',
    gagnant_id = v_gagnant,
    meilleure_offre_id = v_meilleure_offre_id
  WHERE id = p_enchere_id;

  IF v_gagnant IS NOT NULL THEN
    PERFORM get_or_create_conversation(
      'enchere',
      p_enchere_id::TEXT,
      v_gagnant,
      v_vendeur_id,
      'Résultat enchère #' || p_enchere_id::TEXT
    );
  END IF;

  RETURN QUERY SELECT p_enchere_id, v_gagnant, COALESCE(v_montant, 0);
END;
$$;

-- ===============================================
-- 6) Workflow maintenance: clôturer toutes les enchères expirées
-- ===============================================
CREATE OR REPLACE FUNCTION cloturer_encheres_expirees_vendeur()
RETURNS TABLE (enchere_id UUID, gagnant_id UUID, montant_gagnant INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_enchere_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifié';
  END IF;

  FOR v_enchere_id IN
    SELECT e.id
    FROM encheres e
    WHERE e.vendeur_id = auth.uid()
      AND e.statut = 'en_cours'
      AND e.date_fin <= NOW()
    ORDER BY e.date_fin ASC
  LOOP
    RETURN QUERY SELECT * FROM cloturer_enchere(v_enchere_id);
  END LOOP;
END;
$$;

-- ===============================================
-- 7) Workflow commande: création atomique commande + lignes
-- ===============================================
CREATE OR REPLACE FUNCTION creer_commande_avec_lignes(
  p_adresse_texte TEXT,
  p_lignes JSONB
)
RETURNS TABLE (commande_id UUID, total INTEGER, lignes_count INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_commande_id UUID;
  v_total INTEGER := 0;
  v_lignes_count INTEGER := 0;
  v_item JSONB;
  v_produit_id UUID;
  v_quantite INTEGER;
  v_taille TEXT;
  v_couleur TEXT;
  v_nom TEXT;
  v_prix INTEGER;
  v_vendeur_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifié';
  END IF;

  IF p_lignes IS NULL OR jsonb_typeof(p_lignes) <> 'array' OR jsonb_array_length(p_lignes) = 0 THEN
    RAISE EXCEPTION 'Panier invalide: lignes manquantes';
  END IF;

  INSERT INTO commandes (client_id, total, statut, adresse_texte)
  VALUES (auth.uid(), 0, 'en_attente', p_adresse_texte)
  RETURNING id INTO v_commande_id;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_lignes)
  LOOP
    v_produit_id := (v_item->>'produit_id')::UUID;
    v_quantite := COALESCE((v_item->>'quantite')::INTEGER, 1);
    v_taille := NULLIF(v_item->>'taille', '');
    v_couleur := NULLIF(v_item->>'couleur', '');

    IF v_produit_id IS NULL OR v_quantite <= 0 THEN
      RAISE EXCEPTION 'Ligne invalide: produit_id/quantite';
    END IF;

    SELECT p.nom, p.prix, p.vendeur_id
    INTO v_nom, v_prix, v_vendeur_id
    FROM produits p
    WHERE p.id = v_produit_id
      AND p.actif = TRUE;

    IF v_vendeur_id IS NULL THEN
      RAISE EXCEPTION 'Produit introuvable ou inactif';
    END IF;

    INSERT INTO commande_lignes (
      commande_id,
      produit_id,
      vendeur_id,
      nom,
      prix_unitaire,
      quantite,
      taille,
      couleur
    ) VALUES (
      v_commande_id,
      v_produit_id,
      v_vendeur_id,
      v_nom,
      v_prix,
      v_quantite,
      v_taille,
      v_couleur
    );

    v_total := v_total + (v_prix * v_quantite);
    v_lignes_count := v_lignes_count + 1;
  END LOOP;

  UPDATE commandes
  SET total = v_total
  WHERE id = v_commande_id;

  RETURN QUERY SELECT v_commande_id, v_total, v_lignes_count;
END;
$$;



-- ===============================================
-- 8) Workflow commande: annulation côté client
-- ===============================================
CREATE OR REPLACE FUNCTION annuler_commande_client(
  p_commande_id UUID
)
RETURNS TABLE (commande_id UUID, statut TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rows_updated INT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifié';
  END IF;

  UPDATE commandes
  SET statut = 'annulee'
  WHERE id = p_commande_id
    AND client_id = auth.uid()
    AND statut IN ('en_attente', 'en_preparation');

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
  IF v_rows_updated = 0 THEN
    RAISE EXCEPTION 'Annulation impossible: statut incompatible ou commande introuvable';
  END IF;

  RETURN QUERY SELECT p_commande_id, 'annulee'::TEXT;
END;
$$;

-- ===============================================
-- 9) Workflow livraison: confirmation de fin côté livreur
-- ===============================================
CREATE OR REPLACE FUNCTION terminer_livraison_livreur(
  p_livraison_id UUID
)
RETURNS TABLE (livraison_id UUID, statut TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rows_updated INT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifié';
  END IF;

  UPDATE livraisons
  SET
    statut = 'livree',
    updated_at = NOW()
  WHERE id = p_livraison_id
    AND livreur_id = auth.uid()
    AND statut IN ('acceptee', 'en_cours');

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
  IF v_rows_updated = 0 THEN
    RAISE EXCEPTION 'Finalisation impossible: livraison introuvable ou statut incompatible';
  END IF;

  RETURN QUERY SELECT p_livraison_id, 'livree'::TEXT;
END;
$$;



-- ===============================================
-- 10) Workflow livraison: démarrer la course côté livreur
-- ===============================================
CREATE OR REPLACE FUNCTION demarrer_livraison_livreur(
  p_livraison_id UUID
)
RETURNS TABLE (livraison_id UUID, statut TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rows_updated INT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifié';
  END IF;

  UPDATE livraisons
  SET
    statut = 'en_cours',
    updated_at = NOW()
  WHERE id = p_livraison_id
    AND livreur_id = auth.uid()
    AND statut = 'acceptee';

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
  IF v_rows_updated = 0 THEN
    RAISE EXCEPTION 'Démarrage impossible: livraison introuvable ou statut incompatible';
  END IF;

  RETURN QUERY SELECT p_livraison_id, 'en_cours'::TEXT;
END;
$$;

-- ===============================================
-- 11) Workflow livraison: annulation côté client
-- ===============================================
CREATE OR REPLACE FUNCTION annuler_livraison_client(
  p_livraison_id UUID
)
RETURNS TABLE (livraison_id UUID, statut TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rows_updated INT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifié';
  END IF;

  UPDATE livraisons
  SET
    statut = 'annulee',
    updated_at = NOW()
  WHERE id = p_livraison_id
    AND client_id = auth.uid()
    AND statut IN ('en_attente', 'acceptee');

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
  IF v_rows_updated = 0 THEN
    RAISE EXCEPTION 'Annulation impossible: livraison introuvable ou statut incompatible';
  END IF;

  RETURN QUERY SELECT p_livraison_id, 'annulee'::TEXT;
END;
$$;

-- ===============================================
-- 12) Workflow fournisseurs: créer une demande (7 jours)
-- ===============================================
CREATE OR REPLACE FUNCTION creer_demande_fournisseur(
  p_produit_recherche TEXT,
  p_quantite INTEGER,
  p_budget INTEGER,
  p_ville TEXT,
  p_pays TEXT,
  p_livraison_ville TEXT,
  p_details TEXT,
  p_transaction_id UUID DEFAULT NULL
)
RETURNS TABLE (demande_id UUID, expire_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_vendeur_id UUID;
  v_demande_id UUID;
  v_expire_at TIMESTAMPTZ := NOW() + INTERVAL '7 days';
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifié';
  END IF;

  SELECT id
  INTO v_vendeur_id
  FROM vendeurs
  WHERE id = auth.uid();

  IF v_vendeur_id IS NULL THEN
    RAISE EXCEPTION 'Profil vendeur introuvable';
  END IF;

  IF COALESCE(NULLIF(TRIM(p_produit_recherche), ''), '') = '' THEN
    RAISE EXCEPTION 'Produit recherché obligatoire';
  END IF;

  IF p_quantite IS NOT NULL AND p_quantite <= 0 THEN
    RAISE EXCEPTION 'Quantité invalide';
  END IF;

  IF p_budget IS NOT NULL AND p_budget <= 0 THEN
    RAISE EXCEPTION 'Budget invalide';
  END IF;

  IF p_transaction_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1
      FROM transactions t
      WHERE t.id = p_transaction_id
        AND t.user_id = auth.uid()
        AND t.type_transaction = 'fournisseur'
    ) THEN
      RAISE EXCEPTION 'Transaction fournisseur invalide';
    END IF;
  END IF;

  INSERT INTO demandes_fournisseurs (
    demandeur_id,
    transaction_id,
    produit_recherche,
    quantite,
    budget,
    ville,
    pays,
    livraison_ville,
    details,
    active,
    expire_at
  ) VALUES (
    v_vendeur_id,
    p_transaction_id,
    TRIM(p_produit_recherche),
    p_quantite,
    p_budget,
    NULLIF(TRIM(p_ville), ''),
    NULLIF(TRIM(p_pays), ''),
    NULLIF(TRIM(p_livraison_ville), ''),
    NULLIF(TRIM(p_details), ''),
    TRUE,
    v_expire_at
  )
  RETURNING id INTO v_demande_id;

  RETURN QUERY SELECT v_demande_id, v_expire_at;
END;
$$;

-- ===============================================
-- 13) Workflow fournisseurs: répondre à une demande active
-- ===============================================
CREATE OR REPLACE FUNCTION repondre_demande_fournisseur(
  p_demande_id UUID,
  p_message TEXT,
  p_prix_propose INTEGER DEFAULT NULL
)
RETURNS TABLE (reponse_id UUID, conversation_id UUID)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_demandeur_id UUID;
  v_expire_at TIMESTAMPTZ;
  v_active BOOLEAN;
  v_reponse_id UUID;
  v_conversation_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifié';
  END IF;

  IF COALESCE(NULLIF(TRIM(p_message), ''), '') = '' THEN
    RAISE EXCEPTION 'Message obligatoire';
  END IF;

  IF p_prix_propose IS NOT NULL AND p_prix_propose <= 0 THEN
    RAISE EXCEPTION 'Prix proposé invalide';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM vendeurs WHERE id = auth.uid()) THEN
    RAISE EXCEPTION 'Profil vendeur introuvable';
  END IF;

  SELECT demandeur_id, expire_at, active
  INTO v_demandeur_id, v_expire_at, v_active
  FROM demandes_fournisseurs
  WHERE id = p_demande_id
  FOR UPDATE;

  IF v_demandeur_id IS NULL THEN
    RAISE EXCEPTION 'Demande fournisseur introuvable';
  END IF;

  IF auth.uid() = v_demandeur_id THEN
    RAISE EXCEPTION 'Le demandeur ne peut pas répondre à sa propre demande';
  END IF;

  IF v_active IS DISTINCT FROM TRUE OR v_expire_at <= NOW() THEN
    RAISE EXCEPTION 'Demande non active ou expirée';
  END IF;

  INSERT INTO reponses_fournisseurs (
    demande_id,
    fournisseur_id,
    message,
    prix_propose
  ) VALUES (
    p_demande_id,
    auth.uid(),
    TRIM(p_message),
    p_prix_propose
  )
  ON CONFLICT (demande_id, fournisseur_id)
  DO UPDATE SET
    message = EXCLUDED.message,
    prix_propose = EXCLUDED.prix_propose,
    created_at = NOW()
  RETURNING id INTO v_reponse_id;

  v_conversation_id := get_or_create_conversation(
    'fournisseur',
    p_demande_id::TEXT,
    v_demandeur_id,
    auth.uid(),
    'Fournisseur #' || p_demande_id::TEXT
  );

  RETURN QUERY SELECT v_reponse_id, v_conversation_id;
END;
$$;

-- ===============================================
-- 14) Workflow fournisseurs: clôture d'une demande par le demandeur
-- ===============================================
CREATE OR REPLACE FUNCTION cloturer_demande_fournisseur(
  p_demande_id UUID
)
RETURNS TABLE (demande_id UUID, active BOOLEAN)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rows_updated INT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifié';
  END IF;

  UPDATE demandes_fournisseurs
  SET active = FALSE
  WHERE id = p_demande_id
    AND demandeur_id = auth.uid()
    AND active = TRUE;

  GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
  IF v_rows_updated = 0 THEN
    RAISE EXCEPTION 'Clôture impossible: demande introuvable ou déjà inactive';
  END IF;

  RETURN QUERY SELECT p_demande_id, FALSE;
END;
$$;

-- ===============================================
-- 15) Workflow fournisseurs: désactiver ses demandes expirées
-- ===============================================
CREATE OR REPLACE FUNCTION desactiver_demandes_fournisseur_expirees()
RETURNS TABLE (demande_id UUID)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifié';
  END IF;

  RETURN QUERY
  UPDATE demandes_fournisseurs
  SET active = FALSE
  WHERE demandeur_id = auth.uid()
    AND active = TRUE
    AND expire_at <= NOW()
  RETURNING id;
END;
$$;

-- ===============================================
-- 16) Workflow messagerie: envoyer un message conversation
-- ===============================================
CREATE OR REPLACE FUNCTION envoyer_message_conversation(
  p_conversation_id UUID,
  p_contenu TEXT
)
RETURNS TABLE (message_id UUID, conversation_id UUID, created_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_message_id UUID;
  v_created_at TIMESTAMPTZ;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Utilisateur non authentifié';
  END IF;

  IF COALESCE(NULLIF(TRIM(p_contenu), ''), '') = '' THEN
    RAISE EXCEPTION 'Message vide interdit';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM conversations c
    WHERE c.id = p_conversation_id
      AND (c.participant_a = auth.uid() OR c.participant_b = auth.uid())
  ) THEN
    RAISE EXCEPTION 'Conversation introuvable ou accès non autorisé';
  END IF;

  INSERT INTO messages (conversation_id, expediteur_id, contenu)
  VALUES (p_conversation_id, auth.uid(), TRIM(p_contenu))
  RETURNING id, created_at INTO v_message_id, v_created_at;

  UPDATE conversations
  SET updated_at = NOW()
  WHERE id = p_conversation_id;

  RETURN QUERY SELECT v_message_id, p_conversation_id, v_created_at;
END;
$$;

-- ===============================================
-- 17) Sécurité exécution RPC (principe du moindre privilège)
-- ===============================================
REVOKE ALL ON FUNCTION get_or_create_conversation(TEXT, TEXT, UUID, UUID, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION accepter_commande_vendeur(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION expedier_commande_vendeur(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION confirmer_livraison_commande_client(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION prendre_livraison(UUID, INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION placer_offre_enchere(UUID, INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION cloturer_enchere(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION cloturer_encheres_expirees_vendeur() FROM PUBLIC;
REVOKE ALL ON FUNCTION creer_commande_avec_lignes(TEXT, JSONB) FROM PUBLIC;
REVOKE ALL ON FUNCTION annuler_commande_client(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION terminer_livraison_livreur(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION demarrer_livraison_livreur(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION annuler_livraison_client(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION creer_demande_fournisseur(TEXT, INTEGER, INTEGER, TEXT, TEXT, TEXT, TEXT, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION repondre_demande_fournisseur(UUID, TEXT, INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION cloturer_demande_fournisseur(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION desactiver_demandes_fournisseur_expirees() FROM PUBLIC;
REVOKE ALL ON FUNCTION envoyer_message_conversation(UUID, TEXT) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION get_or_create_conversation(TEXT, TEXT, UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION accepter_commande_vendeur(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION expedier_commande_vendeur(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION confirmer_livraison_commande_client(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION prendre_livraison(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION placer_offre_enchere(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION cloturer_enchere(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION cloturer_encheres_expirees_vendeur() TO authenticated;
GRANT EXECUTE ON FUNCTION creer_commande_avec_lignes(TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION annuler_commande_client(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION terminer_livraison_livreur(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION demarrer_livraison_livreur(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION annuler_livraison_client(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION creer_demande_fournisseur(TEXT, INTEGER, INTEGER, TEXT, TEXT, TEXT, TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION repondre_demande_fournisseur(UUID, TEXT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION cloturer_demande_fournisseur(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION desactiver_demandes_fournisseur_expirees() TO authenticated;
GRANT EXECUTE ON FUNCTION envoyer_message_conversation(UUID, TEXT) TO authenticated;
