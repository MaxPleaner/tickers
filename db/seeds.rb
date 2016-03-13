# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


if Ticker.count.eql?(0)
	Ticker.create(
	  name: "test",
	  interval: 1000,
	  content: "`curl \"#{ROOT_URL}/update_output?name=test&password=#{ENV["password"]}&output=\#{SecureRandom.urlsafe_base64}\"`\r\n\r\n# do not use \"exit\"\r\n# and do not raise any errors, or zombie processes may result\r\n"
	)
end

if Stock.count.eql?(0)
	spreadsheet = Spreadsheet.open(Rails.root.join("public", "tickers.xls"))
	spreadsheet.worksheet("Stock").each_with_index do |row, idx|
		unless idx < 4
			puts Stock.create(
				ticker: row[0],
				name: row[1],
				exchange: row[2],
				country: row[3],
				category_name: row[4],
				category_number: row[5]
			).attributes
		end
	end
end