class Email < ApplicationRecord
  belongs_to :conversation, optional: true
  has_many :email_participants, dependent: :destroy
  has_many :employees, -> { distinct }, through: :email_participants
  has_many :contacts, -> { distinct }, through: :email_participants

  validates :message_id, presence: true, uniqueness: true

  scope :chronological, -> { order(Arel.sql("emails.sent_at ASC NULLS FIRST"), :id) }

  def sender
    email_participants.detect(&:role_from?)
  end

  def recipients
    email_participants.reject(&:role_from?)
  end

  # Envoyé par l'organisation (expéditeur collaborateur) ou reçu
  def sent_by_organization?
    sender&.internal? || false
  end

  # Jour de l'échange dans le fuseau de l'application
  def day
    sent_at&.in_time_zone&.to_date
  end
end
