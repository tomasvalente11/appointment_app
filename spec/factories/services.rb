FactoryBot.define do
  factory :service do
    duration  { 60 }
    latitude  { 41.5513 }
    location  { "Braga" }
    longitude { -8.4205 }
    name      { "First Appointment" }
    nutritionist
    price     { 50.00 }
  end

  trait :porto do
    latitude  { 41.1483 }
    location  { "Porto" }
    longitude { -8.6108 }
  end
end
