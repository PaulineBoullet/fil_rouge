# Statut de fil, défini dans les réglages de l'IA. rank 1 = le plus urgent.
class Status < ApplicationRecord
  has_many :conversations, dependent: :nullify

  validates :name, :rank, presence: true

  scope :ordered, -> { order(:rank, :id) }

  # Statut donné à un nouveau fil tant que l'IA ne l'a pas classé : le moins urgent
  def self.default_status
    order(rank: :desc, id: :desc).first
  end

  # Échange la place de ce statut avec son voisin (direction : :up ou :down)
  def move(direction)
    list = self.class.ordered.to_a
    index = list.index(self)
    other_index = direction.to_s == "up" ? index - 1 : index + 1
    return if other_index.negative? || other_index >= list.size

    list[index], list[other_index] = list[other_index], list[index]
    transaction do
      list.each_with_index { |status, i| status.update_columns(rank: i + 1, updated_at: Time.current) }
    end
  end
end
