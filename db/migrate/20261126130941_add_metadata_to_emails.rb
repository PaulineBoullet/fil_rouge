class AddMetadataToEmails < ActiveRecord::Migration[8.1]
  def change
    add_column :emails, :metadata, :jsonb, default: {}, null: false
  end
end
