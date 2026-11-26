# Un domaine tiers : un groupe d'échanges rattaché à un domaine d'expédition
# (entreprise, administration, association…). La table garde le nom de la V1.
class Company < ApplicationRecord
  enum :state, { pending: "pending", validated: "validated" }, default: :pending

  belongs_to :prompt, optional: true
  has_many :contacts, dependent: :nullify
  has_many :conversations, dependent: :nullify
  has_many :emails, through: :conversations
  has_many :company_summaries, dependent: :destroy

  normalizes :domain, with: ->(domain) { domain.strip.downcase }
  validates :name, :domain, presence: true
  validates :domain, uniqueness: true
  validates :domain, format: { with: Setting::DOMAIN_FORMAT, message: "doit être un nom de domaine, par exemple exemple.fr" }

  # Prompt utilisé pour les synthèses : le prompt spécifique, sinon le prompt par défaut
  def effective_prompt
    prompt || Prompt.default_prompt
  end

  def initials
    name.to_s.split(/[\s-]+/).reject { |w| w.length < 3 }.first(2).map { |w| w[0] }.join.upcase.presence ||
      name.to_s.first(2).upcase
  end
end
