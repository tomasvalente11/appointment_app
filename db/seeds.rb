nutritionists_data = [
  {
    avatar_url: "https://i.pravatar.cc/150?img=1",
    bio: "Specialist in sports nutrition and weight management with over 10 years of experience.",
    license_number: "ON-1234",
    name: "Ana Costa",
    services: [
      { address: "Avenida Central 10, Braga, Portugal", duration: 60, location: "Braga", name: "First Appointment", price: 55.00 },
      { address: "Rua do Souto 45, Braga, Portugal",   duration: 30, location: "Braga", name: "Follow-up",         price: 30.00 }
    ]
  },
  {
    avatar_url: "https://i.pravatar.cc/150?img=2",
    bio: "Focused on clinical nutrition and digestive health.",
    license_number: "ON-2345",
    name: "Bruno Ferreira",
    services: [
      { address: "Avenida dos Aliados 100, Porto, Portugal",   duration: 60, location: "Porto", name: "First Appointment",   price: 65.00 },
      { address: "Rua de Santa Catarina 200, Porto, Portugal", duration: 45, location: "Porto", name: "Follow-up",           price: 40.00 },
      { address: nil, duration: 45, location: "Remote", name: "Online Consultation", price: 35.00 }
    ]
  },
  {
    avatar_url: "https://i.pravatar.cc/150?img=3",
    bio: "Pediatric and family nutrition expert.",
    license_number: "ON-3456",
    name: "Carla Mendes",
    services: [
      { address: "Avenida da Liberdade 50, Lisboa, Portugal", duration: 60, location: "Lisboa", name: "First Appointment", price: 75.00 },
      { address: "Rua Augusta 30, Lisboa, Portugal",          duration: 30, location: "Lisboa", name: "Follow-up",         price: 45.00 }
    ]
  },
  {
    avatar_url: "https://i.pravatar.cc/150?img=4",
    bio: "Specialises in plant-based diets and chronic disease prevention.",
    license_number: "ON-4567",
    name: "David Rodrigues",
    services: [
      { address: "Rua Ferreira Borges 15, Coimbra, Portugal",   duration: 60, location: "Coimbra", name: "First Appointment",   price: 50.00 },
      { address: nil, duration: 45, location: "Remote", name: "Online Consultation", price: 30.00 }
    ]
  },
  {
    avatar_url: "https://i.pravatar.cc/150?img=6",
    bio: "Expert in gut health, microbiome nutrition, and personalised dietary plans for urban lifestyles.",
    license_number: "ON-6789",
    name: "Filipa Sousa",
    services: [
      { address: "Avenida da Liberdade 180, Lisboa, Portugal", duration: 60, location: "Lisboa", name: "First Appointment",   price: 80.00 },
      { address: "Rua do Ouro 100, Lisboa, Portugal",         duration: 30, location: "Lisboa", name: "Follow-up",           price: 50.00 },
      { address: nil,                                         duration: 45, location: "Remote", name: "Online Consultation", price: 45.00 }
    ]
  },
  {
    avatar_url: "https://i.pravatar.cc/150?img=5",
    bio: "Nutritionist focused on hormonal balance and women's health.",
    license_number: "ON-5678",
    name: "Elisa Nunes",
    services: [
      { address: "Avenida Central 45, Braga, Portugal", duration: 60, location: "Braga", name: "First Appointment",   price: 60.00 },
      { address: "Largo Carlos Amarante 2, Braga, Portugal", duration: 30, location: "Braga", name: "Follow-up",           price: 35.00 },
      { address: nil, duration: 45, location: "Remote", name: "Online Consultation", price: 40.00 }
    ]
  }
]

puts "Seeding nutritionists and services..."

nutritionists_data.each do |data|
  services_data = data.delete(:services)
  nutritionist = Nutritionist.find_or_create_by!(name: data[:name]) do |n|
    n.assign_attributes(data)
  end

  services_data.each do |s|
    next if nutritionist.services.exists?(name: s[:name], location: s[:location])
    sleep 1 # throttle to respect the public Geocoder API rate limit (~1 req/s for Nominatim)
    nutritionist.services.create!(s)
  end

  puts "  #{nutritionist.name} (#{nutritionist.services.count} services)"
end

puts "Seeding appointment requests..."

ana   = Nutritionist.find_by!(name: "Ana Costa")
bruno = Nutritionist.find_by!(name: "Bruno Ferreira")
carla = Nutritionist.find_by!(name: "Carla Mendes")

AppointmentRequest.find_or_create_by!(guest_email: "joao.silva@example.com", nutritionist: ana) do |r|
  r.guest_name   = "João Silva"
  r.requested_at = 2.days.from_now.change(hour: 10)
  r.service      = ana.services.first
  r.status       = :pending
end

AppointmentRequest.find_or_create_by!(guest_email: "maria.santos@example.com", nutritionist: bruno) do |r|
  r.guest_name   = "Maria Santos"
  r.requested_at = 3.days.from_now.change(hour: 14)
  r.service      = bruno.services.first
  r.status       = :pending
end

AppointmentRequest.find_or_create_by!(guest_email: "pedro.lima@example.com", nutritionist: carla) do |r|
  r.guest_name   = "Pedro Lima"
  r.requested_at = 1.day.ago.change(hour: 11)
  r.service      = carla.services.first
  r.status       = :accepted
end

AppointmentRequest.find_or_create_by!(guest_email: "sofia.gomes@example.com", nutritionist: ana) do |r|
  r.guest_name   = "Sofia Gomes"
  r.requested_at = 5.days.from_now.change(hour: 9)
  r.service      = ana.services.last
  r.status       = :rejected
end

AppointmentRequest.find_or_create_by!(guest_email: "rui.costa@example.com", nutritionist: bruno) do |r|
  r.guest_name   = "Rui Costa"
  r.requested_at = 4.days.from_now.change(hour: 16)
  r.service      = bruno.services.second
  r.status       = :pending
end

puts "Seeding availability slots..."

availability_data = {
  "Ana Costa"       => { days: [ 1, 2, 3, 4, 5 ], start: "09:00", end: "17:00" },
  "Bruno Ferreira"  => { days: [ 1, 3, 5 ],        start: "10:00", end: "18:00" },
  "Filipa Sousa"    => { days: [ 1, 2, 3, 4, 5 ], start: "09:00", end: "18:00" },
  "Carla Mendes"    => { days: [ 1, 2, 3, 4, 5 ], start: "08:00", end: "16:00" },
  "David Rodrigues" => { days: [ 2, 4 ],            start: "09:00", end: "13:00" },
  "Elisa Nunes"     => { days: [ 1, 2, 3, 4, 5 ], start: "09:00", end: "18:00" }
}

availability_data.each do |name, config|
  nutritionist = Nutritionist.find_by!(name: name)
  config[:days].each do |day|
    nutritionist.availability_slots.find_or_create_by!(day_of_week: day) do |slot|
      slot.start_time = config[:start]
      slot.end_time   = config[:end]
    end
  end
  puts "  #{name} (#{nutritionist.availability_slots.count} days)"
end

puts "Done. #{Nutritionist.count} nutritionists, #{Service.count} services, #{AppointmentRequest.count} appointment requests, #{AvailabilitySlot.count} availability slots."

puts "Syncing Algolia search index..."
NutritionistSearch.reindex_all
puts "Algolia index synced."
