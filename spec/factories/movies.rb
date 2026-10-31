FactoryBot.define do
  factory :movie do
    sequence(:title) { |n| "Movie #{n}" }
    description { "A thief who steals corporate secrets through dream-sharing technology." }
    year { 2010 }
    director { "Christopher Nolan" }
  end
end
