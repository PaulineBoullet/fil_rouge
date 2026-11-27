# Paramètres – Mon domaine : le seul réglage à renseigner à la mise en service.
# Changer le domaine réattribue toutes les adresses des mails déjà en base.
class SettingsController < ApplicationController
  def show
    @setting = Setting.current
  end

  def update
    @setting = Setting.current
    if @setting.update(params.expect(setting: [:org_domain, :org_name, :theme_color]))
      if @setting.saved_change_to_org_domain?
        Reidentification.new(org_domain: @setting.org_domain).call
        notice = "Domaine enregistré. Les adresses des mails ont été réattribuées : " \
                 "#{Employee.count} collaborateurs identifiés, #{Contact.pending.count} correspondants à valider."
      else
        notice = "Réglages enregistrés."
      end
      redirect_to organization_path, notice: notice
    else
      render :show, status: :unprocessable_entity
    end
  end

  # Relance l'identification sans changer de domaine (mails repris de la V1, données incohérentes)
  def reidentify
    Reidentification.new.call
    redirect_to organization_path, notice: "Identification relancée : #{Employee.count} collaborateurs identifiés, " \
                                           "#{Contact.pending.count} correspondants à valider."
  end
end
