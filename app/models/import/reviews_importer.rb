class Import::ReviewsImporter < Import::CsvImporter
  private

  def kind
    "reviews"
  end

  def prepare_batch(csv_rows)
    titles = csv_rows.map { |csv_row| csv_row["movie"].to_s.squish }.uniq
    @movies = Movie.where(title: titles).index_by(&:title)
  end

  def build_row(csv_row)
    title = csv_row["movie"].to_s.squish
    movie = @movies[title]
    review = Review.new(movie:, reviewer_name: csv_row["user"], stars: csv_row["stars"], body: csv_row["review"])
    return [ review, [ I18n.t("imports.errors.movie_not_found", title:) ] ] unless movie

    [ review, validation_errors(review) ]
  end

  def save(reviews)
    Review.insert_all(reviews.map { |review| review.slice(:movie_id, :reviewer_name, :stars, :body) })
  end
end
