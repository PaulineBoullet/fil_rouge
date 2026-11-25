class PagesController < ApplicationController
  before_action :set_date

  def dashboard
    emails_of_the_day = Email.joins(:contact).where(sent_at: @date.all_day)

    # Entreprises avec au moins un échange à la date choisie
    @companies = Company.where(id: emails_of_the_day.select("contacts.company_id")).order(:name)

    # Synthèses de cette date, rangées par entreprise
    @summaries = CompanySummary.where(generated_at: @date.all_day)
                               .order(:generated_at)
                               .index_by(&:company_id)

    # Nombre de mails et de contacts de la date, par entreprise
    @email_counts   = emails_of_the_day.group("contacts.company_id").count
    @contact_counts = emails_of_the_day.group("contacts.company_id").distinct.count(:contact_id)
  end
end
