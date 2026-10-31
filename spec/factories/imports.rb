FactoryBot.define do
  factory :import do
    kind { :movies }
    source_path { Faker::File.file_name(ext: "csv") }
    file_checksum { Faker::Crypto.sha256 }

    trait :completed do
      status { :completed }
      started_at { 1.minute.ago }
      finished_at { Time.current }
    end
  end
end
