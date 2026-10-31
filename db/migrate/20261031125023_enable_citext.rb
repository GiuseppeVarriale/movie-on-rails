class EnableCitext < ActiveRecord::Migration[8.1]
  # Case-insensitive text: names compare without regard to case but keep
  # their original casing (used for names that identify associated records).
  def change
    enable_extension "citext"
  end
end
