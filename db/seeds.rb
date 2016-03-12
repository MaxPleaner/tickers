# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


root_url = Rails.env.production? ? "maxp-tickers.herokuapp.com" : "localhost:3000"
Ticker.create(
  name: "test",
  interval: 1000,
  content: "`curl \"#{root_url}/update_output?name=test&password=#{ENV["password"]}&output=\#{SecureRandom.urlsafe_base64}\"`\r\n\r\n# do not use \"exit\"\r\n# and do not raise any errors, or zombie processes may result\r\n"
)