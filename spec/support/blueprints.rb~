User.blueprint {
  name { Faker::Name.name }
  pic { "http://#{sn}" }
  remote_accounts { [RemoteAccount.make] }
  accepted_terms { true }
  created_at { Time.now }
  updated_at { Time.now }
}

RemoteAccount.blueprint {
  account_type { :google }
  identifier { "identifier#{sn}" }
  email { "email#{sn}" }
  token { "token#{sn}" }
}

Contact.blueprint {
  first_name { Faker::Name.first_name }
  last_name { Faker::Name.last_name }
  name { Faker::Name.name }
  pic { "http://#{sn}" }
  encrypted_addresses do
    # generated encrypted addresses
    ["123#{sn} Main St., City, State, USA", "ABCstr #{sn}, Munich, Germany"].collect do |a|
      BSON::Binary.new(Blowfish.encrypt(ENCRYPTION_KEY, a))
    end
  end
  remote_id { "REMOTE_ID#{sn}" }
  created_at { Time.now }
  updated_at { Time.now }
}

Trip.blueprint {
  location_name { Faker::Address.city }
  description { "My trip to #{self.location_name}" }
  start_date { Time.now }
  status { :active }
}