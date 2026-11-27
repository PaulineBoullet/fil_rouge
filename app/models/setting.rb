# Réglages de l'organisation (une seule ligne) : domaine, nom affiché en haut à gauche,
# couleur du thème.
class Setting < ApplicationRecord
  DOMAIN_FORMAT = /\A[a-z0-9-]+(\.[a-z0-9-]+)+\z/
  DEFAULT_THEME = "#3A908F"

  normalizes :org_domain, with: ->(domain) { domain.strip.downcase.delete_prefix("@") }
  normalizes :org_name, with: ->(name) { name.squish }
  normalizes :theme_color, with: ->(color) { color.strip.upcase }

  validates :org_domain, format: { with: DOMAIN_FORMAT, message: "doit être un nom de domaine, par exemple exemple.fr" },
                         allow_blank: true
  validates :org_name, length: { maximum: 40 }
  validates :theme_color, format: { with: /\A#\h{6}\z/, message: "doit être une couleur, par exemple #3A908F" }

  def self.current
    first_or_create!
  end

  def self.org_domain
    current.org_domain.to_s
  end

  def theme
    ThemeColors.new(theme_color)
  end
end
