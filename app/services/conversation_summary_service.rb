# Synthèse d'un fil, construite à partir des synthèses de ses mails (du premier au dernier).
# Les mails eux-mêmes ne sont pas relus, ce qui limite le coût des appels à l'IA.
class ConversationSummaryService
  INSTRUCTIONS = <<~PROMPT
    Tu résumes un fil de conversation par mail entre une organisation et un domaine tiers.
    On te donne, dans l'ordre chronologique, la synthèse de chaque mail du fil.
    Rédige en français une synthèse de quatre phrases au plus : l'objet du fil, où il en est,
    et ce qui est attendu, de qui, avec l'échéance si elle est connue.
    N'invente rien qui ne figure pas dans les synthèses.
  PROMPT

  def initialize(conversation)
    @conversation = conversation
  end

  def call
    lines = @conversation.emails.chronological.includes(:email_participants).filter_map do |email|
      next if email.summary.blank?

      date = email.sent_at ? I18n.l(email.sent_at, format: "%d/%m/%Y %H:%M") : "date inconnue"
      "- #{date}, de #{email.sender&.display_name || 'expéditeur inconnu'} : #{email.summary}"
    end
    return if lines.empty?

    instructions = PromptBuilder.new(@conversation.company).instructions_for(INSTRUCTIONS)
    summary = OpenaiService.new.summarize("Titre du fil : #{@conversation.display_title}\n\n#{lines.join("\n")}",
                                          instructions: instructions)
    @conversation.update!(summary: summary, summary_generated_at: Time.current)
  end
end
