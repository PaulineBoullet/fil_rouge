class Employee < ApplicationRecord
  include PersonName

  enum :state, { pending: "pending", validated: "validated" }, default: :pending

  has_many :email_participants, dependent: :nullify
  has_many :emails, -> { distinct }, through: :email_participants

  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :email, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "n'est pas une adresse mail valide" }

  scope :by_name, -> { order(Arel.sql("LOWER(COALESCE(NULLIF(employees.display_name, ''), employees.last_name, employees.email))")) }
end
