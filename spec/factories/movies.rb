FactoryBot.define do
  factory :movie do
    sequence(:title) { |n| "#{Faker::Movie.title} #{n}" }
    description { Faker::Lorem.paragraph }
    year { Faker::Number.between(from: Movie::FIRST_FILM_YEAR, to: Date.current.year) }
    director { Faker::Name.name }
  end
end
