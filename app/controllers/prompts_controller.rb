class PromptsController < ApplicationController
  def create
    prompt = Prompt.new(prompt_params)
    if prompt.save
      redirect_to ai_settings_path(anchor: "prompts"), notice: "Prompt spécifique ajouté."
    else
      redirect_to ai_settings_path(anchor: "prompts"), alert: "Le prompt doit avoir un nom et une consigne."
    end
  end

  def update
    prompt = Prompt.find(params[:id])
    if prompt.update(prompt_params)
      redirect_to ai_settings_path(anchor: "prompts"), notice: "Prompt enregistré."
    else
      redirect_to ai_settings_path(anchor: "prompts"), alert: "Le prompt doit avoir un nom et une consigne."
    end
  end

  # Associe un domaine tiers à ce prompt spécifique
  def assign
    prompt = Prompt.find(params[:id])
    company = Company.find(params[:company_id])
    company.update!(prompt: prompt)
    redirect_to ai_settings_path(anchor: "prompts"), notice: "#{company.name} utilise désormais « #{prompt.name} »."
  end

  def destroy
    prompt = Prompt.find(params[:id])
    if prompt.is_default?
      redirect_to ai_settings_path(anchor: "prompts"), alert: "Le prompt par défaut ne peut pas être supprimé.", status: :see_other
    else
      prompt.destroy
      redirect_to ai_settings_path(anchor: "prompts"), notice: "Prompt supprimé.", status: :see_other
    end
  end

  private

  def prompt_params
    params.expect(prompt: [:name, :content])
  end
end
