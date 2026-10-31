class MovieSearch
  SORTS = {
    "rating" => [ Arel.sql("average_stars DESC NULLS LAST"), { id: :desc } ],
    "title" => [ { title: :asc } ],
    "newest" => [ { year: :desc }, { id: :desc } ]
  }.freeze
  DEFAULT_SORT = "rating"

  attr_reader :sort

  def initialize(sort: nil)
    @sort = SORTS.key?(sort) ? sort : DEFAULT_SORT
  end

  def results
    Movie.order(*SORTS.fetch(sort)).includes(:actors, :filming_locations)
  end
end
