# Fil rouge

Fil rouge présente, jour par jour, la synthèse des échanges de mails entre les collaborateurs d'une organisation et ses clients. Les mails sont importés puis résumés par une IA, à trois niveaux : l'entreprise cliente, chacun de ses contacts et chaque mail.

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

Les mails de test datent du 5 au 24 novembre 2026. Tant qu'aucune synthèse n'a été générée, le dashboard s'ouvre sur la date du jour : choisissez une de ces dates dans la barre de dates, ou ouvrez par exemple http://localhost:3000/?date=2026-11-24.

## Données de test

Le seed lit les mails fictifs rangés en fichiers `.eml` dans `db/seeds/emails/` et crée les collaborateurs, les entreprises, les contacts et 24 mails. Il ne crée volontairement aucune synthèse, pour que le job de synthèse IA puisse être testé sur des données neuves.

```bash
bin/rails db:seed:replant   # vide les tables puis relance le seed
```

Le détail est sur la page [Installation et données de test](https://github.com/PaulineBoullet/fil_rouge/wiki/Installation-et-donnees-de-test).

## Organisation

| Partie | Où regarder |
|---|---|
| Modèles et validations | `app/models/`, [Schéma de la base](https://github.com/PaulineBoullet/fil_rouge/wiki/Schema-de-la-base) |
| Routes | `config/routes.rb`, [User stories et routes](https://github.com/PaulineBoullet/fil_rouge/wiki/User-stories-et-routes) |
| Choix de la date, recherche | `app/controllers/application_controller.rb` |
| Pages de consultation | `pages#dashboard`, `companies#show`, `contacts#show` |
| Fenêtres modale et de confirmation | `app/javascript/controllers/` |
| Styles | `app/assets/stylesheets/components/` |
| Traductions | `config/locales/fr.yml` |

## Pile technique

Rails 8.1, PostgreSQL, Devise, Bootstrap 5.3, Simple Form, Turbo et Stimulus, Solid Queue pour les jobs.
