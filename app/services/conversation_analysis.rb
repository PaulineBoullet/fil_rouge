# Analyse complète d'un fil par l'IA : chaque mail pas encore analysé, puis le classement du fil
# (priorité, catégorie) et sa synthèse avec ses points clés.
# Utilisée par le bouton « Mettre à jour la synthèse », par la tâche planifiée et par
# bin/rails fil_rouge:analyser.
class ConversationAnalysis
  # Fils affichés qui attendent l'IA : un mail sans synthèse, pas encore de synthèse du fil,
  # ou un mail arrivé depuis la dernière synthèse
  def self.pending
    Conversation.displayable.where(
      "conversations.id IN (SELECT conversation_id FROM emails WHERE emails.summary IS NULL) " \
      "OR conversations.summary_generated_at IS NULL " \
      "OR conversations.last_email_at > conversations.summary_generated_at"
    )
  end

  def initialize(conversation)
    @conversation = conversation
  end

  def call
    @conversation.emails.where(summary: nil).find_each { |email| EmailAnalysisService.new(email, classify: false).call }
    ConversationClassifier.new(@conversation).call
    ConversationSummaryService.new(@conversation).call
  end
end
