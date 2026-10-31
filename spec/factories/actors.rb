FactoryBot.define do
  factory :actor do
    sequence(:name) { |n| "#{Faker::Name.name} #{n}" }
  end
end
