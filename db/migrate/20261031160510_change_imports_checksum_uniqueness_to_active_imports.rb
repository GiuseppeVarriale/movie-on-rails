class ChangeImportsChecksumUniquenessToActiveImports < ActiveRecord::Migration[8.1]
  def change
    remove_index :imports, :file_checksum, unique: true, where: "status = 'completed'",
                 name: "index_imports_on_completed_file_checksum"
    add_index :imports, :file_checksum, unique: true, where: "status IN ('running', 'completed')",
              name: "index_imports_on_active_file_checksum"
  end
end
