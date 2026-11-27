# Plus d'écran « Mails en erreur » : les échecs d'import s'affichent dans la console du seed.
class DropImportFailures < ActiveRecord::Migration[8.1]
  def change
    drop_table :import_failures do |t|
      t.string :filename, null: false
      t.text :reason
      t.integer :attempts, null: false, default: 1
      t.datetime :last_attempt_at
      t.timestamps
      t.index :filename, unique: true
    end
  end
end
