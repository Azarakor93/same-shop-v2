create table public.abonnements (
  id uuid not null default gen_random_uuid (),
  user_id uuid null,
  boutique_id uuid null,
  montant integer not null,
  moyen_paiement text not null,
  statut text not null default 'en_attente'::text,
  created_at timestamp with time zone null default now(),
  constraint abonnements_pkey primary key (id),
  constraint abonnements_boutique_id_fkey foreign KEY (boutique_id) references vendeurs (id) on delete CASCADE,
  constraint abonnements_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE
) TABLESPACE pg_default;

create table public.annonces (
  id uuid not null default gen_random_uuid (),
  titre text null,
  image_url text not null,
  lien_type text null,
  lien_valeur text null,
  ordre integer null default 0,
  active boolean null default true,
  date_debut timestamp without time zone null,
  date_fin timestamp without time zone null,
  created_at timestamp without time zone null default now(),
  constraint annonces_pkey primary key (id)
) TABLESPACE pg_default;

create table public.categories (
  id uuid not null default gen_random_uuid (),
  code text not null,
  icone text not null,
  actif boolean null default true,
  created_at timestamp with time zone null default now(),
  parent_id uuid null,
  nom text null,
  constraint categories_pkey primary key (id),
  constraint categories_code_key unique (code),
  constraint categories_parent_id_fkey foreign KEY (parent_id) references categories (id) on delete CASCADE
) TABLESPACE pg_default;

create table public.livreurs (
  id uuid not null,
  nom_complet text not null,
  telephone text not null,
  type_vehicule text null,
  est_disponible boolean null default true,
  est_verifie boolean null default false,
  est_suspendu boolean null default false,
  created_at timestamp with time zone null default now(),
  constraint livreurs_pkey primary key (id),
  constraint livreurs_id_fkey foreign KEY (id) references auth.users (id) on delete CASCADE,
  constraint livreurs_type_vehicule_check check (
    (
      type_vehicule = any (
        array['moto'::text, 'voiture'::text, 'velo'::text]
      )
    )
  )
) TABLESPACE pg_default;

create table public.notifications (
  id uuid not null default gen_random_uuid (),
  user_id uuid not null,
  titre text not null,
  message text not null,
  type text not null,
  lien_type text null,
  lien_id uuid null,
  est_lu boolean null default false,
  date_creation timestamp with time zone null default now(),
  constraint notifications_pkey primary key (id),
  constraint notifications_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE,
  constraint notifications_lien_type_check check (
    (
      lien_type = any (
        array[
          'vendeur'::text,
          'produit'::text,
          'transaction'::text
        ]
      )
    )
  ),
  constraint notifications_type_check check (
    (
      type = any (
        array[
          'info'::text,
          'succes'::text,
          'avertissement'::text,
          'erreur'::text,
          'paiement'::text,
          'boost'::text,
          'abonnement'::text
        ]
      )
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_notifications_user_id on public.notifications using btree (user_id) TABLESPACE pg_default;

create index IF not exists idx_notifications_non_lues on public.notifications using btree (est_lu) TABLESPACE pg_default
where
  (est_lu = false);

  create table public.produit_couleurs (
  id uuid not null default gen_random_uuid (),
  produit_id uuid not null,
  nom text not null,
  code_hex text null,
  stock integer null default 0,
  created_at timestamp with time zone null default now(),
  constraint produit_couleurs_pkey primary key (id),
  constraint produit_couleurs_produit_id_fkey foreign KEY (produit_id) references produits (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_couleurs_produit on public.produit_couleurs using btree (produit_id) TABLESPACE pg_default;

create trigger trigger_update_stock_couleurs
after INSERT
or DELETE
or
update on produit_couleurs for EACH row
execute FUNCTION update_stock_global ();

create table public.produit_favoris (
  id uuid not null default gen_random_uuid (),
  produit_id uuid not null,
  utilisateur_id uuid not null,
  created_at timestamp with time zone null default now(),
  constraint produit_favoris_pkey primary key (id),
  constraint unique_favori_par_utilisateur unique (produit_id, utilisateur_id),
  constraint produit_favoris_produit_id_fkey foreign KEY (produit_id) references produits (id) on delete CASCADE,
  constraint produit_favoris_utilisateur_id_fkey foreign KEY (utilisateur_id) references auth.users (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_favoris_utilisateur on public.produit_favoris using btree (utilisateur_id) TABLESPACE pg_default;

create index IF not exists idx_favoris_produit on public.produit_favoris using btree (produit_id) TABLESPACE pg_default;

create table public.produit_images (
  id uuid not null default gen_random_uuid (),
  produit_id uuid not null,
  url text not null,
  ordre integer null default 0,
  constraint produit_images_pkey primary key (id),
  constraint produit_images_produit_id_fkey foreign KEY (produit_id) references produits (id) on delete CASCADE
) TABLESPACE pg_default;

create table public.produit_rates (
  id uuid not null default gen_random_uuid (),
  produit_id uuid not null,
  utilisateur_id uuid not null,
  note integer not null,
  commentaire text null,
  created_at timestamp with time zone null default now(),
  constraint produit_rates_pkey primary key (id),
  constraint unique_rate_par_utilisateur unique (produit_id, utilisateur_id),
  constraint produit_rates_produit_id_fkey foreign KEY (produit_id) references produits (id) on delete CASCADE,
  constraint produit_rates_utilisateur_id_fkey foreign KEY (utilisateur_id) references auth.users (id) on delete CASCADE,
  constraint produit_rates_note_check check (
    (
      (note >= 1)
      and (note <= 5)
    )
  )
) TABLESPACE pg_default;

create trigger trigger_update_note
after INSERT
or DELETE
or
update on produit_rates for EACH row
execute FUNCTION update_produit_note ();

create table public.produit_tailles (
  id uuid not null default gen_random_uuid (),
  produit_id uuid not null,
  valeur text not null,
  stock integer null default 0,
  constraint produit_tailles_pkey primary key (id),
  constraint produit_tailles_produit_id_fkey foreign KEY (produit_id) references produits (id) on delete CASCADE
) TABLESPACE pg_default;

create trigger trigger_update_stock_tailles
after INSERT
or DELETE
or
update on produit_tailles for EACH row
execute FUNCTION update_stock_global ();

create table public.produit_variantes (
  id uuid not null default gen_random_uuid (),
  produit_id uuid not null,
  taille_id uuid null,
  couleur_id uuid null,
  sku text null,
  stock integer null default 0,
  prix_ajuste integer null,
  created_at timestamp with time zone null default now(),
  constraint produit_variantes_pkey primary key (id),
  constraint unique_variante unique (produit_id, taille_id, couleur_id),
  constraint produit_variantes_couleur_id_fkey foreign KEY (couleur_id) references produit_couleurs (id) on delete set null,
  constraint produit_variantes_produit_id_fkey foreign KEY (produit_id) references produits (id) on delete CASCADE,
  constraint produit_variantes_taille_id_fkey foreign KEY (taille_id) references produit_tailles (id) on delete set null
) TABLESPACE pg_default;

create index IF not exists idx_variantes_produit on public.produit_variantes using btree (produit_id) TABLESPACE pg_default;

create trigger trigger_update_stock_variantes
after INSERT
or DELETE
or
update on produit_variantes for EACH row
execute FUNCTION update_stock_global ();

create table public.produits (
  id uuid not null default gen_random_uuid (),
  vendeur_id uuid null,
  categorie_id uuid not null,
  nom text not null,
  description text null,
  prix integer not null,
  note numeric null default 0,
  stock_global integer null,
  actif boolean null default true,
  created_at timestamp with time zone null default now(),
  est_top boolean null default false,
  ordre_top integer null default 0,
  etat_produit text not null default 'neuf'::text,
  livraison_disponible boolean not null default false,
  nombre_vues integer null default 0,
  nombre_ventes integer null default 0,
  poids numeric(10, 2) null,
  marque text null,
  updated_at timestamp with time zone null default now(),
  est_booste boolean null default false,
  date_expiration_boost timestamp with time zone null,
  nombre_partages integer null default 0,
  constraint produits_pkey primary key (id),
  constraint produits_categorie_id_fkey foreign KEY (categorie_id) references categories (id) on delete CASCADE,
  constraint produits_vendeur_id_fkey foreign KEY (vendeur_id) references vendeurs (id) on delete CASCADE,
  constraint produits_etat_produit_check check (
    (
      etat_produit = any (array['neuf'::text, 'occasion'::text])
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_produits_vendeur on public.produits using btree (vendeur_id) TABLESPACE pg_default
where
  (actif = true);

create index IF not exists idx_produits_categorie on public.produits using btree (categorie_id) TABLESPACE pg_default
where
  (actif = true);

create index IF not exists idx_produits_actifs on public.produits using btree (actif, created_at desc) TABLESPACE pg_default;

create index IF not exists idx_produits_booste on public.produits using btree (est_booste, date_expiration_boost) TABLESPACE pg_default
where
  (est_booste = true);

create trigger check_toggle_before_update BEFORE
update OF actif on produits for EACH row
execute FUNCTION verifier_abonnement_toggle ();

create trigger trigger_produits_updated_at BEFORE
update on produits for EACH row
execute FUNCTION update_updated_at ();

create table public.profiles (
  id uuid not null,
  language text null,
  theme text null,
  updated_at timestamp with time zone null default now(),
  constraint profiles_pkey primary key (id),
  constraint profiles_id_fkey foreign KEY (id) references auth.users (id) on delete CASCADE
) TABLESPACE pg_default;

create table public.promos (
  id uuid not null default gen_random_uuid (),
  titre text not null,
  description text null,
  type_promo text not null,
  valeur numeric not null,
  produit_id uuid null,
  categorie_id uuid null,
  date_debut timestamp with time zone not null,
  date_fin timestamp with time zone not null,
  actif boolean null default true,
  created_at timestamp with time zone null default now(),
  constraint promos_pkey primary key (id),
  constraint promos_categorie_id_fkey foreign KEY (categorie_id) references categories (id) on delete CASCADE,
  constraint promos_produit_id_fkey foreign KEY (produit_id) references produits (id) on delete CASCADE,
  constraint promo_cible_unique check (
    (
      (
        (produit_id is not null)
        and (categorie_id is null)
      )
      or (
        (produit_id is null)
        and (categorie_id is not null)
      )
    )
  ),
  constraint promos_type_promo_check check (
    (
      type_promo = any (array['pourcentage'::text, 'montant'::text])
    )
  ),
  constraint promos_valeur_check check ((valeur > (0)::numeric))
) TABLESPACE pg_default;

create table public.statistiques_produits (
  id uuid not null default gen_random_uuid (),
  produit_id uuid not null,
  date date not null default CURRENT_DATE,
  nombre_vues integer null default 0,
  nombre_clics integer null default 0,
  nombre_partages integer null default 0,
  nombre_favoris integer null default 0,
  constraint statistiques_produits_pkey primary key (id),
  constraint statistiques_produits_unique unique (produit_id, date),
  constraint statistiques_produits_produit_id_fkey foreign KEY (produit_id) references produits (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_statistiques_produits_produit_id on public.statistiques_produits using btree (produit_id) TABLESPACE pg_default;

create index IF not exists idx_statistiques_produits_date on public.statistiques_produits using btree (date desc) TABLESPACE pg_default;

create table public.statistiques_vendeurs (
  id uuid not null default gen_random_uuid (),
  vendeur_id uuid not null,
  date date not null default CURRENT_DATE,
  nombre_visites integer null default 0,
  nombre_vues_produits integer null default 0,
  nombre_commandes integer null default 0,
  chiffre_affaires integer null default 0,
  constraint statistiques_vendeurs_pkey primary key (id),
  constraint statistiques_vendeurs_unique unique (vendeur_id, date),
  constraint statistiques_vendeurs_vendeur_id_fkey foreign KEY (vendeur_id) references vendeurs (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_statistiques_vendeurs_vendeur_id on public.statistiques_vendeurs using btree (vendeur_id) TABLESPACE pg_default;

create index IF not exists idx_statistiques_vendeurs_date on public.statistiques_vendeurs using btree (date desc) TABLESPACE pg_default;

create table public.super_admins (
  id uuid not null default gen_random_uuid (),
  user_id uuid not null,
  peut_tout_voir boolean null default true,
  peut_modifier boolean null default true,
  peut_supprimer boolean null default false,
  date_ajout timestamp with time zone null default now(),
  constraint super_admins_pkey primary key (id),
  constraint super_admins_user_id_key unique (user_id),
  constraint super_admins_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE
) TABLESPACE pg_default;

create table public.transactions (
  id uuid not null default gen_random_uuid (),
  user_id uuid not null,
  vendeur_id uuid null,
  produit_id uuid null,
  methode_paiement text not null,
  numero_telephone text not null,
  montant integer not null,
  type_transaction text not null,
  type_abonnement text null,
  duree_jours integer null,
  statut text not null default 'en_attente'::text,
  reference_externe text null,
  date_creation timestamp with time zone null default now(),
  date_validation timestamp with time zone null,
  constraint transactions_pkey primary key (id),
  constraint transactions_produit_id_fkey foreign KEY (produit_id) references produits (id) on delete set null,
  constraint transactions_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete CASCADE,
  constraint transactions_vendeur_id_fkey foreign KEY (vendeur_id) references vendeurs (id) on delete set null,
  constraint transactions_type_transaction_check check (
    (
      type_transaction = any (array['abonnement'::text, 'boost'::text, 'fournisseur'::text])
    )
  ),
  constraint transactions_statut_check check (
    (
      statut = any (
        array[
          'en_attente'::text,
          'en_cours'::text,
          'valide'::text,
          'echoue'::text,
          'annule'::text
        ]
      )
    )
  ),
  constraint transactions_montant_check check ((montant > 0)),
  constraint transactions_methode_paiement_check check (
    (
      methode_paiement = any (array['tmoney'::text, 'flooz'::text])
    )
  ),
  constraint transactions_type_abonnement_check check (
    (
      type_abonnement = any (
        array[
          'gratuit'::text,
          'premium'::text,
          'entreprise'::text
        ]
      )
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_transactions_user_id on public.transactions using btree (user_id) TABLESPACE pg_default;

create index IF not exists idx_transactions_vendeur_id on public.transactions using btree (vendeur_id) TABLESPACE pg_default;

create index IF not exists idx_transactions_statut on public.transactions using btree (statut) TABLESPACE pg_default;

create index IF not exists idx_transactions_date_creation on public.transactions using btree (date_creation desc) TABLESPACE pg_default;

create table public.vendeurs (
  id uuid not null,
  nom_boutique text not null,
  description text null,
  telephone text null,
  est_verifie boolean null default false,
  est_suspendu boolean null default false,
  type_abonnement text null default 'gratuit'::text,
  date_expiration_abonnement timestamp with time zone null,
  created_at timestamp with time zone null default now(),
  pays text null,
  ville text null,
  quartier text null,
  latitude numeric null,
  longitude numeric null,
  logo_url text null,
  constraint vendeurs_pkey primary key (id),
  constraint vendeurs_id_fkey foreign KEY (id) references auth.users (id) on delete CASCADE,
  constraint vendeurs_type_abonnement_check check (
    (
      type_abonnement = any (array['gratuit'::text, 'premium'::text, 'entreprise'::text])
    )
  )
) TABLESPACE pg_default;
