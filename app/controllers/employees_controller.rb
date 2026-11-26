# Paramètres – Collaborateurs : adresses du domaine de l'organisation.
class EmployeesController < ApplicationController
  before_action :set_employee, only: %i[edit update destroy validate]

  def index
    employees = Employee.by_name
    employees = employees.where("display_name ILIKE :q OR email ILIKE :q", q: search_pattern) if search_pattern
    @pending = employees.pending.to_a
    @validated = employees.validated.to_a
    stats = EmailParticipant.where(employee_id: @pending + @validated).joins(:email)
    @email_counts = stats.group(:employee_id).distinct.count(:email_id)
    @conversation_counts = stats.group(:employee_id).distinct.count("emails.conversation_id")
    @last_exchange = stats.group(:employee_id).maximum("emails.sent_at")
    @first_seen = stats.group(:employee_id).minimum("emails.sent_at")
  end

  def new
    @employee = Employee.new
  end

  def create
    @employee = Employee.new(employee_params.merge(state: :validated))
    if @employee.save
      redirect_to employees_path, notice: "Collaborateur ajouté."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @employee.update(employee_params)
      redirect_to employees_path, notice: "Collaborateur modifié."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @employee.destroy
    redirect_to employees_path, notice: "Collaborateur supprimé.", status: :see_other
  end

  def validate
    @employee.display_name = params[:display_name] if params[:display_name].present?
    @employee.validated!
    redirect_to employees_path, notice: "#{@employee.name} est validé."
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def employee_params
    params.expect(employee: [:display_name, :email])
  end
end
