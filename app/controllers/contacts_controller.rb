# Correspondants : regroupés par domaine tiers dans la page Domaines tiers, validés un par un.
class ContactsController < ApplicationController
  before_action :set_contact, only: %i[edit update destroy validate block unblock]

  # Les correspondants sont listés dans la page Domaines tiers
  def index
    redirect_to companies_path(**params.permit(:company_id, :state).to_h.symbolize_keys, anchor: "correspondants")
  end

  def new
    @contact = Contact.new(company_id: params[:company_id])
  end

  def create
    @contact = Contact.new(contact_params)
    @contact.company ||= Company.find_by(domain: @contact.email.to_s.split("@").last)
    @contact.state = @contact.validatable? ? :validated : :pending
    if @contact.save
      redirect_to companies_path(anchor: "correspondants"), notice: "Correspondant ajouté."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @contact.update(contact_params)
      redirect_to companies_path(anchor: "correspondants"), notice: "Correspondant modifié."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @contact.destroy
    redirect_to companies_path(anchor: "correspondants"), notice: "Correspondant supprimé.", status: :see_other
  end

  def validate
    unless @contact.validatable?
      return redirect_to companies_path(anchor: "correspondants"), alert: "Validez d'abord le domaine tiers #{@contact.company.name}."
    end

    @contact.display_name = params[:display_name] if params[:display_name].present?
    @contact.validated!
    redirect_back_or_to companies_path(anchor: "correspondants"), notice: "#{@contact.name} est validé."
  end

  # Expéditeur automatique (notification, newsletter) : ses fils ne s'affichent plus
  def block
    @contact.blocked!
    redirect_back_or_to companies_path(anchor: "correspondants"), notice: "#{@contact.name} est bloqué : les fils dont il est l'origine ne s'affichent plus."
  end

  def unblock
    @contact.update!(state: @contact.validatable? ? :validated : :pending)
    redirect_back_or_to companies_path(anchor: "correspondants"), notice: "#{@contact.name} est débloqué."
  end

  private

  def set_contact
    @contact = Contact.find(params[:id])
  end

  def contact_params
    params.expect(contact: [:display_name, :email, :company_id])
  end
end
