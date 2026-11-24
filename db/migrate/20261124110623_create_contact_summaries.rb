class CreateContactSummaries < ActiveRecord::Migration[8.1]
  def change
    create_table :contact_summaries do |t|
      t.references :contact, null: false, foreign_key: true
      t.text :summary
      t.datetime :generated_at

      t.timestamps
    end
  end
end
