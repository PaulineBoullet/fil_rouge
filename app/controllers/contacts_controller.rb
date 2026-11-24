class ContactsController < ApplicationController
  before_action :set_contact, only: %i[show edit update destroy]
  before_action :set_date, only: :show

  def index
    @contacts = Contact.includes(:company).order(:last_name, :first_name)
  end

  def show
    @summary = @contact.contact_summaries.where(generated_at: @date.all_day).order(:generated_at).last
    @emails = @contact.emails
                      .where(sent_at: @date.all_day)
                      .includes(:employee)
                      .order(sent_at: :desc)
  end

  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)
    if @contact.save
      redirect_to contacts_path, notice: "Contact ajouté."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @contact.update(contact_params)
      redirect_to contacts_path, notice: "Contact modifié."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @contact.destroy
    redirect_to contacts_path, notice: "Contact supprimé.", status: :see_other
  end

  private

  def set_contact
    @contact = Contact.find(params[:id])
  end

  def contact_params
    params.expect(contact: [:first_name, :last_name, :email, :company_id])
  end
end
