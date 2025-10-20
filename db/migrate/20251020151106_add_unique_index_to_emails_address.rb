class AddUniqueIndexToEmailsAddress < ActiveRecord::Migration[8.0]
  def change
    add_index :emails, :address, unique: true
  end
end