# Les collaborateurs, domaines tiers et correspondants sont découverts par l'import
# et proposés « à valider ». Les noms sont pré-remplis depuis les en-têtes des mails
# (display_name) ; prénom et nom deviennent facultatifs.
class AddValidationStates < ActiveRecord::Migration[8.1]
  def change
    add_column :employees, :state, :string, null: false, default: "pending"
    add_column :employees, :display_name, :string
    change_column_null :employees, :first_name, true
    change_column_null :employees, :last_name, true
    add_index :employees, :state

    add_column :companies, :state, :string, null: false, default: "pending"
    add_index :companies, :state

    add_column :contacts, :state, :string, null: false, default: "pending"
    add_column :contacts, :display_name, :string
    change_column_null :contacts, :first_name, true
    change_column_null :contacts, :last_name, true
    add_index :contacts, :state

    # Les données saisies à la main en V1 sont considérées comme validées.
    reversible do |dir|
      dir.up do
        execute "UPDATE employees SET state = 'validated'"
        execute "UPDATE companies SET state = 'validated'"
        execute "UPDATE contacts SET state = 'validated'"
      end
    end
  end
end
