# SAME Shop

Marketplace mobile en Flutter + Supabase : catalogue, boutiques, enchères, recherche de fournisseurs, messagerie et livraisons.

## Rôles

- Client acheteur
- Vendeur (particulier ou entreprise)
- Livreur
- Administrateur

## Stack

| Couche | Techno |
|---|---|
| App | Flutter (Material 3), français et anglais, thèmes clair et sombre |
| Backend | Supabase : Auth (OTP par email et SMS), Postgres, Realtime, Storage |
| Cartes | flutter_map (OpenStreetMap) + geolocator |
| Paiement | CinetPay, T-Money, Flooz : pas encore branchés (clés factices, succès simulé) |
| État | `setState` pour l'instant ; Riverpod est installé, prévu pour le panier |

## Prérequis

- Flutter **3.38.4 ou plus récent** (contrainte du `pubspec.lock`, testé avec 3.38.10)
- Un projet Supabase (le projet cloud aujourd'hui, une instance locale à partir de la phase 1 du plan)

## Lancer l'app

1. Copier `config/example.json` en `config/cloud.json`, puis y mettre l'URL et la clé anon du projet (réglages API du projet dans le dashboard Supabase). Ce fichier est ignoré par git.
2. `flutter pub get`
3. `flutter run --dart-define-from-file=config/cloud.json`, ou dans VS Code la configuration **« same_shop (Supabase cloud) »** (F5).

Sans ce fichier, l'app s'arrête au démarrage avec un message qui explique quoi faire. Même option pour `flutter build apk`.

## Organisation

```text
lib/
├── coeur/            # configuration, services transverses, thèmes, langues
├── partage/          # widgets partagés (routeur d'authentification, en-têtes)
├── fonctionnalites/  # un dossier par module (produits, vendeur, encheres…)
└── sql/              # scripts SQL de référence (voir lib/sql/README.md)
config/               # config Supabase de chaque poste (seul example.json est versionné)
design/               # sources graphiques (.psd), hors des assets de l'app
docs/PLAN.md          # plan pour finir le projet en local
```

## Avancement

Voir [`docs/PLAN.md`](docs/PLAN.md).
