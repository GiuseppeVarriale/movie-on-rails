class CreateImports < ActiveRecord::Migration[8.1]
  def change
    create_table :imports do |t|
      t.string :kind, null: false
      t.string :status, null: false, default: "pending"
      t.string :source_path, null: false
      t.string :file_checksum, null: false
      t.integer :rows_processed, null: false, default: 0
      t.integer :rows_failed, null: false, default: 0
      t.jsonb :failures, null: false, default: []
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end
    add_index :imports, :file_checksum, unique: true, where: "status = 'completed'",
              name: "index_imports_on_completed_file_checksum"
  end
end
