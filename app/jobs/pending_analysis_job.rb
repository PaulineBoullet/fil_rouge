# Tâche planifiée (config/recurring.yml) : fait analyser par l'IA les fils qui l'attendent.
# Les fils sont traités l'un après l'autre ; une seule exécution à la fois.
class PendingAnalysisJob < ApplicationJob
  BATCH_SIZE = 20

  limits_concurrency to: 1, key: "pending_analysis"

  def perform
    ConversationAnalysis.pending.order(:last_email_at).limit(BATCH_SIZE).each do |conversation|
      ConversationAnalysis.new(conversation).call
    rescue StandardError => e
      Rails.logger.error("Analyse du fil #{conversation.id} impossible : #{e.message}")
    end
  end
end
