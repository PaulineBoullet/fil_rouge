class ContactSummary < ApplicationRecord
  belongs_to :contact

  validates :summary, :generated_at, presence: true
end
