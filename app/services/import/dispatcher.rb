class Import::Dispatcher
  class FileNotFoundError < StandardError; end

  IMPORTERS = {
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
    files_in_import_order.map { |path, kind| import(path, kind) }
  end

  def check!
    files_in_import_order
    true
  end

  private

  attr_reader :paths

  def files_in_import_order
    paths.map { |path| [ path, detect_kind(path) ] }
         .each_with_index
         .sort_by { |(_path, kind), position| [ IMPORTERS.keys.index(kind), position ] }
         .map(&:first)
  end

  def detect_kind(path)
    raise FileNotFoundError, I18n.t("imports.errors.file_not_found", path:) unless File.file?(path)

    Import::KindDetector.call(path)
  end

  def import(path, kind)
    Result.new(path:, kind:, import: IMPORTERS.fetch(kind).call(path))
  rescue Import::CsvImporter::AlreadyImportedError
    Result.new(path:, kind:, import: nil)
  end
end
