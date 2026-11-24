class Prompt < ApplicationRecord
  has_many :companies, dependent: :nullify

  validates :name, :content, presence: true
end
