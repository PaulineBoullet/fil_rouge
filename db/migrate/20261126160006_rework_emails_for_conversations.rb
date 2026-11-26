# Un mail n'appartient plus à un contact et à un collaborateur : ses adresses sont dans
# email_participants, et il est rattaché à un fil reconstitué par les en-têtes
# In-Reply-To et References.
#
# Reprise des données V1 : chaque mail reçoit deux participants, son contact (expéditeur)
# et son collaborateur (destinataire). Les mails V1 restent sans fil : il faut relancer
# bin/rails db:seed pour obtenir des données V2 complètes.
class ReworkEmailsForConversations < ActiveRecord::Migration[8.1]
  def up
    add_reference :emails, :conversation, foreign_key: true
    add_column :emails, :in_reply_to, :string
    add_column :emails, :reference_ids, :string, array: true, null: false, default: []
    add_column :emails, :attachments_count, :integer, null: false, default: 0
    add_index :emails, :in_reply_to
    add_index :emails, :reference_ids, using: :gin

    execute <<~SQL
      INSERT INTO email_participants (email_id, role, address, name, contact_id, created_at, updated_at)
      SELECT emails.id, 'from', contacts.email, NULL, contacts.id, NOW(), NOW()
      FROM emails JOIN contacts ON contacts.id = emails.contact_id
    SQL
    execute <<~SQL
      INSERT INTO email_participants (email_id, role, address, name, employee_id, created_at, updated_at)
      SELECT emails.id, 'to', employees.email, NULL, employees.id, NOW(), NOW()
      FROM emails JOIN employees ON employees.id = emails.employee_id
    SQL

    remove_reference :emails, :contact, foreign_key: true, index: true
    remove_reference :emails, :employee, foreign_key: true, index: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
