# Synthèse d'un domaine tiers pour un jour, construite à partir des synthèses de ses fils
# actifs ce jour-là.
class CompanyDaySummaryService
  INSTRUCTIONS = <<~PROMPT
    Tu résumes en français la journée d'échanges d'une organisation avec un domaine tiers.
    On te donne la synthèse de chaque fil actif ce jour-là.
    Rédige deux à quatre phrases : les sujets du jour, ce qui est attendu et de qui.
    N'invente rien qui ne figure pas dans les synthèses.
  PROMPT

  def initialize(company, day)
    @company = company
    @day = day
  end

  def call
    emails = Email.joins(:conversation).where(conversations: { company_id: @company.id })
                  .where("#{ActivityFeed.day_sql} = ?", @day)
    conversations = Conversation.where(id: emails.select(:conversation_id))
    lines = conversations.filter_map do |conversation|
      "- #{conversation.display_title} : #{conversation.summary}" if conversation.summary.present?
    end
    return if lines.empty?

    instructions = [INSTRUCTIONS, @company.effective_prompt&.content].compact_blank.join("\n\n")
    text = OpenaiService.new.summarize("Domaine tiers : #{@company.name}\nJour : #{I18n.l(@day, format: :long)}\n\n#{lines.join("\n")}",
                                       instructions: instructions)
    summary = CompanySummary.find_or_initialize_by(company: @company, day: @day)
    summary.update!(summary: text, generated_at: Time.current)
  end
end
