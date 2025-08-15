FactoryBot.define do
  factory :invoice do
    sequence(:invoice_number) { |n| "INV-#{Date.current.year}-#{n.to_s.rjust(4, '0')}" }
    invoice_date { 1.day.ago }
    total { Faker::Commerce.price(range: 100.0..5000.0, as_string: false) }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :high_value do
      total { Faker::Commerce.price(range: 5000.0..10000.0, as_string: false) }
    end

    trait :low_value do
      total { Faker::Commerce.price(range: 10.0..100.0, as_string: false) }
    end

    trait :recent do
      invoice_date { rand(1..7).days.ago }
    end

    trait :old do
      invoice_date { rand(30..90).days.ago }
    end
  end
end
