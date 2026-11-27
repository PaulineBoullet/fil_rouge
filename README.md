# Fil rouge

Fil rouge présente, jour par jour, les échanges de mails entre les collaborateurs d'une organisation et ses domaines tiers (clients, fournisseurs, partenaires). Les mails sont importés, regroupés en fils de discussion, puis résumés et classés par une IA.

Projet réalisé pendant l'AI Week du bootcamp [Le Wagon](https://www.lewagon.com).

La documentation détaillée est dans le [wiki](https://github.com/PaulineBoullet/fil_rouge/wiki).

## Démarrer

Prérequis : Ruby 3.3.5 et PostgreSQL.

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/dev
```

L'application tourne sur http://localhost:3000. Connectez-vous avec le compte de test `test@filrouge.fr`, mot de passe `password`.

Pour que l'IA rédige les synthèses, ajoutez votre clé dans un fichier `.env` à la racine (il n'est pas versionné) : `OPENAI_API_KEY=...`.

En production, une tâche planifiée (`config/recurring.yml`) fait analyser toutes les 15 minutes les fils qui l'attendent. En local, lancez l'analyse vous-même après le seed :

```bash
bin/rails fil_rouge:analyser
```

Le bouton « Mettre à jour la synthèse » d'un fil fait la même chose pour ce seul fil.

## Données de test

Le seed importe les mails fictifs rangés en fichiers `.eml` dans `db/seeds/emails/kelenn_conseil/`, comme le ferait un import automatique. L'organisation est Kelenn Conseil (`kelenn-conseil.example`). Les fils du 5 au 27 novembre 2026 concernent sept domaines tiers validés ; un huitième reste à valider. Le seed ne crée aucune synthèse : c'est l'IA qui les rédige, avec la priorité, la catégorie et les points clés de chaque fil.

```bash
bin/rails db:seed:replant   # vide les tables puis relance le seed
```

Le détail est sur la page [Installation et données de test](https://github.com/PaulineBoullet/fil_rouge/wiki/Installation-et-donnees-de-test).

## Organisation

| Partie | Où regarder |
|---|---|
| Modèles et validations | `app/models/`, [Schéma de la base](https://github.com/PaulineBoullet/fil_rouge/wiki/Schema-de-la-base) |
| Routes | `config/routes.rb`, [User stories et routes](https://github.com/PaulineBoullet/fil_rouge/wiki/User-stories-et-routes) |
| Import des mails, fils, identification des personnes | `app/services/` (`EmailImporter`, `ConversationResolver`, `AddressResolver`) |
| Requêtes du dashboard, recherche | `app/queries/` |
| Synthèses et classement par l'IA | `app/services/` (`EmailAnalysisService`, `ConversationSummaryService`, `PromptBuilder`) |
| Pages de consultation | `pages#dashboard`, `companies#show`, `conversations#show` |
| Paramètres | `settings`, `companies`, `ai_settings` |
| Styles et échelle typographique | `app/assets/stylesheets/` (tailles dans `config/_fonts.scss`) |
| Traductions | `config/locales/fr.yml` |

## Pile technique

Rails 8.1, PostgreSQL, Devise, Bootstrap 5.3, Simple Form, Turbo et Stimulus, Solid Queue pour les jobs, API OpenAI pour les synthèses.
