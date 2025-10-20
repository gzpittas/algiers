class CreateProductionIssues < ActiveRecord::Migration[8.0]
  def change
    create_table :production_issues do |t|
      t.string :issue_number
      t.date :issue_date
      t.string :file_name

      t.timestamps
    end
  end
end
