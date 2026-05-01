Geocoder.configure(lookup: :test)

Geocoder::Lookup::Test.set_default_stub([ { coordinates: [ 41.5513, -8.4205 ] } ])

Geocoder::Lookup::Test.add_stub("Braga, Portugal",  [ { coordinates: [ 41.5513, -8.4205 ] } ])
Geocoder::Lookup::Test.add_stub("Porto, Portugal",  [ { coordinates: [ 41.1483, -8.6108 ] } ])
Geocoder::Lookup::Test.add_stub("Lisboa, Portugal", [ { coordinates: [ 38.7169, -9.1395 ] } ])
Geocoder::Lookup::Test.add_stub("Coimbra, Portugal", [ { coordinates: [ 40.2033, -8.4103 ] } ])
Geocoder::Lookup::Test.add_stub("Braga",            [ { coordinates: [ 41.5513, -8.4205 ] } ])
Geocoder::Lookup::Test.add_stub("Porto",            [ { coordinates: [ 41.1483, -8.6108 ] } ])
