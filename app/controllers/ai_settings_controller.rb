# Paramètres – Réglages de l'IA : catégories, statuts et prompts sur une même page.
class AiSettingsController < ApplicationController
  def show
    @categories = Category.ordered
    @statuses = Status.ordered
    @default_prompt = Prompt.default_prompt
    @prompts = Prompt.specific.includes(:companies)
    @companies = Company.validated.order(:name)
    @category_counts = Conversation.group(:category_id).count
    @status_counts = Conversation.group(:status_id).count
  end
end
