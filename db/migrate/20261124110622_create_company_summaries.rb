class CreateCompanySummaries < ActiveRecord::Migration[8.1]
  def change
    create_table :company_summaries do |t|
      t.references :company, null: false, foreign_key: true
      t.text :summary
      t.datetime :generated_at

      t.timestamps
    end
  end
end
