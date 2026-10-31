class AddTrigramIndexToActorsName < ActiveRecord::Migration[8.1]
  def change
    add_index :actors, "(name::text) gin_trgm_ops", using: :gin, name: "index_actors_on_name_trigram"
  end
end
