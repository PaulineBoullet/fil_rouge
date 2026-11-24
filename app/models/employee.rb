class Employee < ApplicationRecord
  has_many :emails, dependent: :destroy

  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :email, :first_name, :last_name, presence: true
  validates :email, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "n'est pas une adresse mail valide" }

  def full_name
    "#{first_name} #{last_name}"
  end
end
