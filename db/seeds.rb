# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "Création des données de test…"

julie = Employee.find_or_create_by!(email: "j.moreau@cabinet.fr") do |e|
  e.first_name = "Julie"
  e.last_name = "Moreau"
end

tpe = Prompt.find_or_create_by!(name: "Suivi mensuel TPE") do |p|
  p.content = "Résume les échanges du mois avec ce client en cinq lignes au plus. " \
              "Indique les pièces reçues, les pièces manquantes et les échéances fiscales à venir."
end

fournil = Company.find_or_create_by!(domain: "lefournil.fr") do |c|
  c.name = "Boulangerie Le Fournil"
  c.prompt = tpe
end

pierre = Contact.find_or_create_by!(email: "p.lebihan@lefournil.fr") do |c|
  c.first_name = "Pierre"
  c.last_name = "Le Bihan"
  c.company = fournil
end

Email.find_or_create_by!(message_id: "<seed-1@lefournil.fr>") do |m|
  m.contact = pierre
  m.employee = julie
  m.subject = "Relevés bancaires novembre"
  m.content = "Bonjour Julie, vous trouverez ci-joint les relevés de novembre."
  m.sent_at = Time.current
end

puts "Terminé : #{Company.count} entreprise(s), #{Contact.count} contact(s), #{Email.count} mail(s)."
