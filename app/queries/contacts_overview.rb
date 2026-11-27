# Correspondants regroupés par domaine tiers, avec leurs filtres (domaine tiers, état, recherche).
class ContactsOverview
  attr_reader :groups, :companies, :email_counts, :last_exchange

  def initialize(params)
    contacts = Contact.includes(:company).by_name
    contacts = contacts.where(company_id: params[:company_id]) if params[:company_id].present?
    contacts = contacts.where(state: params[:state]) if Contact.states.key?(params[:state])
    if params[:contact_query].present?
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(params[:contact_query].strip)}%"
      contacts = contacts.where("contacts.display_name ILIKE :q OR contacts.email ILIKE :q", q: pattern)
    end

    @groups = contacts.to_a.group_by(&:company).sort_by { |company, _| [company&.validated? ? 0 : 1, company&.name.to_s.downcase] }
    @companies = Company.order(:name)
    stats = EmailParticipant.where(contact_id: contacts.select(:id)).joins(:email)
    @email_counts = stats.group(:contact_id).distinct.count(:email_id)
    @last_exchange = stats.group(:contact_id).maximum("emails.sent_at")
  end
end
