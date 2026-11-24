class Company < ApplicationRecord
  belongs_to :prompt, optional: true
  has_many :contacts, dependent: :nullify
  has_many :emails, through: :contacts
  has_many :company_summaries, dependent: :destroy

  normalizes :domain, with: ->(domain) { domain.strip.downcase }
  validates :name, :domain, presence: true
  validates :domain, uniqueness: true
  validates :domain, format: { with: /\A[a-z0-9-]+(\.[a-z0-9-]+)+\z/, message: "doit être un nom de domaine, par exemple exemple.fr" }
end
