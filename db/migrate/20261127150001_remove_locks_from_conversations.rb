# La priorité et la catégorie d'un fil sont choisies uniquement par l'IA : plus de verrou manuel.
class RemoveLocksFromConversations < ActiveRecord::Migration[8.1]
  def change
    remove_column :conversations, :status_locked, :boolean, default: false, null: false
    remove_column :conversations, :category_locked, :boolean, default: false, null: false
  end
end
