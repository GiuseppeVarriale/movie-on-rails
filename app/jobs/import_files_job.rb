class ImportFilesJob < ApplicationJob
  queue_as :imports
  sidekiq_options retry: false

  def perform(paths)
    results = Import::Dispatcher.call(paths)
    Import::ConsoleReport.for_results(results).each { |line| logger.info(line) }
  end
end
