# Synthèse d'un fil, construite à partir des synthèses de ses mails (du premier au dernier).
# Les mails eux-mêmes ne sont pas relus, ce qui limite le coût des appels à l'IA.
class ConversationSummaryService
  INSTRUCTIONS = <<~PROMPT
    Tu résumes un fil de conversation par mail entre une organisation et un domaine tiers.
    On te donne, dans l'ordre chronologique, la synthèse de chaque mail du fil, suivie de ses
    points saillants (échéances, montants, pièces manquantes, incohérences).
    Retourne le JSON demandé :
    - summary : en français, quatre phrases au plus : l'objet du fil, où il en est, et ce qui
      est attendu, de qui, avec l'échéance si elle est connue.
    - key_points : de 0 à 4 points clés encore d'actualité à la fin du fil, chacun en 12 mots
      au plus : échéance, montant, pièce manquante, risque, incohérence. Reprends-les des points
      saillants des mails ; écarte ceux que la suite du fil a réglés ; ne répète pas la synthèse.
      Liste vide s'il n'y en a pas.
    N'invente rien qui ne figure pas dans les synthèses ou les points saillants.
  PROMPT

  SCHEMA = {
    type: "object",
    properties: {
      summary: { type: "string" },
      key_points: { type: "array", items: { type: "string" } }
    },
    required: %w[summary key_points],
    additionalProperties: false
  }.freeze

  def initialize(conversation)
    @conversation = conversation
  end

  def call
    lines = @conversation.emails.chronological.includes(:email_participants).filter_map do |email|
      next if email.summary.blank?

      date = email.sent_at ? I18n.l(email.sent_at, format: "%d/%m/%Y %H:%M") : "date inconnue"
      points = Array(email.metadata["key_points"]).map { |point| "\n  · #{point}" }.join
      "- #{date}, de #{email.sender&.display_name || 'expéditeur inconnu'} : #{email.summary}#{points}"
    end
    return if lines.empty?

    instructions = PromptBuilder.new(@conversation.company).instructions_for(INSTRUCTIONS)
    result = OpenaiService.new.structured("Titre du fil : #{@conversation.display_title}\n\n#{lines.join("\n")}",
                                          instructions: instructions, name: "thread_summary", schema: SCHEMA)
    @conversation.update!(summary: result.fetch("summary").strip, key_points: Array(result["key_points"]).first(4),
                          summary_generated_at: Time.current)
  end
end
