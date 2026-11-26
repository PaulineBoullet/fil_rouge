# Un fil de conversation : les mails qui se répondent, rattachés à un seul domaine tiers.
class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :company, foreign_key: true                          # vide pour un fil interne
      t.references :origin_contact, foreign_key: { to_table: :contacts } # premier correspondant du fil
      t.references :category, foreign_key: true
      t.references :status, foreign_key: true
      t.string :title
      t.boolean :hidden, null: false, default: false
      t.boolean :internal, null: false, default: false
      t.boolean :status_locked, null: false, default: false    # statut choisi à la main : l'IA ne le remplace pas
      t.boolean :category_locked, null: false, default: false  # idem pour la catégorie
      t.datetime :first_email_at
      t.datetime :last_email_at
      t.text :summary
      t.datetime :summary_generated_at
      t.timestamps
    end
    add_index :conversations, :last_email_at
  end
end
