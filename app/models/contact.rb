# Un correspondant : une personne extérieure, rattachée au domaine tiers de son adresse.
class Contact < ApplicationRecord
  include PersonName

  enum :state, { pending: "pending", validated: "validated", blocked: "blocked" }, default: :pending

  belongs_to :company, optional: true
  has_many :email_participants, dependent: :nullify
  has_many :emails, -> { distinct }, through: :email_participants
  has_many :originated_conversations, class_name: "Conversation", foreign_key: :origin_contact_id,
                                      inverse_of: :origin_contact, dependent: :nullify

  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :email, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "n'est pas une adresse mail valide" }

  scope :by_name, -> { order(Arel.sql("LOWER(COALESCE(NULLIF(contacts.display_name, ''), contacts.last_name, contacts.email))")) }

  # Un correspondant ne se valide qu'une fois son domaine tiers validé
  def validatable?
    company.nil? || company.validated?
  end
end
