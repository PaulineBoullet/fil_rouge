# Filtres communs au dashboard et à la vue d'un domaine tiers.
# Les filtres réduisent la liste sans en changer l'ordre.
module ConversationFilters
  extend ActiveSupport::Concern

  FILTER_KEYS = %i[status category address hidden internal].freeze

  included do
    helper_method :filter_params, :selected_domain_ids, :show_hidden?, :show_internal?
  end

  private

  def filtered_conversations
    scope = Conversation.displayable(show_hidden: show_hidden?, show_internal: show_internal?)
    scope = scope.where(company_id: selected_domain_ids) if selected_domain_ids.any?
    scope = scope.where(status_id: params[:status]) if params[:status].present?
    scope = scope.where(category_id: params[:category]) if params[:category].present?
    if params[:address].present?
      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(params[:address].strip.downcase)}%"
      scope = scope.where(id: Email.joins(:email_participants)
                                   .where("email_participants.address LIKE ?", pattern)
                                   .select(:conversation_id))
    end
    scope
  end

  def selected_domain_ids
    @selected_domain_ids ||= Array(params[:domains]).compact_blank.map(&:to_i).uniq
  end

  def show_hidden?
    params[:hidden] == "1"
  end

  def show_internal?
    params[:internal] == "1"
  end

  # Filtres en cours (sans les domaines tiers), à reporter dans les liens
  def filter_params
    params.permit(*FILTER_KEYS).to_h.compact_blank.symbolize_keys
  end

  # Premier jour à afficher : la veille du paquet suivant (défilement vers l'historique)
  def feed_before
    parse_date(params[:before]) if params[:before].present?
  end

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue ArgumentError
    nil
  end
end
