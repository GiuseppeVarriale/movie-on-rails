require "csv"

class Import::KindDetector
  class UnknownFormatError < StandardError; end

  HEADERS = {
    "movies" => [ "movie", "description", "year", "director", "actor", "filming location", "country" ],
    "reviews" => [ "movie", "user", "stars", "review" ]
  }.freeze

  def self.call(path)
    new(path).call
  end

  def initialize(path)
    @path = path
  end

  def call
    headers = read_headers
    kind, _expected = HEADERS.find { |_kind, expected| expected.sort == headers.sort }

    kind || raise(UnknownFormatError, unknown_headers_message(headers))
  end

  private

  attr_reader :path

  def read_headers
    first_line = File.open(path, encoding: "bom|utf-8", &:gets)
    raise UnknownFormatError, I18n.t("imports.errors.empty_file", path:, expected: accepted_formats) if first_line.blank?

    CSV.parse_line(first_line).map { |header| header.to_s.squish.downcase }
  rescue CSV::MalformedCSVError
    raise UnknownFormatError, I18n.t("imports.errors.not_csv", path:, expected: accepted_formats)
  end

  def unknown_headers_message(headers)
    I18n.t("imports.errors.unknown_format", path:, headers: headers.join(", "), expected: accepted_formats)
  end

  def accepted_formats
    HEADERS.map { |kind, columns| "#{kind} (#{columns.map(&:capitalize).join(', ')})" }.join("; ")
  end
end
