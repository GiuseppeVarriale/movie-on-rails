class CreateMovieActors < ActiveRecord::Migration[8.1]
  def change
    create_table :movie_actors do |t|
      t.references :movie, null: false, foreign_key: true, index: false
      t.references :actor, null: false, foreign_key: true

      t.timestamps
    end
    add_index :movie_actors, [ :movie_id, :actor_id ], unique: true
  end
end
