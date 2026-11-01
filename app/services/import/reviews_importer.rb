class Import::ReviewsImporter < Import::CsvImporter
  private

  def kind
    "reviews"
  end

  def prepare_batch(csv_rows)
    titles = csv_rows.map { |csv_row| title_of(csv_row) }.uniq
    @movies = Movie.where(title: titles).index_by(&:title)
  end

  def build_row(csv_row)
    title = title_of(csv_row)
    movie = @movies[title]
    review = Review.new(movie:, reviewer_name: csv_row["user"], stars: csv_row["stars"], body: csv_row["review"])
    return [ review, [ I18n.t("imports.errors.movie_not_found", title:) ] ] unless movie

    [ review, validation_errors(review) ]
  end

  def title_of(csv_row)
    csv_row["movie"].to_s.squish
  end

  def save(reviews)
    Review.insert_all(reviews.map { |review| review.slice(:movie_id, :reviewer_name, :stars, :body) })
    add_to_movie_ratings(reviews)
  end

  def add_to_movie_ratings(reviews)
    totals = reviews.group_by(&:movie_id).transform_values do |movie_reviews|
      Movie::RatingTotal.new(stars: movie_reviews.sum(&:stars), count: movie_reviews.size)
    end
    Movie.add_ratings(totals)
  end
end
