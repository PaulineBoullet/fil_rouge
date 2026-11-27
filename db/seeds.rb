# Données de démonstration de la V2.
#
# Les personnes et les domaines tiers ne sont plus créés à la main : on importe les
# mails du jeu Kelenn Conseil, comme le ferait l'import nocturne, puis on valide une
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

# Les classements de démonstration ci-dessous visent ces noms ; un nom renommé ou supprimé
# dans les Paramètres est simplement ignoré.
statuses = Status.all.index_by(&:name)
categories = Category.all.index_by(&:name)

Prompt.create!(name: "Prompt par défaut", is_default: true,
               content: "Tu assistes une personne qui doit garder une vue d'ensemble des échanges par mail " \
                        "circulant dans plusieurs boîtes mail. Elle n'a pas le temps de lire chaque mail : " \
                        "pour chacun, elle veut savoir en quelques secondes de quoi il s'agit, dans quelle " \
                        "catégorie il se range et à quel point il est urgent.")

rh = Prompt.create!(name: "Accompagnement RH",
                    content: "Mets en avant les sujets de recrutement, de paie et de formation. Pour chaque fil, indique l'action attendue du cabinet et son échéance.")
Prompt.create!(name: "Suivi comptable TPE",
               content: "Liste les pièces comptables reçues et celles qui manquent. Signale tout écart entre un montant annoncé dans le mail et celui d'une pièce jointe.")

# Import des mails, comme le ferait l'import nocturne
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
# domaines tiers validés avec leurs correspondants. Biocoop Landerneau reste « à valider ».
Company.where(domain: %w[hotel-les-embruns.fr pharmacie-du-port.fr garage-le-du.fr ateliers-quemener.fr])
       .update_all(state: "validated")
Contact.where(email: %w[d.roux@clinique-des-pins.fr g.lefloch@hotel-les-embruns.fr compta@hotel-les-embruns.fr
                        as.kerbrat@pharmacie-du-port.fr erwan@garage-le-du.fr s.quemener@ateliers-quemener.fr])
       .update_all(state: "validated")

# Statuts et catégories de démonstration, en attendant l'IA
{
  "09_mail_avec_incoherences@fictif.test" => ["Urgent", "Facturation"],
  "tm-03@transports-morvan.fr" => ["En attente d'action", "Recrutement"],
  "04_mail_avec_pdf_texte@fictif.test" => ["En attente d'action", "Budget et paie"],
  "06_mail_avec_word_et_excel@fictif.test" => ["En attente d'action", "Recrutement"],
  "cvp-01@kelenn-conseil.example" => ["En attente de réponse", "Formation"]
}.each do |message_id, (status, category)|
  conversation = Email.find_by(message_id: message_id)&.conversation
  conversation&.update!(status: statuses[status], category: categories[category])
end

# Synthèses, statuts et catégories du jeu de démonstration, comme les rédigerait l'IA
demo = JSON.parse(File.read(Rails.root.join("db/seeds/emails/kelenn_conseil/demo/syntheses.json")))
demo["emails"].each { |message_id, summary| Email.where(message_id: message_id).update_all(summary: summary) }
demo["conversations"].each do |message_id, attrs|
  conversation = Email.find_by(message_id: message_id)&.conversation
  next unless conversation

  conversation.update!(status: statuses[attrs["status"]], category: categories[attrs["category"]],
                       summary: attrs["summary"], summary_generated_at: (attrs["summary"] && Time.zone.parse("2026-11-27 07:00")))
end

puts "Terminé : #{Employee.count} collaborateurs, #{Company.count} domaines tiers, #{Contact.count} correspondants, " \
     "#{Conversation.count} fils, #{Email.count} mails."
puts "À valider : #{Company.pending.count} domaines tiers, #{Contact.pending.count} correspondants."
puts "Connexion : test@filrouge.fr / password"
