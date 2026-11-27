# Collaborateurs : les adresses du domaine de l'organisation, listées dans « Mon domaine ».
# Il n'y a rien à valider ; on peut seulement corriger le nom affiché.
class EmployeesController < ApplicationController
  before_action :set_employee

  def edit
  end

  def update
    if @employee.update(params.expect(employee: [:display_name]))
      redirect_to organization_path, notice: "Collaborateur modifié."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end
end
