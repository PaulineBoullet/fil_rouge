# Vue d'un fil : synthèse, statut et catégorie modifiables, mails jour par jour.
class ConversationsController < ApplicationController
  before_action :set_conversation

  def show
    emails = @conversation.emails.displayable.includes(email_participants: %i[contact employee])
    emails = filter_emails(emails)
    @days = emails.to_a.sort_by { |e| [e.sent_at || Time.at(0), e.id] }.group_by(&:day).sort_by { |day, _| day || Date.new(0) }.reverse
    @people = @conversation.participants.sort_by(&:name)
    @emails_after_summary = if @conversation.summary_generated_at
                              @conversation.emails.where("sent_at > ?", @conversation.summary_generated_at).count
                            else
                              0
                            end
    @open_email = @conversation.emails.find_by(id: params[:mail]) if params[:mail].present?
  end

  # Statut ou catégorie choisis à la main : l'IA ne les remplacera plus
  def update
    attrs = params.expect(conversation: [:status_id, :category_id])
    attrs[:status_locked] = true if attrs.key?(:status_id)
    attrs[:category_locked] = true if attrs.key?(:category_id)
    @conversation.update!(attrs)
    redirect_to conversation_path(@conversation), notice: "Fil mis à jour."
  end

  def toggle_hidden
    @conversation.update!(hidden: !@conversation.hidden)
    notice = @conversation.hidden ? "Fil masqué. Le filtre « Fils masqués » permet de le retrouver." : "Le fil n'est plus masqué."
    redirect_to conversation_path(@conversation), notice: notice
  end

  # Synthèses des mails du fil, puis synthèse du fil (fait appel à l'IA)
  def analyze
    @conversation.emails.where(summary: nil).find_each { |email| EmailAnalysisService.new(email).call }
    ConversationSummaryService.new(@conversation).call
    redirect_to conversation_path(@conversation), notice: "Synthèse du fil mise à jour."
  rescue StandardError => e
    redirect_to conversation_path(@conversation), alert: "L'analyse a échoué : #{e.message}"
  end

  private

  def set_conversation
    @conversation = Conversation.includes(:company, :status, :category).find(params[:id])
  end

  def filter_emails(emails)
    if params[:person].present?
      kind, id = params[:person].split("-", 2)
      column = kind == "employee" ? :employee_id : :contact_id
      emails = emails.where(id: EmailParticipant.where(column => id).select(:email_id))
    end
    case params[:direction]
    when "recus" then emails = emails.where.not(id: sent_email_ids)
    when "envoyes" then emails = emails.where(id: sent_email_ids)
    end
    emails = emails.where("emails.attachments_count > 0") if params[:attachments] == "1"
    emails
  end

  def sent_email_ids
    EmailParticipant.role_from.where.not(employee_id: nil).select(:email_id)
  end
end
