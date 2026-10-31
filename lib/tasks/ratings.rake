namespace :ratings do
  desc "Recalculate every movie's ratings from its reviews"
  task recalculate: :environment do
    puts I18n.t("ratings.recalculated", count: Movie::RatingsRecalculator.call)
  end
end
