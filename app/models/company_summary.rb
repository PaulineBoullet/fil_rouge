class CompanySummary < ApplicationRecord
  belongs_to :company

  validates :summary, :generated_at, presence: true
end
