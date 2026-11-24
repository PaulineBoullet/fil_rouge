class CreateEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :emails do |t|
      t.references :contact, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.string :message_id
      t.string :subject
      t.text :content
      t.text :summary
      t.datetime :sent_at

      t.timestamps
    end
    add_index :emails, :message_id, unique: true
    add_index :emails, :sent_at
  end
end
