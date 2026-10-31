class CreateActors < ActiveRecord::Migration[8.1]
  def change
    create_table :actors do |t|
      t.citext :name, null: false

      t.timestamps
    end
    add_index :actors, :name, unique: true
  end
end
