# Paramètres – Mon domaine : le seul réglage à renseigner à la mise en service.
class SettingsController < ApplicationController
  def show
    @setting = Setting.current
  end

  def update
    @setting = Setting.current
    if @setting.update(params.expect(setting: [:org_domain]))
      redirect_to organization_path, notice: "Domaine enregistré."
    else
      render :show, status: :unprocessable_entity
    end
  end
end
