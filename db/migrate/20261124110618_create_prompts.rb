class CreatePrompts < ActiveRecord::Migration[8.1]
  def change
    create_table :prompts do |t|
      t.string :name, null: false
      t.text :content, null: false

      t.timestamps
    end
  end
end
