class Import::Dispatcher
  class FileNotFoundError < StandardError; end

  IMPORTERS_IN_ORDER = {
    "movies" => Import::MoviesImporter,
    "reviews" => Import::ReviewsImporter
  }.freeze

  Result = Data.define(:path, :kind, :import) do
    def skipped?
      import.nil?
    end
  end

  def self.call(paths)
    new(paths).call
  end

  def self.check!(paths)
    new(paths).check!
  end

  def initialize(paths)
    @paths = Array(paths).map(&:to_s)
  end

  def call
    check!.map { |path, kind| import(path, kind) }
  end

  def check!
    files_by_kind = paths.map { |path| [ path, detect_kind(path) ] }.group_by(&:last)

    IMPORTERS_IN_ORDER.keys.flat_map { |kind| files_by_kind.fetch(kind, []) }
  end

  private

  attr_reader :paths

  def detect_kind(path)
    raise FileNotFoundError, I18n.t("imports.errors.file_not_found", path:) unless File.file?(path)

    Import::KindDetector.call(path)
  end

  def import(path, kind)
    Result.new(path:, kind:, import: IMPORTERS_IN_ORDER.fetch(kind).call(path))
  rescue Import::CsvImporter::AlreadyImportedError
    Result.new(path:, kind:, import: nil)
  end
end
