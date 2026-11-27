# Collaborateurs avec leur nombre de fils et leur dernier échange.
class EmployeesOverview
  attr_reader :employees, :conversation_counts, :last_exchange

  def initialize
    @employees = Employee.by_name.to_a
    stats = EmailParticipant.where(employee_id: @employees).joins(:email)
    @conversation_counts = stats.group(:employee_id).distinct.count("emails.conversation_id")
    @last_exchange = stats.group(:employee_id).maximum("emails.sent_at")
  end

  def locals
    { employees: employees, conversation_counts: conversation_counts, last_exchange: last_exchange }
  end
end
