# Paramètres – Correspondants : regroupés par domaine tiers, validés un par un.
class ContactsController < ApplicationController
  before_action :set_contact, only: %i[edit update destroy validate block unblock]

  def index
    contacts = Contact.includes(:company).by_name
    contacts = contacts.where(company_id: params[:company_id]) if params[:company_id].present?
    contacts = contacts.where(state: params[:state]) if Contact.states.key?(params[:state])
    contacts = contacts.where("display_name ILIKE :q OR email ILIKE :q", q: search_pattern) if search_pattern
    @groups = contacts.to_a.group_by(&:company).sort_by { |company, _| [company&.validated? ? 0 : 1, company&.name.to_s.downcase] }
    @companies = Company.order(:name)
    stats = EmailParticipant.where(contact_id: contacts.select(:id)).joins(:email)
    @email_counts = stats.group(:contact_id).distinct.count(:email_id)
    @last_exchange = stats.group(:contact_id).maximum("emails.sent_at")
  end

  def new
    @contact = Contact.new(company_id: params[:company_id])
  end

  def create
    @contact = Contact.new(contact_params)
    @contact.company ||= Company.find_by(domain: @contact.email.to_s.split("@").last)
    @contact.state = @contact.validatable? ? :validated : :pending
    if @contact.save
      redirect_to contacts_path, notice: "Correspondant ajouté."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @contact.update(contact_params)
      redirect_to contacts_path, notice: "Correspondant modifié."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @contact.destroy
    redirect_to contacts_path, notice: "Correspondant supprimé.", status: :see_other
  end

  def validate
    unless @contact.validatable?
      return redirect_to contacts_path, alert: "Validez d'abord le domaine tiers #{@contact.company.name}."
    end

    @contact.display_name = params[:display_name] if params[:display_name].present?
    @contact.validated!
    redirect_back_or_to contacts_path, notice: "#{@contact.name} est validé."
  end

  # Expéditeur automatique (notification, newsletter) : ses fils ne s'affichent plus
  def block
    @contact.blocked!
    redirect_back_or_to contacts_path, notice: "#{@contact.name} est bloqué : les fils dont il est l'origine ne s'affichent plus."
  end

  def unblock
    @contact.update!(state: @contact.validatable? ? :validated : :pending)
    redirect_back_or_to contacts_path, notice: "#{@contact.name} est débloqué."
  end

  private

  def set_contact
    @contact = Contact.find(params[:id])
  end

  def contact_params
    params.expect(contact: [:display_name, :email, :company_id])
  end
end
