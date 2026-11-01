require "csv"

class Import::CsvImporter
  class AlreadyImportedError < StandardError; end

  BATCH_SIZE = 1_000
  MAX_FAILURES = 1_000

  def self.call(path, batch_size: BATCH_SIZE)
    new(path, batch_size:).call
  end

  def initialize(path, batch_size: BATCH_SIZE)
    @path = path.to_s
    @batch_size = batch_size
  end

  def call
    @import = start_import

    each_batch { |lines| import_batch(lines) }

    import.update!(status: :completed, finished_at: Time.current)
    import
  rescue StandardError
    import&.update_columns(status: "failed", finished_at: Time.current) if import&.persisted?
    raise
  end

  private

  attr_reader :path, :batch_size, :import

  def kind
    raise NotImplementedError
  end

  def build_row(_csv_row)
    raise NotImplementedError
  end

  def save(_rows)
    raise NotImplementedError
  end

  def prepare_batch(_csv_rows); end

  def validation_errors(*records)
    records.reject { |record| record.valid?(:import) }.flat_map { |record| record.errors.full_messages }
  end

  def start_import
    checksum = Digest::SHA256.file(path).hexdigest
    raise already_imported if Import.active.exists?(file_checksum: checksum)

    Import.create!(kind:, source_path: path, file_checksum: checksum, status: :running, started_at: Time.current)
  rescue ActiveRecord::RecordNotUnique
    raise already_imported
  rescue ActiveRecord::RecordInvalid => error
    raise already_imported if error.record.errors.of_kind?(:file_checksum, :taken)

    raise
  end

  def already_imported
    AlreadyImportedError.new(I18n.t("imports.errors.already_imported", path:))
  end

  def each_batch(&)
    CSV.foreach(path, headers: true, encoding: "bom|utf-8", header_converters: Import::KindDetector::NORMALIZE_HEADER)
       .with_index(2)
       .each_slice(batch_size, &)
  end

  def import_batch(lines)
    prepare_batch(lines.map(&:first))

    failures = []
    rows = lines.filter_map do |csv_row, line|
      row, errors = build_row(csv_row)
      next row if errors.empty?

      failures << { "line" => line, "errors" => errors }
      nil
    end

    ApplicationRecord.transaction { save(rows) } if rows.any?

    import.update!(
      rows_processed: import.rows_processed + lines.size,
      rows_failed: import.rows_failed + failures.size,
      failures: (import.failures + failures).first(MAX_FAILURES)
    )
  end
end
