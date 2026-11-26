# Catégorie de fil, définie dans les réglages de l'IA.
class Category < ApplicationRecord
  has_many :conversations, dependent: :nullify

  validates :name, presence: true

  scope :ordered, -> { order(:position, :name) }
end
