class CreateFilmingLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :filming_locations do |t|
      t.citext :name, null: false
      t.string :country, null: false

      t.timestamps
    end
    add_index :filming_locations, [ :name, :country ], unique: true
  end
end
