# Paramètres – Mon domaine : le seul réglage à renseigner à la mise en service.
# Changer le domaine réattribue toutes les adresses des mails déjà en base.
class SettingsController < ApplicationController
  def show
    @setting = Setting.current
    load_employees
  end

  def update
    @setting = Setting.current
    if @setting.update(params.expect(setting: [:org_domain]))
      if @setting.saved_change_to_org_domain?
        Reidentification.new(org_domain: @setting.org_domain).call
        notice = "Domaine enregistré. Les adresses des mails ont été réattribuées : " \
                 "#{Employee.count} collaborateurs identifiés, #{Contact.pending.count} correspondants à valider."
      else
        notice = "Domaine enregistré."
      end
      redirect_to organization_path, notice: notice
    else
      load_employees
      render :show, status: :unprocessable_entity
    end
  end

  # Relance l'identification sans changer de domaine (mails repris de la V1, données incohérentes)
  def reidentify
    Reidentification.new.call
    redirect_to organization_path, notice: "Identification relancée : #{Employee.count} collaborateurs identifiés, " \
                                           "#{Contact.pending.count} correspondants à valider."
  end

  private

  # Collaborateurs identifiés : toutes les adresses du domaine de l'organisation
  def load_employees
    @employees = Employee.by_name.to_a
    stats = EmailParticipant.where(employee_id: @employees).joins(:email)
    @conversation_counts = stats.group(:employee_id).distinct.count("emails.conversation_id")
    @last_exchange = stats.group(:employee_id).maximum("emails.sent_at")
  end
end
