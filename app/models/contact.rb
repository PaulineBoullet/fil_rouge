class Contact < ApplicationRecord
  belongs_to :company, optional: true
  has_many :emails, dependent: :destroy
  has_many :contact_summaries, dependent: :destroy

  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :email, :first_name, :last_name, presence: true
  validates :email, uniqueness: true
end
