# Réglages de l'organisation : une seule ligne, le domaine de l'organisation.
class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :settings do |t|
      t.string :org_domain
      t.timestamps
    end
  end
end
