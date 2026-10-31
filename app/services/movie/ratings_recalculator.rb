class Movie::RatingsRecalculator
  def self.call
    new.call
  end

  def call
    Movie.transaction do
      Movie.order(:id).lock.ids
      Movie.update_all(ratings_sum: total("COALESCE(SUM(reviews.stars), 0)"), ratings_count: total("COUNT(*)"))
    end
  end

  private

  def total(expression)
    Arel.sql("(#{Review.where('reviews.movie_id = movies.id').select(expression).to_sql})")
  end
end
