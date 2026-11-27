# Points clés d'un fil, rédigés par l'IA avec sa synthèse
class AddKeyPointsToConversations < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :key_points, :jsonb, null: false, default: []
  end
end
