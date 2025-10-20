class CreateEmails < ActiveRecord::Migration[8.0]
  def change
    create_table :emails do |t|
      t.string :address
      t.references :production, null: false, foreign_key: true

      t.timestamps
    end
  end
end
