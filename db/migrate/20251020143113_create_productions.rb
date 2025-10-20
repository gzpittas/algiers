class CreateProductions < ActiveRecord::Migration[8.0]
  def change
    create_table :productions do |t|
      t.string :name
      t.references :production_issue, null: false, foreign_key: true

      t.timestamps
    end
  end
end
