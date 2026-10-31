class Import < ApplicationRecord
  enum :kind, { movies: "movies", reviews: "reviews" }, validate: true
  enum :status, { pending: "pending", running: "running", completed: "completed", failed: "failed" },
       default: :pending, validate: true

  scope :active, -> { where(status: %i[running completed]) }

  validates :source_path, presence: true
  validates :file_checksum, presence: true, format: { with: /\A\h{64}\z/ }
  validates :file_checksum, uniqueness: { conditions: -> { active } }, if: :active?
  validates :rows_processed, :rows_failed, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def active?
    running? || completed?
  end
end
