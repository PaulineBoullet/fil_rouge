# Mails que l'import n'a pas pu intégrer (fichier illisible…). Consultation seule.
class CreateImportFailures < ActiveRecord::Migration[8.1]
  def change
    create_table :import_failures do |t|
      t.string :filename, null: false
      t.text :reason
      t.integer :attempts, null: false, default: 1
      t.datetime :last_attempt_at
      t.timestamps
    end
    add_index :import_failures, :filename, unique: true
  end
end
