class Stock < ActiveRecord::Base
	has_many :stock_values
	def self.get_values(tickers)
		tickers = Array(tickers)
		stock_quotes = Array(StockQuote::Stock.quote(tickers))
		tickers.each_with_index do |ticker, idx|
			record = Stock.find_by(ticker: ticker)
			quote = stock_quotes[idx]
			record.stock_values.create(
				market_value: quote.ask,
				book_value: quote.book_value,
				earnings_share: quote.earnings_share,
				market_capitalization: quote.market_capitalization,
				average_daily_volume: quote.average_daily_volume
			)
		end
	end
	def plot_history(where_conditions={})
		data = self.stock_values.where(where_conditions).map do |value|
			"*** #{value.created_at.to_i} #{value.market_value}"
		end.join("\n")
		tempfile_name = "graph-data#{SecureRandom.urlsafe_base64}.txt"
		tempfile = Tempfile.new(tempfile_name)
		path = tempfile.path
		puts path
		tempfile.write(data)
		tempfile.close
		binding.pry
		return `(echo "plot '#{path}' using (\$2+3):(\#(3+3):1 with labels, '#{path}' using 2:3"; echo "exit"; ) | gnuplot`
	end
	def get_value
		self.class.get_values(self.ticker)
	end
end
