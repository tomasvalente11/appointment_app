FactoryBot.define do
  factory :appointment_request do
    guest_email  { "guest@example.com" }
    guest_name   { "Test Guest" }
    nutritionist
    requested_at { 1.week.from_now.change(hour: 10, min: 0, sec: 0) }
    status       { :pending }
  end
end
