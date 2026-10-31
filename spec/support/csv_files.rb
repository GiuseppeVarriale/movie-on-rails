module CsvFiles
  def csv_file(content)
    file = Tempfile.new([ "import", ".csv" ])
    file.write(content)
    file.flush
    csv_tempfiles << file
    file.path
  end

  def csv_tempfiles
    @csv_tempfiles ||= []
  end
end

RSpec.configure do |config|
  config.include CsvFiles
  config.after { csv_tempfiles.each(&:close!) }
end
