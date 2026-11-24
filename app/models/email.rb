class Email < ApplicationRecord
  belongs_to :contact
  belongs_to :employee

  validates :message_id, presence: true, uniqueness: true
end
