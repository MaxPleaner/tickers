class CreateStockValues < ActiveRecord::Migration
  def change
    create_table :stock_values do |t|
      t.integer :stock_id
      t.float :market_value
      t.float :book_value
    	t.float :earnings_share
    	t.string :market_capitalization
    	t.float :average_daily_volume
      t.timestamps null: false
    end
  end
end
