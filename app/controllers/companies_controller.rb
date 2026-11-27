# Domaines tiers : vue de consultation (show) et paramètres (liste, validation, prompt).
class CompaniesController < ApplicationController
  include ConversationFilters

  before_action :set_company, only: %i[show edit update destroy validate analyze_emails]

  def index
    companies = Company.includes(:prompt).order(:name)
    companies = companies.where("companies.name ILIKE :q OR companies.domain ILIKE :q", q: search_pattern) if search_pattern
    @pending = companies.pending.to_a
    @validated = companies.validated.to_a
    @conversation_counts = Conversation.where(company_id: @pending + @validated).group(:company_id).count
    @contact_counts = Contact.where(company_id: @pending + @validated).group(:company_id).count
    @first_seen = Email.joins(:conversation).where(conversations: { company_id: @pending.map(&:id) })
                       .group("conversations.company_id").minimum(:sent_at)
    @prompts = Prompt.specific
    @employees_overview = EmployeesOverview.new
  end

  # Fils du domaine tiers, jour par jour
  def show
    @selected_domain_ids = [@company.id]
    @feed = ActivityFeed.new(conversations: filtered_conversations, before: feed_before)
    @cards = ConversationCards.new(@feed)

    render partial: "companies/feed_page", locals: { feed: @feed, cards: @cards, company: @company } if turbo_frame_request?
  end

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(company_params.merge(state: :validated))
    if @company.save
      redirect_to companies_path, notice: "Domaine tiers ajouté."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @company.update(company_params)
      redirect_back_or_to companies_path, notice: "Domaine tiers modifié."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @company.destroy
    redirect_to companies_path, notice: "Domaine tiers supprimé.", status: :see_other
  end

  # Valider un domaine tiers ne valide pas ses correspondants
  def validate
    @company.name = params[:name] if params[:name].present?
    @company.validated!
    redirect_to companies_path, notice: "#{@company.name} est validé. Ses correspondants restent à valider."
  end

  # Synthèse du domaine tiers pour un jour (fait appel à l'IA)
  def analyze_emails
    day = parse_date(params[:day]) || Date.current
    CompanyDaySummaryService.new(@company, day).call
    redirect_back_or_to company_view_path(@company), notice: "Synthèse du #{I18n.l(day, format: :long)} mise à jour."
  rescue StandardError => e
    redirect_back_or_to company_view_path(@company), alert: "L'analyse a échoué : #{e.message}"
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    params.expect(company: [:name, :domain, :prompt_id])
  end
end
