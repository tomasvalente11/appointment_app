FactoryBot.define do
  factory :availability_slot do
    day_of_week { 1 }
    end_time    { "17:00" }
    nutritionist
    start_time  { "09:00" }
  end
end
