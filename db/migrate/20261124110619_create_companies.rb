class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.references :prompt, null: true, foreign_key: true
      t.string :name, null: false
      t.string :domain, null: false

      t.timestamps
    end
    add_index :companies, :domain, unique: true
  end
end
