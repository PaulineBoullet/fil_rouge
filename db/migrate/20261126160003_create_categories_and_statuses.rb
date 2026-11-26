# Listes définies dans les réglages de l'IA. Chaque valeur porte une description
# qui explique à l'IA quand la choisir. Les statuts sont rangés par priorité
# (rank 1 = le plus urgent).
class CreateCategoriesAndStatuses < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :statuses do |t|
      t.string :name, null: false
      t.text :description
      t.integer :rank, null: false
      t.timestamps
    end
    add_index :statuses, :rank
  end
end
