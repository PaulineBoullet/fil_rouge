class Contact < ApplicationRecord
  belongs_to :company, optional: true
  has_many :emails, dependent: :destroy
  has_many :contact_summaries, dependent: :destroy

  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :email, :first_name, :last_name, presence: true
  validates :email, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "n'est pas une adresse mail valide" }

  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    "#{first_name.to_s.first}#{last_name.to_s.first}".upcase
  end
end
