# Recherche de la barre du haut : domaines tiers, personnes et fils. Pour les fils, un mot peut
# se trouver dans le titre, la synthèse, le nom du domaine tiers ou dans l'un des mails (objet,
# synthèse, texte sans les pièces jointes). La recherche ignore les majuscules et les accents.
class SearchController < ApplicationController
  LIMIT = 10
  CONVERSATION_LIMIT = 20

  def index
    @query = params[:q].to_s.strip
    search = TextSearch.new(@query)
    return if search.blank?

    person = TextSearch.matching("display_name", "first_name", "last_name", "email")
    @companies = search.apply(Company.validated, TextSearch.matching("name", "domain")).order(:name).limit(LIMIT)
    @contacts = search.apply(Contact.validated.includes(:company), person).by_name.limit(LIMIT)
    @employees = search.apply(Employee.all, person).by_name.limit(LIMIT)
    @conversations = search.apply(Conversation.displayable, conversation_condition)
                           .includes(:company, :status).order(last_email_at: :desc).limit(CONVERSATION_LIMIT)
  end

  private

  def conversation_condition
    companies = "SELECT id FROM companies WHERE #{TextSearch.matching('companies.name', 'companies.domain')}"
    emails = "SELECT conversation_id FROM emails " \
             "WHERE #{TextSearch.matching('emails.subject', 'emails.summary', 'emails.body_text')}"
    "(#{TextSearch.matching('conversations.title', 'conversations.summary')} " \
      "OR conversations.company_id IN (#{companies}) OR conversations.id IN (#{emails}))"
  end
end
