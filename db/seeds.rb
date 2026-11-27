# Données de démonstration de la V2.
#
# Les personnes et les domaines tiers ne sont plus créés à la main : on importe les
# mails du jeu Kelenn Conseil, comme le ferait un import automatique, puis on valide une
# partie de ce que l'outil a découvert. Le reste est laissé « à valider » pour que les
# écrans de paramètres aient de quoi montrer.
#
# Les catégories et les statuts se gèrent dans Paramètres → Réglages de l'IA : le seed ne les
# efface pas et ne crée que ceux qui manquent, pour qu'une installation neuve fonctionne.

# En production, on refuse de tout effacer sans autorisation explicite
if Rails.env.production? && ENV["RESET_SEED"] != "1"
  abort "Seed bloquée en production : elle efface toutes les données. " \
        "Relance avec RESET_SEED=1 si c'est voulu."
end

puts "Suppression des données existantes…"
# Les catégories et statuts (Paramètres → Réglages de l'IA) ne sont pas effacés :
# ce qui a été saisi dans l'interface est conservé.
[EmailParticipant, Email, CompanySummary, Conversation, Contact, Company, Employee,
 Prompt, Setting].each(&:delete_all)

puts "Création des données de démonstration…"

User.find_or_create_by!(email: "test@filrouge.fr") { |u| u.password = "password" }

Setting.create!(org_domain: "kelenn-conseil.example", org_name: "Kelenn Conseil")

# Catégories et statuts par défaut, créés seulement s'il n'y en a aucun
if Status.none?
  [
    ["Urgent", "Une échéance tombe dans les 48 heures, ou il manque une pièce qui bloque le dossier."],
    ["En attente d'action", "Le dernier message demande quelque chose à mon domaine : une vérification, une validation, un envoi."],
    ["En attente de réponse", "Mon domaine a fait sa part ; on attend un retour du domaine tiers."],
    ["Information", "Aucune action attendue : confirmation, accusé de réception, simple partage d'information."]
  ].each_with_index { |(name, description), i| Status.create!(name: name, description: description, rank: i + 1) }
end

if Category.none?
  [
    ["Recrutement", "Offres d'emploi, candidatures, entretiens, promesses d'embauche et intégration des nouveaux salariés."],
    ["Facturation", "Factures émises ou reçues, devis, relances de paiement, avoirs et litiges sur un montant."],
    ["Formation", "Inscriptions, plans de développement des compétences, entretiens annuels, prises en charge par l'OPCO."],
    ["Budget et paie", "Préparation et suivi budgétaire, bulletins de paie, variables du mois, charges sociales."],
    ["Juridique", "Contrats, avenants, contentieux, mises en demeure et questions de conformité réglementaire."]
  ].each_with_index { |(name, description), i| Category.create!(name: name, description: description, position: i) }
end

Prompt.create!(name: "Prompt par défaut", is_default: true,
               content: "Tu assistes une personne qui doit garder une vue d'ensemble des échanges par mail " \
                        "circulant dans plusieurs boîtes mail. Elle n'a pas le temps de lire chaque mail : " \
                        "pour chacun, elle veut savoir en quelques secondes de quoi il s'agit, dans quelle " \
                        "catégorie il se range et à quel point il est urgent.")

rh = Prompt.create!(name: "Accompagnement RH",
                    content: "Mets en avant les sujets de recrutement, de paie et de formation. Pour chaque fil, indique l'action attendue du cabinet et son échéance.")
Prompt.create!(name: "Suivi comptable TPE",
               content: "Liste les pièces comptables reçues et celles qui manquent. Signale tout écart entre un montant annoncé dans le mail et celui d'une pièce jointe.")

# Import des mails, comme le ferait un import automatique
paths = Dir.glob(Rails.root.join("db/seeds/emails/kelenn_conseil/**/*.eml")).sort
results = EmailImporter.import_files(paths)
puts "  #{results.count { |r| r.status == :imported }} mails importés, " \
     "#{results.count { |r| r.status == :duplicate }} doublons, #{results.count { |r| r.status == :failed }} en erreur."
paths.zip(results).select { |_, r| r.status == :failed }.each { |path, r| puts "  ✗ #{File.basename(path)} : #{r.error}" }

# Validation d'une partie de ce que l'outil a découvert

Company.where(domain: %w[transports-morvan.fr menuiserie-hamon.fr clinique-des-pins.fr])
       .update_all(state: "validated", prompt_id: rh.id)

Contact.where(email: %w[claire.dubois@transports-morvan.fr marc.morvan@transports-morvan.fr
                        j.hamon@menuiserie-hamon.fr h.marchand@clinique-des-pins.fr]).update_all(state: "validated")

# Jeu de démonstration supplémentaire (db/seeds/emails/kelenn_conseil/demo) : quatre autres
# domaines tiers validés avec leurs correspondants ; l'Épicerie Ty Douar reste « à valider ».
# Noms et domaines inventés, en .example, pour ne rien attribuer à une vraie entreprise.
Company.where(domain: %w[hotel-des-trois-goelands.example pharmacie-du-quai-vert.example
                         garage-des-rochers-bleus.example ateliers-du-grand-lavoir.example])
       .update_all(state: "validated")
Contact.where(email: %w[d.roux@clinique-des-pins.fr g.lefloch@hotel-des-trois-goelands.example
                        compta@hotel-des-trois-goelands.example as.kerbrat@pharmacie-du-quai-vert.example
                        erwan@garage-des-rochers-bleus.example s.quemener@ateliers-du-grand-lavoir.example])
       .update_all(state: "validated")

puts "Terminé : #{Employee.count} collaborateurs, #{Company.count} domaines tiers, #{Contact.count} correspondants, " \
     "#{Conversation.count} fils, #{Email.count} mails."
puts "À valider : #{Company.pending.count} domaines tiers, #{Contact.pending.count} correspondants."
puts "Aucune synthèse n'est créée : l'IA les rédige. En production, une tâche planifiée analyse les fils " \
     "toutes les 15 minutes ; en local, lancez bin/rails fil_rouge:analyser (clé OpenAI dans .env)."
puts "Connexion : test@filrouge.fr / password"
