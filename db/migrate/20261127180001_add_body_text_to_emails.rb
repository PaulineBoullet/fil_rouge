# Texte du mail seul (sans en-têtes ni pièces jointes encodées), pour la recherche.
# Rempli à l'import ; les mails déjà en base sont relus ici une fois.
class AddBodyTextToEmails < ActiveRecord::Migration[8.1]
  class MigrationEmail < ActiveRecord::Base
    self.table_name = "emails"
  end

  def up
    add_column :emails, :body_text, :text

    MigrationEmail.reset_column_information
    MigrationEmail.find_each do |email|
      email.update_columns(body_text: EmlReader.body_text(Mail.new(email.content.to_s)))
    rescue StandardError
      next
    end
  end

  def down
    remove_column :emails, :body_text
  end
end
