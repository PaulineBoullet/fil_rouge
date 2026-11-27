# Vue d'un fil : synthèse, statut et catégorie modifiables, puis les mails sous forme de
# conversation, avec une recherche.
class ConversationsController < ApplicationController
  before_action :set_conversation

  def show
    @query = params[:q].to_s.strip
    emails = @conversation.emails.includes(email_participants: %i[contact employee])
    emails = search(emails, @query) if @query.present?
    # Du plus récent au plus ancien, jours comme mails
    @days = emails.to_a.sort_by { |e| [e.sent_at || Time.at(0), e.id] }.reverse.group_by(&:day).sort_by { |day, _| day || Date.new(0) }.reverse
    @total_emails = @conversation.emails.count
    @participants_count = @conversation.participants.size
    @emails_after_summary = if @conversation.summary_generated_at
                              @conversation.emails.where("sent_at > ?", @conversation.summary_generated_at).count
                            else
                              0
                            end
    @open_email = @conversation.emails.find_by(id: params[:mail]) if params[:mail].present?
  end

  # Statut ou catégorie choisis à la main : l'IA ne les remplacera plus
  def toggle_hidden
    @conversation.update!(hidden: !@conversation.hidden)
    notice = @conversation.hidden ? "Fil masqué. Le filtre « Fils masqués » permet de le retrouver." : "Le fil n'est plus masqué."
    redirect_to conversation_path(@conversation), notice: notice
  end

  # Synthèses des mails du fil, puis synthèse du fil (fait appel à l'IA)
  def analyze
    ConversationAnalysis.new(@conversation).call
    redirect_to conversation_path(@conversation), notice: "Synthèse du fil mise à jour."
  rescue StandardError => e
    redirect_to conversation_path(@conversation), alert: "L'analyse a échoué : #{e.message}"
  end

  private

  def set_conversation
    @conversation = Conversation.includes(:company, :status, :category).find(params[:id])
  end

  # Recherche dans les mails du fil : objet, synthèse et texte du mail (sans les pièces jointes), sans tenir compte des accents
  def search(emails, query)
    TextSearch.new(query).apply(emails, TextSearch.matching("emails.subject", "emails.summary", "emails.body_text"))
  end
end
