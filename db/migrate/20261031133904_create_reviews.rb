class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :movie, null: false, foreign_key: true
      t.string :reviewer_name, null: false
      t.integer :stars, null: false
      t.text :body

      t.timestamps
    end
  end
end
