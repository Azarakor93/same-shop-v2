# Qu’est-ce qu’un « dossier skill » ?

Un **dossier skill** est un petit module d’instructions réutilisables pour guider l’agent sur une tâche spécifique.

## 1) À quoi sert un skill

Un skill sert à encapsuler :
- un **contexte métier** (ex: comment faire une migration SQL propre),
- un **processus recommandé** (étapes à suivre),
- des **fichiers de référence** (templates, scripts, exemples),
- parfois des **scripts automatisés** à exécuter.

L’objectif : éviter de réinventer la méthode à chaque demande.

## 2) Structure typique d’un dossier skill

Un dossier skill contient généralement :

- `SKILL.md` (**obligatoire** en pratique)
  - Le fichier principal qui explique quand et comment utiliser le skill.
- `references/` (optionnel)
  - Documentation complémentaire ciblée.
- `scripts/` (optionnel)
  - Scripts prêts à exécuter.
- `assets/` ou `templates/` (optionnel)
  - Modèles réutilisables.

Exemple schématique :

```text
my-skill/
  SKILL.md
  references/
    conventions.md
  scripts/
    setup.sh
  templates/
    pr_template.md
```

## 3) Comment reconnaître qu’un lien GitHub est un skill

Un lien GitHub représente un skill si le dossier ciblé contient un `SKILL.md` cohérent.

- ✅ Bon candidat :
  - `https://github.com/<owner>/<repo>/tree/main/skills/sql-hardening`
  - (si `skills/sql-hardening/SKILL.md` existe)
- ❌ Pas un skill (au sens du système de skills) :
  - un dossier applicatif classique comme `lib/`, `src/`, `app/` sans `SKILL.md`.

## 4) Différence entre « code du projet » et « skill »

- **Code projet** (`lib/`, `backend/`, `sql/`, etc.)
  - Produit final livré aux utilisateurs.
- **Skill**
  - Guide opératoire pour l’agent (méthode de travail), pas une feature produit directe.

## 5) Quand utiliser un skill

Tu demandes un skill quand tu veux :
- standardiser une manière de travailler,
- accélérer des tâches répétitives,
- imposer un workflow de qualité (tests, conventions, PR, sécurité).

## 6) Ce qu’il faut me donner pour installer un skill

Pour que je l’installe rapidement, donne :
1. Une URL GitHub vers **le dossier exact** du skill,
2. Vérifie la présence de `SKILL.md` dans ce dossier.

Format recommandé :

```text
https://github.com/<owner>/<repo>/tree/<branch>/<path-vers-skill>
```

Exemple valide :

```text
https://github.com/acme/codex-skills/tree/main/skills/flutter-review
```

(à condition que `skills/flutter-review/SKILL.md` existe).
