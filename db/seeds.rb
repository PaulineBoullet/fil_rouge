require "mail"

# Données de test.
# Les mails viennent des kits fournis (fichiers .eml dans db/seeds/emails/).
# Aucune synthèse n'est créée ici : les champs emails.summary, company_summaries
# et contact_summaries doivent être remplis par le job de synthèse IA.

puts "Création des données de test…"

# Compte de test pour se connecter (Devise)
User.find_or_create_by!(email: "test@filrouge.fr") do |u|
  u.password = "password"
end

# Collaborateurs (destinataires des mails des deux kits)
[
  ["Julie", "Moreau", "j.moreau@cabinet-moreau.example"],          # kit Luna / Terra
  ["Pauline", "Boullet", "pauline.boullet@agileaconseil.fr"],      # jeu de test Agilea
  ["Thomas", "Garnier", "thomas.garnier@agileaconseil.fr"],
  ["Sarah", "Lemoine", "sarah.lemoine@agileaconseil.fr"]
].each do |first_name, last_name, email|
  Employee.find_or_create_by!(email: email) do |e|
    e.first_name = first_name
    e.last_name = last_name
  end
end

# Prompts
prompts = {
  tpe: ["Suivi mensuel TPE", "Résume les échanges du jour avec ce client en cinq lignes au plus. Indique les pièces reçues, les pièces manquantes et les échéances fiscales à venir."],
  pme: ["PME et paie", "Mets en avant les questions sociales et de paie, puis les points comptables en attente."],
  sci: ["SCI et patrimoine", "Résume les demandes des associés et les décisions à préparer pour l'assemblée."],
  rh:  ["Accompagnement RH", "Résume les demandes du client, les décisions prises, les actions attendues du cabinet et leurs échéances."]
}.transform_values do |name, content|
  Prompt.find_or_create_by!(name: name) { |p| p.content = content }
end

# Entreprises et contacts
# Une entreprise est rattachée à un domaine. Les contacts qui écrivent depuis une
# messagerie générique (gmail.com, mail.example) restent sans entreprise.
companies = [
  # Kit Luna / Terra
  ["Boulangerie Le Fournil", "lefournil.example", :tpe, [["Pierre", "Le Bihan", "p.lebihan@lefournil.example"]]],
  ["Garage Auto Rance", "autorance.example", :tpe, [["Sophie", "Delmas", "sophie@autorance.example"]]],
  ["SARL Atelier Kemper", "atelier-kemper.example", :tpe, [["Yann", "Guivarch", "y.guivarch@atelier-kemper.example"]]],
  ["Cabinet infirmier Lemoal", "infirmiere.example", :tpe, [["Claire", "Lemoal", "claire.lemoal@infirmiere.example"]]],
  ["Le Comptoir des Saveurs", "comptoir-saveurs.example", :tpe, [["Inès", "Barra", "ines@comptoir-saveurs.example"]]],
  ["Crêperie Ty Gwenn", "tygwenn.example", :tpe, [["Maëlle", "Kerboul", "contact@tygwenn.example"]]],
  # Jeu de test Agilea
  ["Transports Morvan", "transports-morvan.fr", :rh, [["Claire", "Dubois", "claire.dubois@transports-morvan.fr"],
                                                      ["Marc", "Morvan", "marc.morvan@transports-morvan.fr"]]],
  ["Menuiserie Hamon", "menuiserie-hamon.fr", :rh, [["Julien", "Hamon", "j.hamon@menuiserie-hamon.fr"]]],
  ["Clinique Vétérinaire des Pins", "clinique-des-pins.fr", :rh, [["Hélène", "Marchand", "h.marchand@clinique-des-pins.fr"],
                                                                  ["Damien", "Roux", "d.roux@clinique-des-pins.fr"]]]
]

companies.each do |name, domain, prompt_key, people|
  company = Company.find_or_create_by!(domain: domain) do |c|
    c.name = name
    c.prompt = prompts[prompt_key]
  end
  people.each do |first_name, last_name, email|
    Contact.find_or_create_by!(email: email) do |c|
      c.first_name = first_name
      c.last_name = last_name
      c.company = company
    end
  end
end

# Contacts sans entreprise (adresse sur une messagerie générique)
[
  ["Thomas", "Riou", "plomberie.riou@mail.example"],        # Plomberie Riou EI
  ["Anne", "Le Goff", "anne.legoff.keravel@gmail.com"]       # Boulangeries Ker Avel
].each do |first_name, last_name, email|
  Contact.find_or_create_by!(email: email) do |c|
    c.first_name = first_name
    c.last_name = last_name
  end
end

# Mails
# Pour chaque fichier .eml, on cherche le collaborateur et le contact parmi
# l'expéditeur et les destinataires. Un mail venant d'un expéditeur « no-reply »
# est attribué à l'adresse de Reply-To. Les mails sans contact client (mail
# interne, notification du CRM) sont ignorés.
skipped = []

Dir.glob(Rails.root.join("db/seeds/emails/**/*.eml")).sort.each do |path|
  mail = Mail.read(path)
  file = path.delete_prefix(Rails.root.join("db/seeds/emails/").to_s)

  sender = Array(mail.from).first.to_s.downcase
  sender = Array(mail.reply_to).first.to_s.downcase if sender.match?(/no-?reply/) && mail.reply_to.present?
  recipients = (Array(mail.to) + Array(mail.cc)).map(&:downcase)
  addresses = [sender, *recipients]

  employee = addresses.lazy.filter_map { |address| Employee.find_by(email: address) }.first
  contact  = addresses.lazy.filter_map { |address| Contact.find_by(email: address) }.first

  if employee.nil? || contact.nil?
    skipped << file
    next
  end

  # Le texte du mail, sans les pièces jointes
  body = (mail.text_part || mail).decoded.to_s.force_encoding("UTF-8").scrub.strip

  email = Email.find_or_initialize_by(message_id: mail.message_id || "seed-#{File.basename(path, '.eml')}@fil-rouge.local")
  email.update!(
    contact: contact,
    employee: employee,
    subject: mail.subject,
    content: body,
    sent_at: mail.date,
    summary: nil
  )
end

puts "Terminé : #{Employee.count} collaborateurs, #{Company.count} entreprises, #{Contact.count} contacts, #{Email.count} mails."
puts "Mails ignorés (pas de contact client) : #{skipped.join(', ')}" if skipped.any?
