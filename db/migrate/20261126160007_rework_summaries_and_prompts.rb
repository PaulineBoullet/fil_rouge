# - company_summaries : une synthèse par domaine tiers et par jour (colonne day).
# - contact_summaries : supprimée, remplacée par la synthèse du fil.
# - prompts : un prompt par défaut, utilisé pour les domaines tiers sans prompt spécifique.
class ReworkSummariesAndPrompts < ActiveRecord::Migration[8.1]
  def up
    add_column :company_summaries, :day, :date
    execute "UPDATE company_summaries SET day = DATE(generated_at) WHERE generated_at IS NOT NULL"
    # Une seule synthèse par jour : on garde la plus récente
    execute <<~SQL
      DELETE FROM company_summaries a
      USING company_summaries b
      WHERE a.company_id = b.company_id AND a.day = b.day AND a.id < b.id
    SQL
    add_index :company_summaries, [:company_id, :day], unique: true

    drop_table :contact_summaries

    add_column :prompts, :is_default, :boolean, null: false, default: false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
