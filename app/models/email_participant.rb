# Une adresse d'un mail, avec son rôle, reliée au collaborateur ou au correspondant reconnu.
class EmailParticipant < ApplicationRecord
  enum :role, { from: "from", to: "to", cc: "cc" }, prefix: :role

  belongs_to :email
  belongs_to :employee, optional: true
  belongs_to :contact, optional: true

  validates :address, presence: true

  def person
    employee || contact
  end

  def display_name
    person&.name || name.presence || address
  end

  def internal?
    employee_id.present?
  end
end
