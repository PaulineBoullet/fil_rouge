# Les collaborateurs ne se valident plus : toute adresse du domaine de l'organisation
# est un collaborateur, simplement listé dans la page « Mon domaine ».
class RemoveStateFromEmployees < ActiveRecord::Migration[8.1]
  def change
    remove_index :employees, :state
    remove_column :employees, :state, :string, null: false, default: "pending"
  end
end
