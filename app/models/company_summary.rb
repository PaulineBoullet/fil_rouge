# Synthèse d'un domaine tiers pour un jour donné.
class CompanySummary < ApplicationRecord
  belongs_to :company

  validates :summary, :generated_at, :day, presence: true
  validates :day, uniqueness: { scope: :company_id }
end
