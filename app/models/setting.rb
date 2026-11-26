# Réglages de l'organisation (une seule ligne).
class Setting < ApplicationRecord
  DOMAIN_FORMAT = /\A[a-z0-9-]+(\.[a-z0-9-]+)+\z/

  normalizes :org_domain, with: ->(domain) { domain.strip.downcase.delete_prefix("@") }
  validates :org_domain, format: { with: DOMAIN_FORMAT, message: "doit être un nom de domaine, par exemple exemple.fr" },
                         allow_blank: true

  def self.current
    first_or_create!
  end

  def self.org_domain
    current.org_domain.to_s
  end
end
