# Paramètres – Mon domaine : le seul réglage à renseigner à la mise en service.
# Changer le domaine réattribue toutes les adresses des mails déjà en base.
class SettingsController < ApplicationController
  def show
    @setting = Setting.current
  end

  def update
    @setting = Setting.current
    if @setting.update(params.expect(setting: [:org_domain]))
      if @setting.saved_change_to_org_domain?
        Reidentification.new(org_domain: @setting.org_domain).call
        notice = "Domaine enregistré. Les adresses des mails ont été réattribuées : " \
                 "#{Employee.pending.count} collaborateurs et #{Contact.pending.count} correspondants sont à valider."
      else
        notice = "Domaine enregistré."
      end
      redirect_to organization_path, notice: notice
    else
      render :show, status: :unprocessable_entity
    end
  end
end
