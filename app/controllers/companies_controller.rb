class CompaniesController < ApplicationController
  before_action :set_company, only: %i[show edit update destroy analyze_emails]
  before_action :set_date, only: %i[show analyze_emails]
  def index
    @companies = Company.left_joins(:contacts)
                        .select("companies.*, COUNT(contacts.id) AS contacts_count")
                        .group(:id)
                        .includes(:prompt)
                        .order(:name)
    if search_pattern
      @companies = @companies.where("companies.name ILIKE :q OR companies.domain ILIKE :q", q: search_pattern)
    end
  end

  def show
    @summary = @company.company_summaries.where(generated_at: @date.all_day).order(:generated_at).last

    # Contacts de l'entreprise ayant échangé à la date choisie,
    # avec leur nombre de mails et l'heure du dernier
    @contacts = @company.contacts
                        .joins(:emails)
                        .where(emails: { sent_at: @date.all_day })
                        .select("contacts.*, COUNT(emails.id) AS emails_count, MAX(emails.sent_at) AS last_email_at")
                        .group(:id)
                        .order(:last_name, :first_name)

    @contact_summaries = ContactSummary.where(contact_id: @contacts.map(&:id), generated_at: @date.all_day)
                                       .order(:generated_at)
                                       .index_by(&:contact_id)
  end

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(company_params)
    if @company.save
      redirect_to companies_path, notice: "Entreprise ajoutée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @company.update(company_params)
      redirect_to companies_path, notice: "Entreprise modifiée."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @company.destroy
    redirect_to companies_path, notice: "Entreprise supprimée.", status: :see_other
  end

  def analyze_emails
  emails = @company.emails.where(sent_at: @date.all_day)

  emails.find_each do |email|
    EmailAnalysisService.new(email).call
  end

  redirect_to root_path(date: @date), notice: "#{emails.count} emails analysés."
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    params.expect(company: [:name, :domain, :prompt_id])
  end
end
