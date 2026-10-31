namespace :import do
  desc 'Import CSV files, detecting each kind from its headers: bin/rails import:csv FILES="movies.csv reviews.csv"'
  task csv: :environment do
    paths = ENV.fetch("FILES", "").split
    abort I18n.t("imports.rake.usage") if paths.empty?

    puts Import::ConsoleReport.for_results(Import::Dispatcher.call(paths))
  rescue Import::Dispatcher::FileNotFoundError, Import::KindDetector::UnknownFormatError => error
    abort error.message
  end

  desc "List the latest imports"
  task status: :environment do
    puts Import::ConsoleReport.for_imports(Import.order(id: :desc).limit(10))
  end
end
