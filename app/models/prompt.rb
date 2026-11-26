# Consigne donnée à l'IA pour les synthèses. Un seul prompt par défaut ; les autres
# sont des prompts spécifiques, associés à des domaines tiers.
class Prompt < ApplicationRecord
  has_many :companies, dependent: :nullify

  validates :name, :content, presence: true

  before_save :unset_other_defaults, if: -> { is_default? && will_save_change_to_is_default? }

  scope :specific, -> { where(is_default: false).order(:name) }

  def self.default_prompt
    find_by(is_default: true)
  end

  private

  def unset_other_defaults
    self.class.where.not(id: id).where(is_default: true).update_all(is_default: false)
  end
end
