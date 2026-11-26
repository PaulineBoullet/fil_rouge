# Une ligne par adresse d'un mail (expéditeur, destinataires, copies), reliée au
# collaborateur ou au correspondant reconnu à partir de cette adresse.
class CreateEmailParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :email_participants do |t|
      t.references :email, null: false, foreign_key: true
      t.string :role, null: false        # from, to, cc
      t.string :address, null: false
      t.string :name
      t.references :employee, foreign_key: true
      t.references :contact, foreign_key: true
      t.timestamps
    end
    add_index :email_participants, [:email_id, :role]
    add_index :email_participants, :address
  end
end
