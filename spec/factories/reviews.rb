FactoryBot.define do
  factory :review do
    movie
    reviewer_name { Faker::Name.name }
    stars { Faker::Number.between(from: Review::MIN_STARS, to: Review::MAX_STARS) }
    body { Faker::Lorem.sentence }
  end
end
