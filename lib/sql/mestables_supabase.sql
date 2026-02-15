-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.abonnements (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  boutique_id uuid,
  montant integer NOT NULL,
  moyen_paiement text NOT NULL,
  statut text NOT NULL DEFAULT 'en_attente'::text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT abonnements_pkey PRIMARY KEY (id),
  CONSTRAINT abonnements_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT abonnements_boutique_id_fkey FOREIGN KEY (boutique_id) REFERENCES public.vendeurs(id)
);
CREATE TABLE public.annonces (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  titre text,
  image_url text NOT NULL,
  lien_type text,
  lien_valeur text,
  ordre integer DEFAULT 0,
  active boolean DEFAULT true,
  date_debut timestamp without time zone,
  date_fin timestamp without time zone,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT annonces_pkey PRIMARY KEY (id)
);
CREATE TABLE public.boost_historique (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  produit_id uuid,
  transaction_id text NOT NULL,
  duree_jours integer NOT NULL,
  montant integer NOT NULL,
  base_calcul timestamp with time zone NOT NULL,
  expire_at timestamp with time zone NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT boost_historique_pkey PRIMARY KEY (id),
  CONSTRAINT boost_historique_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES public.produits(id)
);
CREATE TABLE public.categories (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  icone text NOT NULL,
  actif boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  parent_id uuid,
  nom text,
  CONSTRAINT categories_pkey PRIMARY KEY (id),
  CONSTRAINT categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.categories(id)
);
CREATE TABLE public.commande_lignes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  commande_id uuid NOT NULL,
  produit_id uuid NOT NULL,
  vendeur_id uuid NOT NULL,
  nom text NOT NULL,
  prix_unitaire integer NOT NULL,
  quantite integer NOT NULL DEFAULT 1,
  taille text,
  couleur text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT commande_lignes_pkey PRIMARY KEY (id),
  CONSTRAINT commande_lignes_commande_id_fkey FOREIGN KEY (commande_id) REFERENCES public.commandes(id),
  CONSTRAINT commande_lignes_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES public.produits(id),
  CONSTRAINT commande_lignes_vendeur_id_fkey FOREIGN KEY (vendeur_id) REFERENCES public.vendeurs(id)
);
CREATE TABLE public.commandes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  client_id uuid NOT NULL,
  total integer NOT NULL,
  statut text NOT NULL DEFAULT 'en_attente'::text CHECK (statut = ANY (ARRAY['en_attente'::text, 'en_preparation'::text, 'expediee'::text, 'livree'::text, 'annulee'::text])),
  adresse_texte text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT commandes_pkey PRIMARY KEY (id),
  CONSTRAINT commandes_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.users(id)
);
CREATE TABLE public.conversations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  canal text NOT NULL CHECK (canal = ANY (ARRAY['commande'::text, 'enchere'::text, 'fournisseur'::text, 'livraison'::text])),
  ref_id text NOT NULL,
  participant_a uuid NOT NULL,
  participant_b uuid NOT NULL,
  titre text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT conversations_pkey PRIMARY KEY (id),
  CONSTRAINT conversations_participant_a_fkey FOREIGN KEY (participant_a) REFERENCES auth.users(id),
  CONSTRAINT conversations_participant_b_fkey FOREIGN KEY (participant_b) REFERENCES auth.users(id)
);
CREATE TABLE public.demandes_fournisseurs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  demandeur_id uuid NOT NULL,
  transaction_id uuid,
  produit_recherche text NOT NULL,
  quantite integer,
  budget integer,
  ville text,
  pays text,
  livraison_ville text,
  details text,
  active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  expire_at timestamp with time zone NOT NULL,
  CONSTRAINT demandes_fournisseurs_pkey PRIMARY KEY (id),
  CONSTRAINT demandes_fournisseurs_demandeur_id_fkey FOREIGN KEY (demandeur_id) REFERENCES public.vendeurs(id),
  CONSTRAINT demandes_fournisseurs_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transactions(id)
);
CREATE TABLE public.encheres (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  vendeur_id uuid NOT NULL,
  titre text NOT NULL,
  description text,
  lot_texte text NOT NULL,
  quantite integer NOT NULL DEFAULT 1,
  prix_depart integer NOT NULL,
  duree_type text NOT NULL CHECK (duree_type = ANY (ARRAY['1h'::text, '6h'::text, '24h'::text, '3j'::text, '7j'::text])),
  date_fin timestamp with time zone NOT NULL,
  statut text NOT NULL DEFAULT 'en_cours'::text CHECK (statut = ANY (ARRAY['en_cours'::text, 'termine'::text, 'annule'::text])),
  gagnant_id uuid,
  meilleure_offre_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT encheres_pkey PRIMARY KEY (id),
  CONSTRAINT encheres_vendeur_id_fkey FOREIGN KEY (vendeur_id) REFERENCES public.vendeurs(id),
  CONSTRAINT encheres_gagnant_id_fkey FOREIGN KEY (gagnant_id) REFERENCES auth.users(id)
);
CREATE TABLE public.encheres_offres (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  enchere_id uuid NOT NULL,
  acheteur_id uuid NOT NULL,
  montant integer NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT encheres_offres_pkey PRIMARY KEY (id),
  CONSTRAINT encheres_offres_enchere_id_fkey FOREIGN KEY (enchere_id) REFERENCES public.encheres(id),
  CONSTRAINT encheres_offres_acheteur_id_fkey FOREIGN KEY (acheteur_id) REFERENCES auth.users(id)
);
CREATE TABLE public.livraison_packs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  livreur_id uuid NOT NULL,
  transaction_id uuid,
  total integer NOT NULL,
  restant integer NOT NULL,
  type_pack text NOT NULL CHECK (type_pack = ANY (ARRAY['gratuit'::text, 'pack10'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT livraison_packs_pkey PRIMARY KEY (id),
  CONSTRAINT livraison_packs_livreur_id_fkey FOREIGN KEY (livreur_id) REFERENCES public.livreurs(id),
  CONSTRAINT livraison_packs_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transactions(id)
);
CREATE TABLE public.livraisons (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  client_id uuid NOT NULL,
  vendeur_id uuid,
  livreur_id uuid,
  statut text NOT NULL DEFAULT 'en_attente'::text CHECK (statut = ANY (ARRAY['en_attente'::text, 'acceptee'::text, 'en_cours'::text, 'livree'::text, 'annulee'::text])),
  prix_livraison integer,
  commission integer NOT NULL DEFAULT 100,
  demande_speciale boolean NOT NULL DEFAULT false,
  frais_demande_speciale integer NOT NULL DEFAULT 25,
  depart_texte text,
  arrivee_texte text,
  depart_latitude numeric,
  depart_longitude numeric,
  arrivee_latitude numeric,
  arrivee_longitude numeric,
  note_client integer,
  commentaire_client text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT livraisons_pkey PRIMARY KEY (id),
  CONSTRAINT livraisons_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.users(id),
  CONSTRAINT livraisons_vendeur_id_fkey FOREIGN KEY (vendeur_id) REFERENCES public.vendeurs(id),
  CONSTRAINT livraisons_livreur_id_fkey FOREIGN KEY (livreur_id) REFERENCES public.livreurs(id)
);
CREATE TABLE public.livreurs (
  id uuid NOT NULL,
  nom_complet text NOT NULL,
  telephone text NOT NULL,
  type_vehicule text CHECK (type_vehicule = ANY (ARRAY['moto'::text, 'voiture'::text, 'velo'::text])),
  est_disponible boolean DEFAULT true,
  est_verifie boolean DEFAULT false,
  est_suspendu boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT livreurs_pkey PRIMARY KEY (id),
  CONSTRAINT livreurs_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.messages (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL,
  expediteur_id uuid NOT NULL,
  contenu text NOT NULL,
  lu boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT messages_pkey PRIMARY KEY (id),
  CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id),
  CONSTRAINT messages_expediteur_id_fkey FOREIGN KEY (expediteur_id) REFERENCES auth.users(id)
);
CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  titre text NOT NULL,
  message text NOT NULL,
  type text NOT NULL CHECK (type = ANY (ARRAY['info'::text, 'succes'::text, 'avertissement'::text, 'erreur'::text, 'paiement'::text, 'boost'::text, 'abonnement'::text])),
  lien_type text CHECK (lien_type = ANY (ARRAY['vendeur'::text, 'produit'::text, 'transaction'::text])),
  lien_id uuid,
  est_lu boolean DEFAULT false,
  date_creation timestamp with time zone DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.produit_couleurs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  produit_id uuid NOT NULL,
  nom text NOT NULL,
  code_hex text,
  stock integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT produit_couleurs_pkey PRIMARY KEY (id),
  CONSTRAINT produit_couleurs_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES public.produits(id)
);
CREATE TABLE public.produit_favoris (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  produit_id uuid NOT NULL,
  utilisateur_id uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT produit_favoris_pkey PRIMARY KEY (id),
  CONSTRAINT produit_favoris_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES public.produits(id),
  CONSTRAINT produit_favoris_utilisateur_id_fkey FOREIGN KEY (utilisateur_id) REFERENCES auth.users(id)
);
CREATE TABLE public.produit_images (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  produit_id uuid NOT NULL,
  url text NOT NULL,
  ordre integer DEFAULT 0,
  CONSTRAINT produit_images_pkey PRIMARY KEY (id),
  CONSTRAINT produit_images_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES public.produits(id)
);
CREATE TABLE public.produit_rates (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  produit_id uuid NOT NULL,
  utilisateur_id uuid NOT NULL,
  note integer NOT NULL CHECK (note >= 1 AND note <= 5),
  commentaire text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT produit_rates_pkey PRIMARY KEY (id),
  CONSTRAINT produit_rates_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES public.produits(id),
  CONSTRAINT produit_rates_utilisateur_id_fkey FOREIGN KEY (utilisateur_id) REFERENCES auth.users(id)
);
CREATE TABLE public.produit_tailles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  produit_id uuid NOT NULL,
  valeur text NOT NULL,
  stock integer DEFAULT 0,
  CONSTRAINT produit_tailles_pkey PRIMARY KEY (id),
  CONSTRAINT produit_tailles_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES public.produits(id)
);
CREATE TABLE public.produit_variantes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  produit_id uuid NOT NULL,
  taille_id uuid,
  couleur_id uuid,
  sku text,
  stock integer DEFAULT 0,
  prix_ajuste integer,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT produit_variantes_pkey PRIMARY KEY (id),
  CONSTRAINT produit_variantes_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES public.produits(id),
  CONSTRAINT produit_variantes_taille_id_fkey FOREIGN KEY (taille_id) REFERENCES public.produit_tailles(id),
  CONSTRAINT produit_variantes_couleur_id_fkey FOREIGN KEY (couleur_id) REFERENCES public.produit_couleurs(id)
);
CREATE TABLE public.produits (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  vendeur_id uuid,
  categorie_id uuid NOT NULL,
  nom text NOT NULL,
  description text,
  prix integer NOT NULL,
  note numeric DEFAULT 0,
  stock_global integer,
  actif boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  est_top boolean DEFAULT false,
  ordre_top integer DEFAULT 0,
  etat_produit text NOT NULL DEFAULT 'neuf'::text CHECK (etat_produit = ANY (ARRAY['neuf'::text, 'occasion'::text])),
  livraison_disponible boolean NOT NULL DEFAULT false,
  nombre_vues integer DEFAULT 0,
  nombre_ventes integer DEFAULT 0,
  poids numeric,
  marque text,
  updated_at timestamp with time zone DEFAULT now(),
  est_booste boolean DEFAULT false,
  date_expiration_boost timestamp with time zone,
  nombre_partages integer DEFAULT 0,
  boost_actif boolean DEFAULT false,
  boost_expire_at timestamp with time zone,
  CONSTRAINT produits_pkey PRIMARY KEY (id),
  CONSTRAINT produits_categorie_id_fkey FOREIGN KEY (categorie_id) REFERENCES public.categories(id),
  CONSTRAINT produits_vendeur_id_fkey FOREIGN KEY (vendeur_id) REFERENCES public.vendeurs(id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  language text,
  theme text,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.promos (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  titre text NOT NULL,
  description text,
  type_promo text NOT NULL CHECK (type_promo = ANY (ARRAY['pourcentage'::text, 'montant'::text])),
  valeur numeric NOT NULL CHECK (valeur > 0::numeric),
  produit_id uuid,
  categorie_id uuid,
  date_debut timestamp with time zone NOT NULL,
  date_fin timestamp with time zone NOT NULL,
  actif boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT promos_pkey PRIMARY KEY (id),
  CONSTRAINT promos_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES public.produits(id),
  CONSTRAINT promos_categorie_id_fkey FOREIGN KEY (categorie_id) REFERENCES public.categories(id)
);
CREATE TABLE public.reponses_fournisseurs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  demande_id uuid NOT NULL,
  fournisseur_id uuid NOT NULL,
  message text NOT NULL,
  prix_propose integer,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT reponses_fournisseurs_pkey PRIMARY KEY (id),
  CONSTRAINT reponses_fournisseurs_demande_id_fkey FOREIGN KEY (demande_id) REFERENCES public.demandes_fournisseurs(id),
  CONSTRAINT reponses_fournisseurs_fournisseur_id_fkey FOREIGN KEY (fournisseur_id) REFERENCES public.vendeurs(id)
);
CREATE TABLE public.statistiques_produits (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  produit_id uuid NOT NULL,
  date date NOT NULL DEFAULT CURRENT_DATE,
  nombre_vues integer DEFAULT 0,
  nombre_clics integer DEFAULT 0,
  nombre_partages integer DEFAULT 0,
  nombre_favoris integer DEFAULT 0,
  CONSTRAINT statistiques_produits_pkey PRIMARY KEY (id),
  CONSTRAINT statistiques_produits_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES public.produits(id)
);
CREATE TABLE public.statistiques_vendeurs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  vendeur_id uuid NOT NULL,
  date date NOT NULL DEFAULT CURRENT_DATE,
  nombre_visites integer DEFAULT 0,
  nombre_vues_produits integer DEFAULT 0,
  nombre_commandes integer DEFAULT 0,
  chiffre_affaires integer DEFAULT 0,
  CONSTRAINT statistiques_vendeurs_pkey PRIMARY KEY (id),
  CONSTRAINT statistiques_vendeurs_vendeur_id_fkey FOREIGN KEY (vendeur_id) REFERENCES public.vendeurs(id)
);
CREATE TABLE public.super_admins (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  peut_tout_voir boolean DEFAULT true,
  peut_modifier boolean DEFAULT true,
  peut_supprimer boolean DEFAULT false,
  date_ajout timestamp with time zone DEFAULT now(),
  CONSTRAINT super_admins_pkey PRIMARY KEY (id),
  CONSTRAINT super_admins_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.transactions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  vendeur_id uuid,
  produit_id uuid,
  methode_paiement text NOT NULL CHECK (methode_paiement = ANY (ARRAY['tmoney'::text, 'flooz'::text])),
  numero_telephone text NOT NULL,
  montant integer NOT NULL CHECK (montant > 0),
  type_transaction text NOT NULL CHECK (type_transaction = ANY (ARRAY['abonnement'::text, 'boost'::text])),
  type_abonnement text CHECK (type_abonnement = ANY (ARRAY['gratuit'::text, 'premium'::text, 'entreprise'::text])),
  statut text NOT NULL DEFAULT 'en_attente'::text CHECK (statut = ANY (ARRAY['en_attente'::text, 'en_cours'::text, 'valide'::text, 'echoue'::text, 'annule'::text])),
  reference_externe text,
  date_creation timestamp with time zone DEFAULT now(),
  date_validation timestamp with time zone,
  CONSTRAINT transactions_pkey PRIMARY KEY (id),
  CONSTRAINT transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT transactions_vendeur_id_fkey FOREIGN KEY (vendeur_id) REFERENCES public.vendeurs(id),
  CONSTRAINT transactions_produit_id_fkey FOREIGN KEY (produit_id) REFERENCES public.produits(id)
);
CREATE TABLE public.vendeurs (
  id uuid NOT NULL,
  nom_boutique text NOT NULL,
  description text,
  telephone text,
  est_verifie boolean DEFAULT false,
  est_suspendu boolean DEFAULT false,
  type_abonnement text DEFAULT 'gratuit'::text CHECK (type_abonnement = ANY (ARRAY['gratuit'::text, 'premium'::text])),
  date_expiration_abonnement timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  pays text,
  ville text,
  quartier text,
  latitude numeric,
  longitude numeric,
  logo_url text,
  CONSTRAINT vendeurs_pkey PRIMARY KEY (id),
  CONSTRAINT vendeurs_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);