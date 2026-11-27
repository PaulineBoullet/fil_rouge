# Mon domaine : nom de l'organisation affiché en haut à gauche, et couleur du thème.
class AddNameAndThemeToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :org_name, :string
    add_column :settings, :theme_color, :string, null: false, default: "#3A908F"
  end
end
