FactoryBot.define do
  factory :filming_location do
    sequence(:name) { |n| "#{Faker::Address.city} #{n}" }
    country { Faker::Address.country_code }
  end
end
