# Recherche par domaine tiers, par personne et par mot-clé dans les titres et objets.
class SearchController < ApplicationController
  LIMIT = 10

  def index
    @query = params[:q].to_s.strip
    return if @query.blank?

    pattern = search_pattern(@query)
    @companies = Company.validated.where("name ILIKE :q OR domain ILIKE :q", q: pattern).order(:name).limit(LIMIT)
    @contacts = Contact.validated.includes(:company)
                       .where("display_name ILIKE :q OR first_name ILIKE :q OR last_name ILIKE :q OR email ILIKE :q", q: pattern)
                       .by_name.limit(LIMIT)
    @employees = Employee
                         .where("display_name ILIKE :q OR first_name ILIKE :q OR last_name ILIKE :q OR email ILIKE :q", q: pattern)
                         .by_name.limit(LIMIT)
    subjects = Email.where("subject ILIKE ?", pattern).select(:conversation_id)
    base = Conversation.displayable
    @conversations = base.where("conversations.title ILIKE :q", q: pattern).or(base.where(id: subjects))
                         .includes(:company, :status).order(last_email_at: :desc).limit(LIMIT)
  end
end
