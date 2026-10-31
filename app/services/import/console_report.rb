class Import::ConsoleReport
  MAX_FAILURES_SHOWN = 5

  def self.for_results(results)
    results.flat_map { |result| new.result_lines(result) }
  end

  def self.for_imports(imports)
    return [ I18n.t("imports.report.no_imports") ] if imports.empty?

    imports.map { |import| new.import_line(import) }
  end

  def result_lines(result)
    return [ I18n.t("imports.report.skipped", kind: result.kind, path: result.path) ] if result.skipped?

    [ summary(result.import) ] + failure_lines(result.import)
  end

  def import_line(import)
    I18n.t("imports.report.status_line", id: import.id, created_at: I18n.l(import.created_at, format: :short),
                                         summary: summary(import))
  end

  private

  def summary(import)
    I18n.t("imports.report.imported", kind: import.kind, path: import.source_path, status: import.status,
                                      processed: import.rows_processed, failed: import.rows_failed)
  end

  def failure_lines(import)
    lines = import.failures.first(MAX_FAILURES_SHOWN).map do |failure|
      I18n.t("imports.report.failure", line: failure["line"], errors: failure["errors"].to_sentence)
    end
    hidden = import.rows_failed - lines.size
    hidden.positive? ? lines + [ I18n.t("imports.report.more_failures", count: hidden) ] : lines
  end
end
