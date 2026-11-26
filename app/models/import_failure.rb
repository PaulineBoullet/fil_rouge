# Mail que l'import n'a pas pu intégrer. Consultation seule.
class ImportFailure < ApplicationRecord
  validates :filename, presence: true

  scope :recent_first, -> { order(last_attempt_at: :desc, id: :desc) }

  def self.record(filename, reason)
    failure = find_or_initialize_by(filename: filename)
    failure.attempts = failure.new_record? ? 1 : failure.attempts + 1
    failure.reason = reason
    failure.last_attempt_at = Time.current
    failure.save!
    failure
  end
end
