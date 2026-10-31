FactoryBot.define do
  factory :actor do
    sequence(:name) { |n| "Actor #{n}" }
  end
end
