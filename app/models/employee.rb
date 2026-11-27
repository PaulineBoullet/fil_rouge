# Un collaborateur : une adresse du domaine de l'organisation. Il n'y a rien à valider ;
# les collaborateurs sont listés dans la page « Mon domaine ».
class Employee < ApplicationRecord
  include PersonName

  has_many :email_participants, dependent: :nullify
  has_many :emails, -> { distinct }, through: :email_participants

  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :email, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "n'est pas une adresse mail valide" }

  scope :by_name, -> { order(Arel.sql("LOWER(COALESCE(NULLIF(employees.display_name, ''), employees.last_name, employees.email))")) }
end
