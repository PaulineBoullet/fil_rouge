class StatusesController < ApplicationController
  def create
    status = Status.new(status_params.merge(rank: Status.maximum(:rank).to_i + 1))
    if status.save
      redirect_to ai_settings_path(anchor: "statuts"), notice: "Statut ajouté."
    else
      redirect_to ai_settings_path(anchor: "statuts"), alert: "Le statut doit avoir un nom."
    end
  end

  def update
    status = Status.find(params[:id])
    if status.update(status_params)
      redirect_to ai_settings_path(anchor: "statuts"), notice: "Statut enregistré."
    else
      redirect_to ai_settings_path(anchor: "statuts"), alert: "Le statut doit avoir un nom."
    end
  end

  # Monter ou descendre un statut dans l'ordre de priorité
  def move
    Status.find(params[:id]).move(params[:direction])
    redirect_to ai_settings_path(anchor: "statuts"), status: :see_other
  end

  def destroy
    Status.find(params[:id]).destroy
    Status.ordered.each_with_index { |status, i| status.update_columns(rank: i + 1) }
    redirect_to ai_settings_path(anchor: "statuts"), notice: "Statut supprimé.", status: :see_other
  end

  private

  def status_params
    params.expect(status: [:name, :description])
  end
end
